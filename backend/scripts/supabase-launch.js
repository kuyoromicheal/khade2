/**
 * One-command launch automation:
 * migrate → phase7 → storage → seed → check
 *
 * Usage: npm run launch:setup
 */
const { spawnSync } = require('child_process');
const path = require('path');

const backendDir = path.join(__dirname, '..');
const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

function run(script, { optional = false } = {}) {
  console.log(`\n>>> npm run ${script}\n`);
  const r = spawnSync(npmCmd, ['run', script], { cwd: backendDir, stdio: 'inherit', shell: true });
  if (r.status !== 0 && !optional) {
    console.error(`\n${script} failed (exit ${r.status})`);
    process.exit(r.status || 1);
  }
  return r.status === 0;
}

console.log('╔══════════════════════════════════════╗');
console.log('║   Khade launch automation            ║');
console.log('╚══════════════════════════════════════╝');

run('supabase:migrate', { optional: true });
run('supabase:phase7', { optional: true });
run('supabase:storage', { optional: true });
run('supabase:seed-app');
run('launch:check', { optional: true });

console.log('\n=== Launch setup finished ===');
console.log('Flutter: cd ../khade_app && flutter pub get && flutter run --flavor customer -t lib/main.dart');
console.log('Paystack webhook:', 'https://khade-api.onrender.com/api/payments/webhook');
