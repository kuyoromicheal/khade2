/**
 * Seed demo wallet, notifications, and verify auth accounts for the mobile app.
 * Usage: npm run supabase:seed-app
 */
const { loadEnv } = require('./supabase-env');
loadEnv();

const { getClient, isConfigured } = require('../src/supabase-client');
const { hashPassword } = require('../src/auth');

const DEMO_EMAIL = 'customer@khade.ng';
const TARGET_BALANCE = 85000;

async function nextCounter(client, table) {
  const { data: row } = await client
    .from('khade_counters')
    .select('value')
    .eq('table_name', table)
    .single();
  const next = (row?.value || 0) + 1;
  await client.from('khade_counters').upsert({ table_name: table, value: next }, { onConflict: 'table_name' });
  return next;
}

async function seedWalletForUser(client, userId) {
  const { data: existing } = await client
    .from('khade_wallet_transactions')
    .select('id')
    .eq('user_id', userId);

  if (existing?.length > 0) {
    console.log(`  wallet txs for user ${userId}: already ${existing.length} — skip`);
    return;
  }

  const now = new Date().toISOString();
  const txs = [
    { type: 'credit', amount: 2000, description: 'Welcome bonus — ₦2,000 is on us!', reference: `WELCOME_${userId}` },
    { type: 'credit', amount: 100000, description: 'Wallet top-up via Paystack', reference: 'PSK_TOPUP_DEMO' },
    { type: 'debit', amount: 8500, description: 'Booking KHD-1001 — Glam Studio Pro', reference: 'KHD-1001' },
    { type: 'debit', amount: 12600, description: 'Booking KHD-1002 — Beat by Ada', reference: 'KHD-1002' },
    { type: 'credit', amount: 5000, description: 'Referral reward', reference: 'REF_DEMO' },
    { type: 'debit', amount: 9000, description: 'Booking KHD-1003 — Luxury Face Abuja', reference: 'KHD-1003' },
  ];

  let net = 0;
  for (const tx of txs) {
    const id = await nextCounter(client, 'wallet_transactions');
    net += tx.type === 'credit' ? tx.amount : -tx.amount;
    await client.from('khade_wallet_transactions').insert({
      id,
      user_id: userId,
      type: tx.type,
      amount: tx.amount,
      description: tx.description,
      reference: tx.reference,
      created_at: now,
    });
  }

  await client.from('khade_users').update({ wallet_balance: TARGET_BALANCE }).eq('id', userId);
  console.log(`  wallet txs for user ${userId}: seeded ${txs.length} (balance set to ₦${TARGET_BALANCE.toLocaleString()})`);
}

async function seedNotifications(client, userId) {
  const { count } = await client
    .from('khade_notifications')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);

  if (count > 0) {
    console.log(`  notifications for user ${userId}: already ${count} — skip`);
    return;
  }

  const items = [
    { title: 'Welcome to Khade ✦', body: '₦2,000 has been added to your wallet. Book your first service today!', emoji: '🎁' },
    { title: 'Booking confirmed', body: 'Your appointment at Glam Studio Pro is confirmed for tomorrow.', emoji: '✓' },
    { title: 'Wallet topped up', body: '₦100,000 added to your Khade wallet', emoji: '💳' },
  ];

  for (const n of items) {
    const id = await nextCounter(client, 'notifications');
    await client.from('khade_notifications').insert({
      id,
      user_id: userId,
      title: n.title,
      body: n.body,
      emoji: n.emoji,
      read: 0,
      created_at: new Date().toISOString(),
    });
  }
  console.log(`  notifications for user ${userId}: seeded ${items.length}`);
}

async function ensureDemoAuth(client) {
  const demos = [
    { email: 'customer@khade.ng', password: 'password123', role: 'customer' },
    { email: 'provider@khade.ng', password: 'password123', role: 'provider' },
    { email: 'admin@khade.ng', password: 'password123', role: 'admin' },
  ];

  for (const demo of demos) {
    const { data: user } = await client.from('khade_users').select('*').eq('email', demo.email).single();
    if (!user) {
      console.log(`  ✗ missing demo user ${demo.email}`);
      continue;
    }
    if (!user.password_hash) {
      await client
        .from('khade_users')
        .update({ password_hash: await hashPassword(demo.password), role: demo.role })
        .eq('id', user.id);
      console.log(`  auth fixed for ${demo.email}`);
    } else {
      console.log(`  auth OK for ${demo.email}`);
    }
  }
}

async function main() {
  console.log('=== Khade app data seed ===\n');

  if (!isConfigured()) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  const client = getClient();

  await ensureDemoAuth(client);

  const { data: customer } = await client.from('khade_users').select('id,email').eq('email', DEMO_EMAIL).single();
  if (!customer) {
    console.error(`Demo customer ${DEMO_EMAIL} not found — run login once or migrate:supabase`);
    process.exit(1);
  }

  console.log(`\nSeeding wallet + notifications for ${customer.email} (id ${customer.id})...`);
  await seedWalletForUser(client, customer.id);
  await seedNotifications(client, customer.id);

  console.log('\nDone. Demo login: customer@khade.ng / password123');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
