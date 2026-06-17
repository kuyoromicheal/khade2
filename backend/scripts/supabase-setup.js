/**
 * Full Supabase setup: status → migrate → seed → status
 * Usage: npm run supabase:setup
 */
const { spawnSync } = require('child_process');
const path = require('path');

const backendDir = path.join(__dirname, '..');
const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

function run(script) {
  console.log(`\n>>> npm run ${script}\n`);
  const r = spawnSync(npmCmd, ['run', script], { cwd: backendDir, stdio: 'inherit', shell: true });
  if (r.status !== 0 && script !== 'supabase:migrate') {
    process.exit(r.status || 1);
  }
}

console.log('=== Khade Supabase full setup ===');
run('supabase:status');
run('supabase:migrate');
run('migrate:supabase');
run('supabase:seed-app');
run('supabase:status');
console.log('\n=== Setup complete ===');
