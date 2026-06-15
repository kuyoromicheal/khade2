/** Copy live khade.json → khade.deploy.json for git/deploy. Run after import or data changes. */
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
const src = path.join(dataDir, 'khade.json');
const dest = path.join(dataDir, 'khade.deploy.json');

if (!fs.existsSync(src)) {
  console.error('Missing data/khade.json — run import or generate first.');
  process.exit(1);
}
fs.copyFileSync(src, dest);
console.log('Bundled data/khade.deploy.json for production deploy');
