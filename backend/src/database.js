const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
const dbPath = path.join(dataDir, 'khade.json');

if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const empty = {
  users: [],
  providers: [],
  services: [],
  bookings: [],
  feed_posts: [],
  notifications: [],
  _counters: { users: 0, providers: 0, services: 0, bookings: 0, feed_posts: 0, notifications: 0 },
};

function load() {
  if (!fs.existsSync(dbPath)) {
    fs.writeFileSync(dbPath, JSON.stringify(empty, null, 2));
    return structuredClone(empty);
  }
  return JSON.parse(fs.readFileSync(dbPath, 'utf8'));
}

function save(data) {
  fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
}

function nextId(data, table) {
  data._counters[table] = (data._counters[table] || 0) + 1;
  return data._counters[table];
}

module.exports = { load, save, nextId, dbPath };
