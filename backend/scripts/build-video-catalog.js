/**
 * Build 200+ unique category beauty reels (Pexels, royalty-free).
 * Requirements: >=10s when API used, category-themed, no duplicate files.
 *
 * Optional in backend/.env: PEXELS_API_KEY=... (free at https://www.pexels.com/api/)
 * Run: npm run build:videos
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');

const ROOT = path.join(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'public', 'media', 'videos');
const CATALOG_PATH = path.join(ROOT, 'data', 'video-catalog.json');
const UA = 'Mozilla/5.0 (compatible; KhadeMediaBot/1.0)';
const MIN_DURATION_SEC = 10;
const MAX_BYTES = 14 * 1024 * 1024;
const MIN_BYTES = 400000;

const CATEGORIES = {
  barbing: { queries: ['barber haircut', 'barbershop fade', 'men haircut'], target: 23, seeds: [3045163, 4178353, 5595291, 6198979, 3990089, 5678092, 4828859, 7581450, 4058821] },
  nails: { queries: ['manicure nails', 'nail polish salon', 'pedicure spa'], target: 23, seeds: [853889, 6194114, 3129671, 853890, 4828751, 4786756, 6963395, 7161340] },
  makeup: { queries: ['makeup artist', 'cosmetics beauty', 'lipstick makeup'], target: 23, seeds: [3195394, 7817651, 3999399, 4057780, 6593633, 2533266, 3373736, 5096661] },
  spa: { queries: ['spa massage', 'facial treatment', 'aromatherapy spa'], target: 23, seeds: [3209211, 5473997, 854579, 3760163, 5096661, 6593633, 7817651] },
  hair: { queries: ['hair salon', 'hair styling', 'blow dry hair'], target: 23, seeds: [3045163, 3990089, 6521112, 7270766, 5595639, 3194240, 7693319, 6271557] },
  skincare: { queries: ['skincare facial', 'face serum beauty', 'skin care routine'], target: 22, seeds: [6593633, 3760163, 5096661, 4057780, 7817651, 3195394, 2533266] },
  braids: { queries: ['braids hairstyle', 'african braids', 'hair braiding'], target: 22, seeds: [3045163, 6521112, 7270766, 1034062, 769283, 1319460, 5595639] },
  lashes: { queries: ['eyelashes extensions', 'lash makeup', 'mascara beauty'], target: 22, seeds: [6593633, 4057780, 7817651, 2103127, 2533266, 3373736] },
  wellness: { queries: ['yoga wellness', 'meditation spa', 'relaxation massage'], target: 22, seeds: [3209211, 5473997, 854579, 3822621, 8436722, 3757942] },
};

const RESOLUTIONS = ['hd_1280_720_25fps', 'hd_1280_720_30fps', 'sd_960_540_25fps', 'sd_640_360_25fps'];
const globalUsedIds = new Set();
const globalHashes = new Set();

function loadEnv() {
  const envPath = path.join(ROOT, '.env');
  if (!fs.existsSync(envPath)) return;
  fs.readFileSync(envPath, 'utf8').split('\n').forEach((line) => {
    const t = line.trim();
    if (!t || t.startsWith('#')) return;
    const eq = t.indexOf('=');
    if (eq > 0 && !process.env[t.slice(0, eq).trim()]) {
      process.env[t.slice(0, eq).trim()] = t.slice(eq + 1).trim();
    }
  });
}

function hashFile(filePath) {
  const buf = fs.readFileSync(filePath);
  return crypto.createHash('sha256').update(buf).digest('hex');
}

function httpsGet(url, headers = {}) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': UA, ...headers } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return httpsGet(res.headers.location, headers).then(resolve, reject);
      }
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode}`));
        resolve(Buffer.concat(chunks));
      });
    }).on('error', reject);
  });
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': UA } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        file.close();
        try { fs.unlinkSync(dest); } catch { /* */ }
        return downloadFile(res.headers.location, dest).then(resolve, reject);
      }
      if (res.statusCode !== 200) {
        file.close();
        try { fs.unlinkSync(dest); } catch { /* */ }
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve(dest)));
    }).on('error', reject);
  });
}

function expandSeeds(seeds) {
  const ids = new Set();
  for (const s of seeds) {
    for (let d = -30; d <= 30; d++) {
      const id = s + d;
      if (id > 100000) ids.add(id);
    }
  }
  return [...ids];
}

async function fetchFromPexelsApi(query, page, perPage = 40) {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return [];
  const url = `https://api.pexels.com/videos/search?query=${encodeURIComponent(query)}&per_page=${perPage}&page=${page}&orientation=portrait`;
  const buf = await httpsGet(url, { Authorization: key });
  const json = JSON.parse(buf.toString());
  return (json.videos || [])
    .filter((v) => (v.duration || 0) >= MIN_DURATION_SEC)
    .map((v) => ({
      id: v.id,
      duration: v.duration,
      url: pickBestFile(v.video_files || []),
    }))
    .filter((v) => v.url);
}

