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
    const { error } = await client.from(table).upsert(rows, { onConflict: 'id' });
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

function nextId(data, table) {
  data._counters[table] = (data._counters[table] || 0) + 1;
  return data._counters[table];
}

module.exports = {
  mode: 'supabase',
  load,
  save,
  nextId: (data, table) => Promise.resolve(nextId(data, table)),
  TABLE_MAP,
  COUNTERS_TABLE,
  SAVE_ORDER,
};
