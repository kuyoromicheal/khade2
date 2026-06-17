/**
 * Apply safe Supabase SQL migrations via direct Postgres connection.
 * Requires SUPABASE_DB_URL in backend/.env (Dashboard → Database → Connection string).
 *
 * Usage: npm run supabase:migrate
 */
const fs = require('fs');
const path = require('path');
const { loadEnv } = require('./supabase-env');
loadEnv();

const MIGRATION_FILES = [
  'auth-extensions.sql',
  'phase2.sql',
  'phase2-full.sql',
  'add-booking-dest.sql',
  'fix-rls.sql',
  'phase3-mobile.sql',
  'phase3-v3.sql',
  'phase5-solo.sql',
  'phase6-instant-signup.sql',
  'phase7-launch.sql',
];

async function runWithPg() {
  const dbUrl = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
  if (!dbUrl) {
    console.log('SUPABASE_DB_URL not set — skipping CLI SQL runner.\n');
    console.log('Options:');
    console.log('  1. Add SUPABASE_DB_URL to backend/.env (Database → Connection string → URI)');
    console.log('  2. Use Cursor Supabase MCP: ask agent to run migrations via execute_sql');
    console.log('  3. Paste files manually in Supabase SQL Editor in this order:');
    MIGRATION_FILES.forEach((f, i) => console.log(`     ${i + 1}. backend/supabase/${f}`));
    process.exit(0);
  }

  let pg;
  try {
    pg = require('pg');
  } catch (_) {
    console.error('Install pg: npm install pg');
    process.exit(1);
  }

  const client = new pg.Client({ connectionString: dbUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();
  console.log('Connected to Postgres\n');

  const sqlDir = path.join(__dirname, '..', 'supabase');
  for (const file of MIGRATION_FILES) {
    const filePath = path.join(sqlDir, file);
    if (!fs.existsSync(filePath)) {
      console.log(`  skip ${file} (not found)`);
      continue;
    }
    const sql = fs.readFileSync(filePath, 'utf8');
    process.stdout.write(`  running ${file}... `);
    try {
      await client.query(sql);
      console.log('OK');
    } catch (e) {
      console.log('FAIL');
      console.error(`    ${e.message}`);
    }
  }

  await client.end();
  console.log('\nDone. Run: npm run supabase:status');
}

runWithPg().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
