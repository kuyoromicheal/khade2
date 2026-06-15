const { getClient } = require('./supabase-client');

/** JSON key → Supabase table (khade_* avoids conflicts with existing UUID tables) */
const TABLE_MAP = {
  categories: 'khade_categories',
  users: 'khade_users',
  providers: 'khade_providers',
  services: 'khade_services',
  bookings: 'khade_bookings',
  feed_posts: 'khade_feed_posts',
  feed_comments: 'khade_feed_comments',
  notifications: 'khade_notifications',
  wallet_transactions: 'khade_wallet_transactions',
  reviews: 'khade_reviews',
  messages: 'khade_messages',
  provider_locations: 'khade_provider_locations',
  booking_groups: 'khade_booking_groups',
  client_profiles: 'khade_client_profiles',
  staff: 'khade_staff',
  inventory: 'khade_inventory',
  campaigns: 'khade_campaigns',
  capital_loans: 'khade_capital_loans',
  payouts: 'khade_payouts',
  platform_revenue: 'khade_platform_revenue',
  fcm_tokens: 'khade_fcm_tokens',
  pending_payments: 'khade_pending_payments',
};

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
  provider_locations: [],
  booking_groups: [],
  client_profiles: [],
  staff: [],
  inventory: [],
  campaigns: [],
  capital_loans: [],
  payouts: [],
  platform_revenue: [],
  fcm_tokens: [],
  pending_payments: [],
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

async function save(data) {
  const client = getClient();

  for (const key of TABLES) {
    const rows = data[key];
    if (!rows || rows.length === 0) continue;
    const table = TABLE_MAP[key];
    const { error } = await client.from(table).upsert(rows, { onConflict: 'id' });
    if (error) throw new Error(`Supabase save ${table}: ${error.message}`);
  }

  const counters = Object.entries(data._counters || {}).map(([table_name, value]) => ({
    table_name,
    value,
  }));
  if (counters.length > 0) {
    const { error } = await client.from(COUNTERS_TABLE).upsert(counters, { onConflict: 'table_name' });
    if (error) throw new Error(`Supabase save counters: ${error.message}`);
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
};
