/** Copy bundled deploy data if khade.json is missing (fresh cloud instance). */
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
const dbPath = path.join(dataDir, 'khade.deploy.json');
const livePath = path.join(dataDir, 'khade.json');

if (!fs.existsSync(livePath) && fs.existsSync(dbPath)) {
  fs.copyFileSync(dbPath, livePath);
  console.log('Initialized data/khade.json from khade.deploy.json');
}
