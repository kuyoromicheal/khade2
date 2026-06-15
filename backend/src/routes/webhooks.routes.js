const express = require('express');
const crypto = require('crypto');
const { load, save, nextId } = require('../database');
const { verifyTransaction } = require('../paystack');
const { ensureCollections } = require('../collections');

const router = express.Router();

function verifyPaystackSignature(req) {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  if (!secret) return false;
  const hash = crypto.createHmac('sha512', secret).update(JSON.stringify(req.body)).digest('hex');
  return hash === req.headers['x-paystack-signature'];
}

/** Paystack webhook — charge.success credits wallet or confirms booking payment */
router.post('/paystack', async (req, res) => {
  if (!verifyPaystackSignature(req)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const event = req.body?.event;
  const reference = req.body?.data?.reference;
  if (event !== 'charge.success' || !reference) {
    return res.json({ received: true });
  }

  const data = ensureCollections(await load());
  let verified;
  try {
    verified = await verifyTransaction(reference);
  } catch (_) {
    return res.status(400).json({ error: 'Verification failed' });
  }

  if (verified.status !== 'success') {
    return res.json({ received: true, status: verified.status });
  }

  const pending = data.pending_payments.find((p) => p.reference === reference);
  if (pending && pending.status === 'completed') {
    return res.json({ received: true, duplicate: true });
  }

  if (pending) {
    pending.status = 'completed';
    if (pending.purpose === 'wallet_topup' && pending.user_id) {
      const user = data.users.find((u) => u.id === pending.user_id);
      if (user) {
        user.wallet_balance = (user.wallet_balance || 0) + verified.amount;
        data.wallet_transactions.push({
          id: await nextId(data, 'wallet_transactions'),
          user_id: user.id,
          type: 'credit',
          amount: verified.amount,
          description: 'Paystack top-up (webhook)',
          reference,
          created_at: new Date().toISOString(),
        });
        data.notifications.unshift({
          id: await nextId(data, 'notifications'),
          user_id: user.id,
          title: 'Wallet topped up',
          body: `₦${verified.amount} added via Paystack`,
          emoji: '💳',
          read: 0,
          created_at: new Date().toISOString(),
        });
      }
    } else if (pending.purpose === 'booking' && pending.booking_meta) {
      const meta = pending.booking_meta;
      const bookingId = meta.bookingId;
      const booking = data.bookings.find((b) => b.id === bookingId);
      if (booking) {
        booking.payment_status = 'paid';
        booking.payment_reference = reference;
      }
    }
  } else if (reference.startsWith('KHADE_')) {
    const userId = 1;
    const user = data.users.find((u) => u.id === userId);
    if (user) {
      user.wallet_balance = (user.wallet_balance || 0) + verified.amount;
      data.wallet_transactions.push({
        id: await nextId(data, 'wallet_transactions'),
        user_id: userId,
        type: 'credit',
        amount: verified.amount,
        description: 'Paystack payment (webhook)',
        reference,
        created_at: new Date().toISOString(),
      });
    }
  }

  await save(data);
  res.json({ received: true, reference, amount: verified.amount });
});

module.exports = router;
