/**
 * Check Supabase connection and table row counts.
 * Usage: npm run supabase:status
 */
const { loadEnv } = require('./supabase-env');
loadEnv();

const { getClient, isConfigured } = require('../src/supabase-client');
const { TABLE_MAP } = require('../src/database-supabase');

async function main() {
  console.log('=== Khade Supabase status ===\n');

  if (!isConfigured()) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in backend/.env');
    process.exit(1);
  }

  console.log(`URL:     ${process.env.SUPABASE_URL}`);
  console.log(`Project: ${process.env.SUPABASE_PROJECT_REF || 'lqfzutfhhshditpewedt'}`);
  console.log(`DB URL:  ${process.env.SUPABASE_DB_URL ? 'set (CLI migrations enabled)' : 'not set (use MCP or add SUPABASE_DB_URL)'}\n`);

  const client = getClient();
  let ok = 0;
  let missing = 0;

  for (const [key, table] of Object.entries(TABLE_MAP)) {
    const { count, error } = await client.from(table).select('*', { count: 'exact', head: true });
    if (error) {
      console.log(`  ✗ ${table}: ${error.message}`);
      missing++;
    } else {
      console.log(`  ✓ ${table}: ${count ?? 0} rows`);
      ok++;
    }
  }

  const { count: counterCount, error: counterErr } = await client
    .from('khade_counters')
    .select('*', { count: 'exact', head: true });
  if (counterErr) console.log(`  ✗ khade_counters: ${counterErr.message}`);
  else console.log(`  ✓ khade_counters: ${counterCount ?? 0} entries`);

  console.log(`\n${ok} tables OK, ${missing} missing/errors`);
  if (missing > 0) {
    console.log('\nFix: npm run supabase:migrate   (or use Cursor Supabase MCP → execute_sql)');
    process.exit(1);
  }
  console.log('\nReady. API health should show database: supabase');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
