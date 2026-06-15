/** Deduplicate videos by hash and rebuild video-catalog.json */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'public', 'media', 'videos');
const CATALOG_PATH = path.join(ROOT, 'data', 'video-catalog.json');
const CATEGORIES = ['barbing', 'nails', 'makeup', 'spa', 'hair', 'skincare', 'braids', 'lashes', 'wellness'];

function hashFile(p) {
  return crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
}

const seen = new Set();
const byCategory = {};
const entries = [];

for (const slug of CATEGORIES) byCategory[slug] = [];

for (const slug of CATEGORIES) {
  const files = fs.readdirSync(OUT_DIR)
    .filter((f) => f.startsWith(`${slug}-`) && f.endsWith('.mp4'))
    .sort((a, b) => parseInt(a.match(/-(\d+)/)?.[1] || '0', 10) - parseInt(b.match(/-(\d+)/)?.[1] || '0', 10));

  for (const f of files) {
    const p = path.join(OUT_DIR, f);
    const size = fs.statSync(p).size;
    if (size < 400000) {
      fs.unlinkSync(p);
      continue;
    }
    const h = hashFile(p);
    if (seen.has(h)) {
      fs.unlinkSync(p);
      console.log(`removed duplicate ${f}`);
      continue;
    }
    seen.add(h);
    const renamed = `${slug}-${byCategory[slug].length + 1}.mp4`;
    const dest = path.join(OUT_DIR, renamed);
    if (f !== renamed) fs.renameSync(p, dest);
    byCategory[slug].push(renamed);
    entries.push({ file: renamed, category: slug, duration: 10 });
  }
}

const total = entries.length;
fs.writeFileSync(CATALOG_PATH, JSON.stringify({
  builtAt: new Date().toISOString(),
  minDurationSec: 10,
  total,
  byCategory,
  entries,
  all: entries.map((e) => e.file),
}, null, 2));
console.log(`Catalog: ${total} unique videos (deduped)`);
