/**
 * Upload khade.deploy.json (or khade.json) into Supabase.
 * Prerequisites:
 *   1. Run supabase/schema.sql in Supabase SQL Editor
 *   2. Set SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY in backend/.env
 *
 * Usage: npm run migrate:supabase
 */
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  fs.readFileSync(envPath, 'utf8').split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const eq = trimmed.indexOf('=');
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim();
      const val = trimmed.slice(eq + 1).trim();
      if (!process.env[key]) process.env[key] = val;
    }
  });
}

const { getClient, isConfigured } = require('../src/supabase-client');

const { TABLE_MAP, COUNTERS_TABLE } = require('../src/database-supabase');

const TABLES = Object.keys(TABLE_MAP);

async function main() {
  if (!isConfigured()) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in backend/.env');
    process.exit(1);
  }

  const dataPath = [path.join(__dirname, '..', 'data', 'khade.deploy.json'), path.join(__dirname, '..', 'data', 'khade.json')]
    .find((p) => fs.existsSync(p));

  if (!dataPath) {
    console.error('No khade.deploy.json or khade.json found in backend/data');
    process.exit(1);
  }

  const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
  const client = getClient();

  console.log(`Migrating from ${path.basename(dataPath)} → Supabase\n`);

  for (const key of TABLES) {
    const rows = data[key] || [];
    const table = TABLE_MAP[key];
    if (rows.length === 0) {
      console.log(`  skip ${table} (empty)`);
      continue;
    }
    const { error } = await client.from(table).upsert(rows, { onConflict: 'id' });
    if (error) {
      console.error(`  FAIL ${table}:`, error.message);
      process.exit(1);
    }
    console.log(`  ✓ ${table}: ${rows.length} rows`);
  }

  const counters = Object.entries(data._counters || {}).map(([table_name, value]) => ({ table_name, value }));
  if (counters.length > 0) {
    const { error } = await client.from(COUNTERS_TABLE).upsert(counters, { onConflict: 'table_name' });
    if (error) {
      console.error('  FAIL counters:', error.message);
      process.exit(1);
    }
    console.log(`  ✓ ${COUNTERS_TABLE}: ${counters.length} entries`);
  }

  const active = (data.providers || []).filter((p) => p.status === 'active').length;
  console.log(`\nDone. ${active} active providers in database.`);
  console.log('Restart the API — it will use Supabase when env vars are set.\n');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
