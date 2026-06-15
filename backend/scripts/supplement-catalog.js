/** Fast-fill weak categories with unique Pexels IDs (parallel probes). */
const fs = require('fs');
const path = require('path');
const https = require('https');

const CATALOG_PATH = path.join(__dirname, '..', 'data', 'video-catalog.json');
const UA = 'Mozilla/5.0';
const RES = 'hd_1280_720_25fps';
const MIN_PER_CAT = 22;
const CONCURRENCY = 12;

/** High-yield ID ranges discovered from Pexels beauty searches */
const RANGES = {
  barbing: [[4178340, 4178450], [5595260, 5595340]],
  hair: [[6198975, 6199030], [3045160, 3045220], [7693280, 7693350]],
  braids: [[6198975, 6199030], [6521100, 6521180]],
  skincare: [[6593625, 6593680], [3760140, 3760200]],
  lashes: [[6593625, 6593700], [4057760, 4057820]],
  wellness: [[3209170, 3209260], [854535, 854560], [3822600, 3822680], [5473950, 5474020]],
};

/** Extra global scan — any category still short borrows from these pools */
const GLOBAL_POOLS = [
  [853894, 854100],
  [3195400, 3195500],
  [3209250, 3209350],
  [6593640, 6593750],
  [3999360, 3999450],
  [7817600, 7817700],
];

function headOk(id) {
  return new Promise((resolve) => {
    const url = `https://videos.pexels.com/video-files/${id}/${id}-${RES}.mp4`;
    const req = https.get(url, { headers: { 'User-Agent': UA } }, (res) => {
      res.resume();
      resolve(res.statusCode === 200 ? id : null);
    });
    req.on('error', () => resolve(null));
    req.setTimeout(8000, () => { req.destroy(); resolve(null); });
  });
}

async function scanRange(start, end, used, limit) {
  const found = [];
  const ids = [];
  for (let id = start; id <= end; id++) if (!used.has(id)) ids.push(id);

  for (let i = 0; i < ids.length && found.length < limit; i += CONCURRENCY) {
    const batch = ids.slice(i, i + CONCURRENCY);
    const results = await Promise.all(batch.map(headOk));
    for (const id of results) {
      if (id && found.length < limit) {
        found.push(id);
        used.add(id);
      }
    }
  }
  return found;
}

async function main() {
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
  const used = new Set((catalog.entries || []).map((e) => e.id));

  for (const [slug, ranges] of Object.entries(RANGES)) {
    const list = [...(catalog.byCategory[slug] || [])];
    if (list.length >= MIN_PER_CAT) continue;
    console.log(`[${slug}] ${list.length} → target ${MIN_PER_CAT}`);

    for (const [start, end] of ranges) {
      if (list.length >= MIN_PER_CAT) break;
      const need = MIN_PER_CAT - list.length;
      const found = await scanRange(start, end, used, need);
      for (const id of found) {
        const file = `pexels-${id}.mp4`;
        list.push(file);
        catalog.entries.push({ id, category: slug, duration: 10, file, url: `/media/pexels/${id}.mp4` });
        console.log(`  + ${id}`);
      }
    }
    catalog.byCategory[slug] = list;
  }

  // Global top-up for any category still under target
  for (const [slug, list] of Object.entries(catalog.byCategory)) {
    if (slug === 'all' || list.length >= MIN_PER_CAT) continue;
    console.log(`[${slug}] top-up ${list.length} → ${MIN_PER_CAT}`);
    for (const [start, end] of GLOBAL_POOLS) {
      if (list.length >= MIN_PER_CAT) break;
      const found = await scanRange(start, end, used, MIN_PER_CAT - list.length);
      for (const id of found) {
        const file = `pexels-${id}.mp4`;
        list.push(file);
        catalog.entries.push({ id, category: slug, duration: 10, file, url: `/media/pexels/${id}.mp4` });
        console.log(`  + ${id}`);
      }
    }
    catalog.byCategory[slug] = list;
  }

  catalog.all = catalog.entries.map((e) => e.file);
  catalog.total = catalog.entries.length;
  catalog.builtAt = new Date().toISOString();
  fs.writeFileSync(CATALOG_PATH, JSON.stringify(catalog, null, 2));
  console.log(`\nDone: ${catalog.total} unique videos`);
}

main().catch((e) => { console.error(e); process.exit(1); });
