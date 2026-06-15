const express = require('express');
const crypto = require('crypto');
const { load, save, nextId } = require('../database');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ensureCollections } = require('../collections');

const router = express.Router();

function sinceFilter(iso) {
  if (!iso) return () => true;
  const t = new Date(iso).getTime();
  return (row) => new Date(row.created_at || row.updated_at || 0).getTime() > t;
}

/** Real-time sync snapshot — poll every 3–5s from Flutter */
router.get('/sync/snapshot', async (req, res) => {
  const data = ensureCollections(await load());
  const userId = Number(req.query.userId || req.userId || 1);
  const since = req.query.since;
  const filt = sinceFilter(since);

  const notifications = data.notifications
    .filter((n) => n.user_id === userId)
    .filter(filt)
    .map((r) => ({
      id: r.id, title: r.title, body: r.body, emoji: r.emoji,
      read: !!r.read, createdAt: r.created_at,
    }));

  const walletTransactions = (data.wallet_transactions || [])
    .filter((t) => t.user_id === userId)
    .filter(filt)
    .map((t) => ({
      id: t.id, type: t.type, amount: t.amount, description: t.description,
      reference: t.reference, createdAt: t.created_at,
    }));

  const feedPosts = data.feed_posts
    .filter(filt)
    .slice(0, 20)
    .map((f) => ({
      id: f.id, providerId: f.provider_id, caption: f.caption,
      likes: f.likes, comments: f.comments, createdAt: f.created_at,
    }));

  const user = data.users.find((u) => u.id === userId);

  res.json({
    data: {
      serverTime: new Date().toISOString(),
      walletBalance: user?.wallet_balance ?? 0,
      unreadNotifications: data.notifications.filter((n) => n.user_id === userId && !n.read).length,
      notifications,
      walletTransactions,
      feedPosts,
    },
  });
});

/** In-app chat per booking */
router.get('/bookings/:bookingId/messages', async (req, res) => {
  const data = ensureCollections(await load());
  const bookingId = Number(req.params.bookingId);
  const rows = data.messages
    .filter((m) => m.booking_id === bookingId)
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  res.json({
    data: rows.map((m) => ({
      id: m.id, bookingId: m.booking_id, senderId: m.sender_id,
      senderName: m.sender_name, body: m.body, createdAt: m.created_at,
    })),
  });
});

router.post('/bookings/:bookingId/messages', async (req, res) => {
  const data = ensureCollections(await load());
  const bookingId = Number(req.params.bookingId);
  const { body, userId = req.userId || 1, senderName } = req.body;
  if (!body?.trim()) return res.status(400).json({ error: 'Message body required' });

  const booking = data.bookings.find((b) => b.id === bookingId);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });

  const user = data.users.find((u) => u.id === Number(userId));
  const msg = {
    id: await nextId(data, 'messages'),
    booking_id: bookingId,
    sender_id: Number(userId),
    sender_name: senderName || user?.name || 'User',
    body: body.trim(),
    created_at: new Date().toISOString(),
  };
  data.messages.push(msg);

  const recipientId = Number(userId) === booking.user_id ? booking.provider_id : booking.user_id;
  const provider = data.providers.find((p) => p.id === booking.provider_id);
  const notifyUserId = Number(userId) === booking.user_id
    ? (provider?.owner_user_id || booking.user_id)
    : booking.user_id;

  data.notifications.unshift({
    id: await nextId(data, 'notifications'),
    user_id: notifyUserId,
    title: 'New message',
    body: `${msg.sender_name}: ${body.trim().slice(0, 80)}`,
    emoji: '💬',
    read: 0,
    created_at: new Date().toISOString(),
  });

  await save(data);
  res.status(201).json({
    data: {
      id: msg.id, bookingId, senderId: msg.sender_id,
      senderName: msg.sender_name, body: msg.body, createdAt: msg.created_at,
    },
  });
});

/** Group / owambe booking */
router.post('/groups', async (req, res) => {
  const data = ensureCollections(await load());
  const {
    userId = req.userId || 1, title, eventDate, guestCount = 1,
    address, providerId, serviceId, scheduledAt, note,
  } = req.body;
  if (!title || !providerId || !serviceId) {
    return res.status(400).json({ error: 'title, providerId, serviceId required' });
  }

  const groupId = await nextId(data, 'booking_groups');
  data.booking_groups.push({
    id: groupId,
    lead_user_id: Number(userId),
    title,
    event_date: eventDate || scheduledAt,
    guest_count: Number(guestCount),
    address: address || null,
    status: 'pending',
    created_at: new Date().toISOString(),
  });

  const service = data.services.find((s) => s.id === Number(serviceId));
  const fee = Math.round((service?.price || 10000) * 0.1);
  const total = (service?.price || 10000) + fee;
  const code = `KHD-G${groupId}`;

  const bookingId = await nextId(data, 'bookings');
  data.bookings.push({
    id: bookingId,
    user_id: Number(userId),
    provider_id: Number(providerId),
    service_id: Number(serviceId),
    group_id: groupId,
    status: 'upcoming',
    location_type: 'home',
    address,
    scheduled_at: scheduledAt || eventDate,
    total_amount: total,
    booking_code: code,
    payment_method: 'paystack',
    note: note || `Group booking: ${title} · ${guestCount} guests`,
    payment_status: 'pending',
    created_at: new Date().toISOString(),
  });

  await save(data);
  res.status(201).json({
    data: { groupId, bookingId, bookingCode: code, totalAmount: total, guestCount },
  });
});

