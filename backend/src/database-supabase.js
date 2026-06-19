const { getClient } = require('./supabase-client');

/** JSON key → Supabase table (khade_* avoids conflicts with existing UUID tables) */
const TABLE_MAP = {
  categories: 'khade_categories',
  providers: 'khade_providers',
  users: 'khade_users',
  services: 'khade_services',
  bookings: 'khade_bookings',
  feed_posts: 'khade_feed_posts',
  feed_comments: 'khade_feed_comments',
  notifications: 'khade_notifications',
  wallet_transactions: 'khade_wallet_transactions',
  reviews: 'khade_reviews',
  messages: 'khade_messages',
  payouts: 'khade_payouts',
  platform_revenue: 'khade_platform_revenue',
};

/** Save order respects foreign keys */
const SAVE_ORDER = [
  'categories',
  'providers',
  'users',
  'services',
  'bookings',
  'feed_posts',
  'feed_comments',
  'notifications',
  'wallet_transactions',
  'reviews',
  'messages',
  'payouts',
  'platform_revenue',
];

const TABLES = Object.keys(TABLE_MAP);
/** Auth routes only need these tables — avoids loading bookings, feed, etc. */
const AUTH_TABLES = ['users', 'providers', 'wallet_transactions', 'notifications'];
const COUNTERS_TABLE = 'khade_counters';

const empty = {
  categories: [],
  users: [],
  providers: [],
  services: [],
  bookings: [],
  feed_posts: [],
  feed_comments: [],
  notifications: [],
  wallet_transactions: [],
  reviews: [],
  messages: [],
  payouts: [],
  platform_revenue: [],
  _counters: {},
};

async function load() {
  const client = getClient();
  const data = structuredClone(empty);

  await Promise.all(
    TABLES.map(async (key) => {
      const table = TABLE_MAP[key];
      const { data: rows, error } = await client.from(table).select('*');
      if (error) throw new Error(`Supabase load ${table}: ${error.message}`);
      data[key] = rows || [];
    }),
  );

  const { data: counterRows, error: counterErr } = await client.from(COUNTERS_TABLE).select('*');
  if (counterErr) throw new Error(`Supabase load counters: ${counterErr.message}`);
  data._counters = {};
  for (const row of counterRows || []) {
    data._counters[row.table_name] = row.value;
  }

  syncCountersFromData(data);

  return data;
}

/** Login only needs users + id counters. */
const LOGIN_TABLES = ['users'];

async function loadLogin() {
  const client = getClient();
  const data = structuredClone(empty);

  await Promise.all(
    LOGIN_TABLES.map(async (key) => {
      const table = TABLE_MAP[key];
      const { data: rows, error } = await client.from(table).select('*');
      if (error) throw new Error(`Supabase load ${table}: ${error.message}`);
      data[key] = rows || [];
    }),
  );

  const { data: counterRows, error: counterErr } = await client.from(COUNTERS_TABLE).select('*');
  if (counterErr) throw new Error(`Supabase load counters: ${counterErr.message}`);
  data._counters = {};
  for (const row of counterRows || []) {
    data._counters[row.table_name] = row.value;
  }

  syncCountersFromData(data);

  return data;
}

async function loadAuth() {
  const client = getClient();
  const data = structuredClone(empty);

  await Promise.all(
    AUTH_TABLES.map(async (key) => {
      const table = TABLE_MAP[key];
      const { data: rows, error } = await client.from(table).select('*');
      if (error) throw new Error(`Supabase load ${table}: ${error.message}`);
      data[key] = rows || [];
    }),
  );

  const { data: counterRows, error: counterErr } = await client.from(COUNTERS_TABLE).select('*');
  if (counterErr) throw new Error(`Supabase load counters: ${counterErr.message}`);
  data._counters = {};
  for (const row of counterRows || []) {
    data._counters[row.table_name] = row.value;
  }

  syncCountersFromData(data);

  return data;
}

async function save(data, onlyTables = null) {
  const client = getClient();
  const keys = onlyTables
    ? SAVE_ORDER.filter((k) => onlyTables.includes(k))
    : SAVE_ORDER;

  for (const key of keys) {
    const rows = data[key];
    if (!rows || rows.length === 0) continue;
    const table = TABLE_MAP[key];
    const payload = dedupeRowsById(rows);
    const { error } = await client.from(table).upsert(payload, { onConflict: 'id' });
    if (error) throw new Error(`Supabase save ${table}: ${error.message}`);
  }

  if (!onlyTables || onlyTables.includes('_counters')) {
    const counters = Object.entries(data._counters || {}).map(([table_name, value]) => ({
      table_name,
      value,
    }));
    if (counters.length > 0) {
      const { error } = await client.from(COUNTERS_TABLE).upsert(counters, { onConflict: 'table_name' });
      if (error) throw new Error(`Supabase save counters: ${error.message}`);
    }
  }
}

function syncCountersFromData(data) {
  for (const key of TABLES) {
    const rows = data[key];
    if (!Array.isArray(rows) || rows.length === 0) continue;
    const maxId = rows.reduce((m, r) => Math.max(m, Number(r.id) || 0), 0);
    data._counters[key] = Math.max(data._counters[key] || 0, maxId);
  }
}

function dedupeRowsById(rows) {
  const byId = new Map();
  for (const row of rows) {
    if (row?.id != null) byId.set(row.id, row);
  }
  return [...byId.values()];
}

function nextId(data, table) {
  const rows = data[table] || [];
  const maxExisting = rows.reduce((m, r) => Math.max(m, Number(r.id) || 0), 0);
  const next = Math.max(data._counters[table] || 0, maxExisting) + 1;
  data._counters[table] = next;
  return next;
}

module.exports = {
  mode: 'supabase',
  load,
  loadAuth,
  loadLogin,
  save,
  nextId: (data, table) => Promise.resolve(nextId(data, table)),
  TABLE_MAP,
  COUNTERS_TABLE,
  SAVE_ORDER,
  AUTH_TABLES,
};
