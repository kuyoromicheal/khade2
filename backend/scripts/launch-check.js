/**
 * Full launch readiness check (env, DB, storage, phase7, API health).
 * Usage: npm run launch:check
 */
const { loadEnv } = require('./supabase-env');
loadEnv();

const { getClient, isConfigured } = require('../src/supabase-client');
const { TABLE_MAP } = require('../src/database-supabase');

const API_URL = process.env.KHADE_API_URL || 'https://khade-api.onrender.com';
const WEBHOOK_URL = `${API_URL.replace(/\/$/, '')}/api/payments/webhook`;

const REQUIRED_ENV = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'JWT_SECRET',
  'PAYSTACK_SECRET_KEY',
  'PAYSTACK_PUBLIC_KEY',
];

const RECOMMENDED_ENV = ['SUPABASE_DB_URL', 'PAYSTACK_CALLBACK_BASE'];

const STORAGE_BUCKETS = ['provider-photos', 'portfolio-videos', 'provider-docs', 'post-images'];

let failures = 0;
let warnings = 0;

function fail(msg) {
  console.log(`  ✗ ${msg}`);
  failures++;
}

function warn(msg) {
  console.log(`  ⚠ ${msg}`);
  warnings++;
}

function ok(msg) {
  console.log(`  ✓ ${msg}`);
}

async function checkEnv() {
  console.log('Environment (backend/.env)');
  for (const key of REQUIRED_ENV) {
    if (process.env[key]) ok(key);
    else fail(`${key} missing`);
  }
  for (const key of RECOMMENDED_ENV) {
    if (process.env[key]) ok(key);
    else warn(`${key} not set`);
  }
  const callback = process.env.PAYSTACK_CALLBACK_BASE || '';
  if (callback.includes('10.') || callback.includes('192.168.') || callback.includes('localhost')) {
    warn(`PAYSTACK_CALLBACK_BASE is local (${callback}) — use ${API_URL} for phones + Render`);
  }
  console.log('');
}

async function checkTables(client) {
  console.log('Database tables');
  for (const [, table] of Object.entries(TABLE_MAP)) {
    const { count, error } = await client.from(table).select('*', { count: 'exact', head: true });
    if (error) fail(`${table}: ${error.message}`);
    else ok(`${table}: ${count ?? 0} rows`);
  }
  console.log('');
}

async function checkPhase7(client) {
  console.log('Phase7 columns');
  const { error: p } = await client.from('khade_providers').select('bank_code').limit(1);
  const { error: u } = await client.from('khade_users').select('fcm_token').limit(1);
  if (p) fail('khade_providers.bank_code — run npm run supabase:phase7');
  else ok('provider bank columns');
  if (u) fail('khade_users.fcm_token — run npm run supabase:phase7');
  else ok('user fcm_token column');
  console.log('');
}

async function checkStorage(client) {
  console.log('Storage buckets');
  const { data, error } = await client.storage.listBuckets();
  if (error) {
    fail(`listBuckets: ${error.message}`);
    console.log('');
    return;
  }
  const names = new Set((data || []).map((b) => b.name));
  for (const id of STORAGE_BUCKETS) {
    if (names.has(id)) ok(id);
    else warn(`${id} missing — run npm run supabase:storage`);
  }
  console.log('');
}

async function checkApiHealth() {
  console.log(`API health (${API_URL})`);
  try {
    const res = await fetch(`${API_URL}/health`, { signal: AbortSignal.timeout(20000) });
    if (!res.ok) {
      fail(`/health returned ${res.status}`);
    } else {
      const body = await res.json();
      if (body.database === 'supabase') ok('database: supabase');
      else warn(`database: ${body.database ?? 'unknown'} (deploy latest backend)`);
      ok('API reachable');
    }
  } catch (e) {
    warn(`API unreachable (${e.message}) — Render may be cold-starting`);
  }
  console.log('');
}

function printManualSteps() {
  console.log('Manual steps (cannot automate)');
  console.log('  • Paystack Dashboard → Webhooks →', WEBHOOK_URL);
  console.log('  • Push backend to GitHub → Render auto-deploy');
  console.log('  • CAC + Paystack live keys when ready for production payments');
  console.log('  • Apple / Google developer accounts for store submit');
  console.log('');
}

async function main() {
  console.log('=== Khade launch check ===\n');

  await checkEnv();

  if (!isConfigured()) {
    fail('Supabase not configured — fix .env first');
    printManualSteps();
    process.exit(1);
  }

  const client = getClient();
  await checkTables(client);
  await checkPhase7(client);
  await checkStorage(client);
  await checkApiHealth();
  printManualSteps();

  console.log(`Result: ${failures} failure(s), ${warnings} warning(s)`);
  if (failures > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
