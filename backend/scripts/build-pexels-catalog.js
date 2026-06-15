/**
 * Build catalog of 200+ unique Pexels video IDs (category-matched, >=10s when API key set).
 * Videos stream via backend proxy — no bulk download needed.
 * Run: npm run build:catalog
 */
const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT = path.join(__dirname, '..');
const CATALOG_PATH = path.join(ROOT, 'data', 'video-catalog.json');
const UA = 'Mozilla/5.0 (compatible; KhadeMediaBot/1.0)';
const MIN_DURATION = 10;

const CATEGORIES = {
  barbing: { queries: ['barber haircut', 'barbershop', 'men haircut'], target: 23, seeds: [3045163, 6198980, 6198983, 6198986, 6198989, 4178353, 5595291, 6198979] },
  nails: { queries: ['manicure nails', 'nail salon', 'pedicure'], target: 23, seeds: [853889, 3129671, 6194114, 853890] },
  makeup: { queries: ['makeup artist', 'cosmetics beauty', 'lipstick'], target: 23, seeds: [3195394, 7817651, 3999399, 4057780, 6593633] },
  spa: { queries: ['spa massage', 'facial treatment', 'aromatherapy'], target: 23, seeds: [3209211, 5473997, 854579, 3760163] },
  hair: { queries: ['hair salon', 'hair styling', 'blow dry'], target: 23, seeds: [3045163, 3990089, 6198980, 6198983] },
  skincare: { queries: ['skincare facial', 'face serum', 'skin care'], target: 22, seeds: [6593633, 3760163, 5096661, 4057780] },
  braids: { queries: ['braids hairstyle', 'african braids', 'hair braiding'], target: 22, seeds: [3045163, 6521112, 7270766, 6198986] },
  lashes: { queries: ['eyelashes makeup', 'lash extensions', 'mascara'], target: 22, seeds: [6593633, 4057780, 7817651, 2103127] },
  wellness: { queries: ['yoga wellness', 'meditation spa', 'relaxation massage'], target: 22, seeds: [3209211, 5473997, 3822621, 8436722] },
};

const RES = ['hd_1280_720_25fps', 'hd_1280_720_30fps', 'sd_640_360_25fps'];

function loadEnv() {
  const p = path.join(ROOT, '.env');
  if (!fs.existsSync(p)) return;
  fs.readFileSync(p, 'utf8').split('\n').forEach((line) => {
    const t = line.trim();
    if (!t || t.startsWith('#')) return;
    const eq = t.indexOf('=');
    if (eq > 0 && !process.env[t.slice(0, eq).trim()]) {
      process.env[t.slice(0, eq).trim()] = t.slice(eq + 1).trim();
    }
  });
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
        if (res.statusCode !== 200) return reject(new Error(String(res.statusCode)));
        resolve(Buffer.concat(chunks));
      });
    }).on('error', reject);
  });
}

function headOk(id) {
  return new Promise((resolve) => {
    const url = `https://videos.pexels.com/video-files/${id}/${id}-${RES[0]}.mp4`;
    https.get(url, { headers: { 'User-Agent': UA } }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    }).on('error', () => resolve(false));
  });
}

async function fetchApi(query, page) {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return [];
  const url = `https://api.pexels.com/videos/search?query=${encodeURIComponent(query)}&per_page=40&page=${page}&orientation=portrait`;
  const buf = await httpsGet(url, { Authorization: key });
  const json = JSON.parse(buf.toString());
  return (json.videos || [])
    .filter((v) => (v.duration || 0) >= MIN_DURATION)
    .map((v) => ({ id: v.id, duration: v.duration, category: null }));
}

function expandSeeds(seeds) {
  const s = new Set();
  for (const n of seeds) for (let d = -40; d <= 40; d++) if (n + d > 0) s.add(n + d);
  return [...s];
}

async function buildCategory(slug, cfg, usedIds) {
  const entries = [];
  const candidates = [];

  if (process.env.PEXELS_API_KEY) {
    for (const q of cfg.queries) {
      for (let page = 1; page <= 8; page++) {
        try {
          const batch = await fetchApi(q, page);
          candidates.push(...batch);
        } catch { break; }
      }
    }
  }
  for (const id of expandSeeds(cfg.seeds)) candidates.push({ id, duration: MIN_DURATION });

  for (const c of candidates) {
    if (entries.length >= cfg.target || usedIds.has(c.id)) continue;
    process.stdout.write(`  ${slug} ${c.id}... `);
    if (await headOk(c.id)) {
      usedIds.add(c.id);
      entries.push({
        id: c.id,
        category: slug,
        duration: c.duration || MIN_DURATION,
        file: `pexels-${c.id}.mp4`,
        url: `/media/pexels/${c.id}.mp4`,
      });
      console.log('OK');
    } else {
      console.log('skip');
    }
  }
  return entries;
}

async function main() {
  loadEnv();
  const byCategory = {};
  const allEntries = [];
  const usedIds = new Set();

  for (const [slug, cfg] of Object.entries(CATEGORIES)) {
    console.log(`\n[${slug}] target ${cfg.target}`);
    const entries = await buildCategory(slug, cfg, usedIds);
    byCategory[slug] = entries.map((e) => e.file);
    allEntries.push(...entries);
    console.log(`  → ${entries.length}`);
  }

  const catalog = {
    builtAt: new Date().toISOString(),
    minDurationSec: MIN_DURATION,
    total: allEntries.length,
    byCategory,
    entries: allEntries,
    all: allEntries.map((e) => e.file),
  };
  fs.writeFileSync(CATALOG_PATH, JSON.stringify(catalog, null, 2));
  console.log(`\nCatalog: ${allEntries.length} unique Pexels IDs (proxied, with sound)`);
}

main().catch((e) => { console.error(e); process.exit(1); });