router.get('/groups', async (req, res) => {
  const data = ensureCollections(await load());
  const userId = Number(req.query.userId || req.userId || 1);
  const rows = data.booking_groups.filter((g) => g.lead_user_id === userId);
  res.json({ data: rows });
});

/** FCM token registration (push notifications) */
router.post('/devices/fcm-token', async (req, res) => {
  const data = ensureCollections(await load());
  const { userId = req.userId || 1, token, platform = 'android' } = req.body;
  if (!token) return res.status(400).json({ error: 'token required' });

  data.fcm_tokens = data.fcm_tokens.filter((t) => t.token !== token);
  data.fcm_tokens.push({
    id: await nextId(data, 'fcm_tokens'),
    user_id: Number(userId),
    token,
    platform,
    created_at: new Date().toISOString(),
  });
  await save(data);
  res.json({ data: { registered: true } });
});

/** CRM — client profiles for providers */
router.get('/provider/crm/clients', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const providerId = req.user.provider_id;
  const rows = data.client_profiles.filter((c) => c.provider_id === providerId);
  res.json({ data: rows });
});

router.post('/provider/crm/clients', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const providerId = req.user.provider_id;
  const { userId, name, phone, notes, allergies, colorFormula } = req.body;
  const row = {
    id: await nextId(data, 'client_profiles'),
    provider_id: providerId,
    user_id: userId || null,
    name, phone, notes, allergies,
    color_formula: colorFormula,
    lifetime_value: 0,
    visit_count: 0,
    created_at: new Date().toISOString(),
  };
  data.client_profiles.push(row);
  await save(data);
  res.status(201).json({ data: row });
});

/** Staff management */
router.get('/provider/staff', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  res.json({ data: data.staff.filter((s) => s.provider_id === req.user.provider_id) });
});

router.post('/provider/staff', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const { name, role, phone } = req.body;
  const row = {
    id: await nextId(data, 'staff'),
    provider_id: req.user.provider_id,
    name, role, phone,
    active: 1,
    created_at: new Date().toISOString(),
  };
  data.staff.push(row);
  await save(data);
  res.status(201).json({ data: row });
});

/** Inventory */
router.get('/provider/inventory', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  res.json({ data: data.inventory.filter((i) => i.provider_id === req.user.provider_id) });
});

router.post('/provider/inventory', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const { name, sku, quantity, reorderLevel, unitPrice } = req.body;
  const row = {
    id: await nextId(data, 'inventory'),
    provider_id: req.user.provider_id,
    name, sku,
    quantity: Number(quantity) || 0,
    reorder_level: Number(reorderLevel) || 5,
    unit_price: Number(unitPrice) || 0,
    created_at: new Date().toISOString(),
  };
  data.inventory.push(row);
  await save(data);
  res.status(201).json({ data: row });
});

/** Marketing campaigns */
router.post('/provider/campaigns', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const { title, message, channel = 'sms' } = req.body;
  const clients = data.client_profiles.filter((c) => c.provider_id === req.user.provider_id);
  const row = {
    id: await nextId(data, 'campaigns'),
    provider_id: req.user.provider_id,
    title, message, channel,
    sent_count: clients.length,
    status: 'sent',
    created_at: new Date().toISOString(),
  };
  data.campaigns.push(row);
  await save(data);
  res.status(201).json({ data: row, meta: { recipients: clients.length } });
});

/** Khade Capital — provider loan application */
router.post('/provider/capital/apply', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  const { amount, purpose } = req.body;
  if (!amount) return res.status(400).json({ error: 'amount required' });
  const row = {
    id: await nextId(data, 'capital_loans'),
    provider_id: req.user.provider_id,
    amount: Number(amount),
    purpose: purpose || 'Equipment & stock',
    status: 'pending',
    repayment_pct: 10,
    created_at: new Date().toISOString(),
  };
  data.capital_loans.push(row);
  await save(data);
  res.status(201).json({ data: row });
});

router.get('/provider/capital', requireAuth, requireRole('provider'), async (req, res) => {
  const data = ensureCollections(await load());
  res.json({ data: data.capital_loans.filter((l) => l.provider_id === req.user.provider_id) });
});

module.exports = router;
