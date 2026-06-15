/**
 * Download category-matched HQ feed videos into public/media/videos/.
 * Run from backend/: node scripts/download-media.js
 */
const fs = require('fs');
const path = require('path');
const https = require('https');

const OUT = path.join(__dirname, '..', 'public', 'media', 'videos');
const UA = 'Mozilla/5.0 (compatible; KhadeMediaBot/1.0)';

/** Pexels video ID → output filename */
const CATALOG = [
  { file: 'barbing-3.mp4', id: 3045163, res: 'hd_1920_1080_25fps' },
  { file: 'barbing-2.mp4', id: 3045163, res: 'sd_640_360_25fps' },
  { file: 'nails-1.mp4', id: 853889, res: 'hd_1920_1080_25fps' },
  { file: 'makeup-1.mp4', id: 3195394, res: 'hd_1920_1080_25fps' },
  { file: 'spa-1.mp4', id: 3209211, res: 'hd_1920_1080_25fps' },
  { file: 'lashes-2.mp4', id: 6593633, res: 'hd_1920_1080_25fps' },
];

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': UA } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        file.close();
        fs.unlinkSync(dest);
        return download(res.headers.location, dest).then(resolve, reject);
      }
      if (res.statusCode !== 200) {
        file.close();
        fs.unlinkSync(dest);
        return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve(dest)));
    }).on('error', reject);
  });
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  for (const item of CATALOG) {
    const url = `https://videos.pexels.com/video-files/${item.id}/${item.id}-${item.res}.mp4`;
    const dest = path.join(OUT, item.file);
    process.stdout.write(`Downloading ${item.file}... `);
    try {
      await download(url, dest);
      const mb = (fs.statSync(dest).size / 1024 / 1024).toFixed(2);
      console.log(`${mb} MB`);
    } catch (e) {
      console.log(`FAILED (${e.message})`);
    }
  }
  console.log('Done. Copy variants per category in media-urls.js if needed.');
}

main();