function pickBestFile(files) {
  const mp4s = files.filter((f) => f.file_type === 'video/mp4' && f.link);
  if (!mp4s.length) return null;
  const portrait = mp4s.filter((f) => f.height > f.width);
  const pool = portrait.length ? portrait : mp4s;
  pool.sort((a, b) => (b.height || 0) - (a.height || 0));
  const pick = pool.find((f) => (f.height || 0) <= 1280) || pool[0];
  return pick.link;
}

async function tryDownloadUrl(url, dest) {
  await downloadFile(url, dest);
  const size = fs.statSync(dest).size;
  if (size < MIN_BYTES || size > MAX_BYTES) {
    fs.unlinkSync(dest);
    return null;
  }
  const h = hashFile(dest);
  if (globalHashes.has(h)) {
    fs.unlinkSync(dest);
    return null;
  }
  globalHashes.add(h);
  return { size, hash: h };
}

async function tryDownloadPexelsId(id, dest) {
  if (globalUsedIds.has(id)) return null;
  for (const res of RESOLUTIONS) {
    const url = `https://videos.pexels.com/video-files/${id}/${id}-${res}.mp4`;
    try {
      const ok = await tryDownloadUrl(url, dest);
      if (ok) {
        globalUsedIds.add(id);
        return { id, res, ...ok };
      }
    } catch {
      try { if (fs.existsSync(dest)) fs.unlinkSync(dest); } catch { /* */ }
    }
  }
  return null;
}

async function collectCandidates(cfg) {
  const list = [];
  if (process.env.PEXELS_API_KEY) {
    for (const q of cfg.queries) {
      for (let page = 1; page <= 6; page++) {
        try {
          const batch = await fetchFromPexelsApi(q, page);
          list.push(...batch);
        } catch {
          break;
        }
      }
    }
  }
  for (const id of expandSeeds(cfg.seeds)) {
    list.push({ id, duration: null, url: null });
  }
  return list;
}

async function buildCategory(slug, cfg) {
  const entries = [];
  const candidates = await collectCandidates(cfg);
  const seenIds = new Set();

  for (const c of candidates) {
    if (entries.length >= cfg.target) break;
    if (c.id && seenIds.has(c.id)) continue;
    if (c.id) seenIds.add(c.id);

    const name = `${slug}-${entries.length + 1}.mp4`;
    const dest = path.join(OUT_DIR, name);

    if (fs.existsSync(dest)) {
      const size = fs.statSync(dest).size;
      if (size >= MIN_BYTES && size <= MAX_BYTES) {
        const h = hashFile(dest);
        if (!globalHashes.has(h)) {
          globalHashes.add(h);
          entries.push({ file: name, category: slug, pexelsId: c.id || null, duration: c.duration || MIN_DURATION_SEC });
          process.stdout.write(`  reuse ${name}\n`);
          continue;
        }
        fs.unlinkSync(dest);
      }
    }

    process.stdout.write(`  ${slug} ${c.id || '?'}... `);
    let ok = null;
    if (c.url) {
      try {
        ok = await tryDownloadUrl(c.url, dest);
        if (ok) globalUsedIds.add(c.id);
      } catch {
        ok = null;
      }
    }
    if (!ok && c.id) ok = await tryDownloadPexelsId(c.id, dest);

    if (ok) {
      entries.push({ file: name, category: slug, pexelsId: c.id || null, duration: c.duration || MIN_DURATION_SEC });
      console.log(`OK ${name} (${(ok.size / 1024 / 1024).toFixed(1)} MB)`);
    } else {
      console.log('skip');
    }
  }
  return entries;
}

async function main() {
  loadEnv();
  fs.mkdirSync(OUT_DIR, { recursive: true });

  if (!process.env.PEXELS_API_KEY) {
    console.log('Tip: add PEXELS_API_KEY to backend/.env for faster 200+ unique videos (10s+, with sound).\n');
  }

  const byCategory = {};
  const allEntries = [];
  let total = 0;

  for (const [slug, cfg] of Object.entries(CATEGORIES)) {
    console.log(`\n[${slug}] target ${cfg.target}`);
    const entries = await buildCategory(slug, cfg);
    byCategory[slug] = entries.map((e) => e.file);
    allEntries.push(...entries);
    total += entries.length;
    console.log(`  → ${entries.length} unique`);
  }

  const catalog = {
    builtAt: new Date().toISOString(),
    minDurationSec: MIN_DURATION_SEC,
    total,
    byCategory,
    entries: allEntries,
    all: allEntries.map((e) => e.file),
  };
  fs.writeFileSync(CATALOG_PATH, JSON.stringify(catalog, null, 2));
  console.log(`\nCatalog: ${total} unique videos → ${CATALOG_PATH}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
