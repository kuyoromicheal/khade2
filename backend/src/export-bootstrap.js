/** Export bootstrap JSON for Flutter offline bundle. Run: node src/export-bootstrap.js */
const fs = require('fs');
const path = require('path');
const http = require('http');

const out = path.join(__dirname, '..', '..', 'khade_app', 'assets', 'data', 'bootstrap.json');

http.get('http://localhost:3001/api/bootstrap?userId=1', (res) => {
  let body = '';
  res.on('data', (c) => { body += c; });
  res.on('end', () => {
    const json = JSON.parse(body);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, JSON.stringify(json.data, null, 2));
    console.log(`Exported bootstrap → ${out}`);
  });
}).on('error', (e) => {
  console.error('Start the API first (npm start):', e.message);
  process.exit(1);
});
