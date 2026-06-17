const crypto = require('crypto');
const { load, save, nextId } = require('./database');
const { verifyTransaction } = require('./paystack');

async function pushNotification(data, { userId, title, body, emoji = '✦' }) {
  data.notifications = data.notifications || [];
  data.notifications.unshift({
    id: await nextId(data, 'notifications'),
    user_id: userId,
    title,
    body,
    emoji,
    read: 0,
    created_at: new Date().toISOString(),
  });
}

async function creditWalletFromPaystack(userId, amountNaira, reference) {
  const data = await load();
  const user = data.users.find((u) => u.id === userId);
  if (!user) return { ok: false, error: 'user not found' };

  data.wallet_transactions = data.wallet_transactions || [];
  const existing = data.wallet_transactions.find((t) => t.reference === reference);
  if (existing) return { ok: true, duplicate: true, newBalance: user.wallet_balance };

  const verified = await verifyTransaction(reference);
  if (verified.status !== 'success') return { ok: false, error: 'payment not verified' };

  const amt = Math.round(verified.amount || amountNaira);
  user.wallet_balance = (user.wallet_balance || 0) + amt;
  data.wallet_transactions.push({
    id: await nextId(data, 'wallet_transactions'),
    user_id: userId,
    type: 'credit',
    amount: amt,
    description: 'Wallet top-up via Paystack',
    reference,
    status: 'completed',
    created_at: new Date().toISOString(),
  });
  await pushNotification(data, {
    userId,
    title: 'Wallet Topped Up',
    body: `₦${amt.toLocaleString()} added to your Khade wallet`,
    emoji: '💰',
  });
  await save(data, ['users', 'wallet_transactions', 'notifications', '_counters']);
  return { ok: true, newBalance: user.wallet_balance, amount: amt };
}

async function handlePaystackWebhook(rawBody, signature) {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  if (!secret) return { status: 503, body: 'Paystack not configured' };

  const hash = crypto.createHmac('sha512', secret).update(rawBody).digest('hex');
  if (hash !== signature) return { status: 401, body: 'Invalid signature' };

  const event = JSON.parse(rawBody.toString());
  if (event.event === 'charge.success') {
    const ref = event.data.reference;
    const metaUserId = event.data.metadata?.user_id || event.data.metadata?.userId;
    const email = event.data.customer?.email;
    const amount = event.data.amount / 100;

    const data = await load();
    let userId = metaUserId ? Number(metaUserId) : null;
    if (!userId && email) {
      const user = data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
      userId = user?.id;
    }
    if (!userId) return { status: 200, body: 'ok (no user match)' };

    await creditWalletFromPaystack(userId, amount, ref);
  }

  return { status: 200, body: 'ok' };
}

module.exports = { handlePaystackWebhook, creditWalletFromPaystack };
