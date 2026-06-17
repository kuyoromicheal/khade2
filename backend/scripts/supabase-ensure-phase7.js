/**
 * Verify phase7-launch.sql was applied; apply via pg when SUPABASE_DB_URL is set.
 * Usage: npm run supabase:phase7
 */
const fs = require('fs');
const path = require('path');
const { loadEnv } = require('./supabase-env');
loadEnv();

const { getClient, isConfigured } = require('../src/supabase-client');

const PHASE7_FILE = path.join(__dirname, '..', 'supabase', 'phase7-launch.sql');

async function probePhase7(client) {
  const checks = [
    {
      label: 'khade_providers.bank_code',
      run: () => client.from('khade_providers').select('bank_code').limit(1),
    },
    {
      label: 'khade_users.fcm_token',
      run: () => client.from('khade_users').select('fcm_token').limit(1),
    },
  ];

  const missing = [];
  for (const c of checks) {
    const { error } = await c.run();
    if (error) {
      missing.push(c.label);
      console.log(`  ✗ ${c.label}: ${error.message}`);
    } else {
      console.log(`  ✓ ${c.label}`);
    }
  }
  return missing;
}

async function applyViaPg() {
  const dbUrl = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
  if (!dbUrl) return false;

  let pg;
  try {
    pg = require('pg');
  } catch (_) {
    console.error('Install pg: npm install pg');
    process.exit(1);
  }

  const sql = fs.readFileSync(PHASE7_FILE, 'utf8');
  const client = new pg.Client({ connectionString: dbUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();
  console.log('\nApplying phase7-launch.sql via Postgres...');
  await client.query(sql);
  await client.end();
  console.log('  OK\n');
  return true;
}

async function main() {
  console.log('=== Khade phase7 schema check ===\n');

  if (!isConfigured()) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  const client = getClient();
  let missing = await probePhase7(client);

  if (missing.length === 0) {
    console.log('\nphase7 schema OK.');
    return;
  }

  console.log(`\n${missing.length} column(s) missing — attempting auto-apply...`);
  const applied = await applyViaPg();

  if (applied) {
    missing = await probePhase7(client);
    if (missing.length === 0) {
      console.log('\nphase7 applied successfully.');
      return;
    }
  }

  console.log('\nManual fix (pick one):');
  console.log('  1. Add SUPABASE_DB_URL to backend/.env → npm run supabase:phase7');
  console.log('  2. Paste backend/supabase/phase7-launch.sql in Supabase SQL Editor → Run');
  process.exit(1);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
