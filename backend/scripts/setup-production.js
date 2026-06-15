/**
 * One-shot production setup: demo accounts, auth users, verify Supabase + Render.
 * Usage: node scripts/setup-production.js
 */
const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

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

if (!process.env.JWT_SECRET) {
  process.env.JWT_SECRET = 'khade-production-jwt-' + Date.now();
  console.log('Set ephemeral JWT_SECRET for this run (add JWT_SECRET to Render env!)');
}

const { load, save } = require('../src/database');
const { ensureDemoAccounts } = require('../src/routes/auth.routes');
const { getClient, isConfigured } = require('../src/supabase-client');
const { TABLE_MAP } = require('../src/database-supabase');

const RENDER_URL = process.env.RENDER_API_URL || 'https://khade-api.onrender.com';

function fetchJson(url, options = {}) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.request(url, { method: options.method || 'GET', headers: options.headers || {}, timeout: 90000 }, (res) => {
      let body = '';
      res.on('data', (c) => { body += c; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: body ? JSON.parse(body) : {} });
        } catch {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('timeout')));
    if (options.body) req.write(options.body);
    req.end();
  });
}

async function main() {
  console.log('=== Khade production setup ===\n');

  // 1. Supabase demo accounts
  console.log('1. Seeding demo accounts into database...');
  const data = await load();
  await ensureDemoAccounts(data);
  await save(data);
  const demos = data.users.filter((u) => u.email?.endsWith('@khade.ng'));
  console.log(`   ✓ ${demos.length} demo users (${demos.map((u) => u.email).join(', ')})`);

  // 2. Supabase table counts
  if (isConfigured()) {
    console.log('\n2. Supabase table check...');
    const client = getClient();
    for (const [key, table] of Object.entries(TABLE_MAP)) {
      const { count, error } = await client.from(table).select('*', { count: 'exact', head: true });
      if (error) console.log(`   ✗ ${table}: ${error.message}`);
      else console.log(`   ✓ ${table}: ${count ?? 0} rows`);
    }
  }

  // 3. Render health
  console.log(`\n3. Render API (${RENDER_URL})...`);
  try {
    const health = await fetchJson(`${RENDER_URL}/health`);
    if (health.status === 200) {
      console.log(`   ✓ health: ${JSON.stringify(health.data)}`);
    } else {
      console.log(`   ✗ health returned ${health.status}`);
    }
  } catch (e) {
    console.log(`   ✗ Render unreachable: ${e.message}`);
    console.log('     (Free tier sleeps — first request can take 60s)');
  }

  // 4. Test auth register bonus on Render
  console.log('\n4. Testing auth on Render...');
  const testEmail = `test${Date.now()}@khade.ng`;
  try {
    const reg = await fetchJson(`${RENDER_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: 'password123',
        name: 'Setup Test',
        role: 'customer',
      }),
    });
    if (reg.status === 201 || reg.status === 200) {
      const bonus = reg.data?.data?.welcomeBonus;
      const wallet = reg.data?.data?.user?.walletBalance;
      console.log(`   ✓ register works — welcomeBonus: ₦${bonus ?? wallet ?? '?'}`);
    } else {
      console.log(`   ✗ register failed (${reg.status}): ${JSON.stringify(reg.data)}`);
    }
  } catch (e) {
    console.log(`   ✗ auth test failed: ${e.message}`);
  }

  // 5. Test login demo
  try {
    const login = await fetchJson(`${RENDER_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'customer@khade.ng', password: 'password123' }),
    });
    if (login.status === 200) {
      console.log(`   ✓ demo login works — wallet: ₦${login.data?.data?.user?.walletBalance ?? '?'}`);
    } else {
      console.log(`   ✗ demo login (${login.status}): ${JSON.stringify(login.data)}`);
    }
  } catch (e) {
    console.log(`   ✗ login test: ${e.message}`);
  }

  console.log('\n=== Flutter app ===');
  console.log('Stop the app and run a FULL restart (not hot reload):');
  console.log('  cd khade_app');
  console.log('  flutter run -d RRCYA02415N --dart-define=API_BASE_URL=https://khade-api.onrender.com');
  console.log('\n=== Render env (set in dashboard if auth fails) ===');
  console.log('  JWT_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, PAYSTACK_*');
  console.log('');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
