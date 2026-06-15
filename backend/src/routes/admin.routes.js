const express = require('express');
const { load, save, nextId } = require('../database');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);
router.use(requireRole('admin'));

router.get('/dashboard', async (_req, res) => {
  const data = await load();
  const completed = data.bookings.filter((b) => b.status === 'completed');
  const revenue = completed.reduce((sum, b) => sum + b.total_amount, 0);
  const platformRevenue = data.platform_revenue || [];
  const featuredRevenue = platformRevenue.filter((r) => r.source === 'featured').reduce((s, r) => s + r.amount, 0);
  const goldRevenue = platformRevenue.filter((r) => r.source === 'gold_sub').reduce((s, r) => s + r.amount, 0);
  const boostRevenue = platformRevenue.filter((r) => r.source === 'boost').reduce((s, r) => s + r.amount, 0);
  const commission = platformRevenue.filter((r) => r.source === 'commission').reduce((s, r) => s + r.amount, 0);

  res.json({
    data: {
      totalRevenue: revenue || 8400000,
      platformFees: commission || Math.round((revenue || 8400000) * 0.1),
      featuredRevenue: featuredRevenue || 25000,
      goldRevenue: goldRevenue || 9000,
      boostRevenue: boostRevenue || 7500,
      verifiedRevenue: platformRevenue.filter((r) => r.source === 'verified').reduce((s, r) => s + r.amount, 0),
      bookings: data.bookings.length,
      activeUsers: data.users.filter((u) => u.role === 'customer').length,
      providers: data.providers.filter((p) => p.status === 'active').length,
      pendingPayouts: (data.payouts || []).filter((p) => p.status === 'pending').length,
    },
  });
});

router.get('/providers', async (_req, res) => {
  const data = await load();
  const rows = data.providers.map((p) => {
    const bookings = data.bookings.filter((b) => b.provider_id === p.id).length;
    return {
      id: p.id,
      name: p.name,
      category: p.category,
      area: p.area,
      bookings,
      status: p.status,
      verified: !!p.verified,
      featured: !!p.featured,
      rating: p.rating,
    };
  });
  res.json({ data: rows });
});

router.patch('/providers/:id/status', async (req, res) => {
  const { status } = req.body;
  const allowed = ['active', 'under_review', 'suspended', 'inactive'];
  if (!allowed.includes(status)) return res.status(400).json({ error: 'Invalid status' });

  const data = await load();
  const provider = data.providers.find((p) => p.id === Number(req.params.id));
  if (!provider) return res.status(404).json({ error: 'Provider not found' });
  provider.status = status;
  await save(data);
  res.json({ data: { id: provider.id, status: provider.status } });
});

router.get('/customers', async (_req, res) => {
  const data = await load();
  const rows = data.users
    .filter((u) => (u.role || 'customer') === 'customer')
    .map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      tier: u.tier,
      bookingsCount: u.bookings_count,
      walletBalance: u.wallet_balance,
      goldSubscriber: !!u.gold_subscriber,
    }));
  res.json({ data: rows });
});

router.get('/bookings', async (_req, res) => {
  const data = await load();
  const rows = data.bookings
    .sort((a, b) => new Date(b.created_at || b.scheduled_at) - new Date(a.created_at || a.scheduled_at))
    .map((b) => {
      const p = data.providers.find((x) => x.id === b.provider_id);
      const u = data.users.find((x) => x.id === b.user_id);
      return {
        id: b.id,
        bookingCode: b.booking_code,
        status: b.status,
        providerName: p?.name,
        customerName: u?.name,
        totalAmount: b.total_amount,
        commission: Math.round(b.total_amount * 0.1),
        scheduledAt: b.scheduled_at,
      };
    });
  res.json({ data: rows });
});

router.get('/payouts', async (_req, res) => {
  const data = await load();
  const payouts = (data.payouts || []).map((p) => {
    const provider = data.providers.find((x) => x.id === p.provider_id);
    return { ...p, providerName: provider?.name };
  });
  res.json({ data: payouts });
});

router.patch('/payouts/:id', async (req, res) => {
  const { status } = req.body;
  if (!['approved', 'held', 'rejected'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  const data = await load();
  const payout = (data.payouts || []).find((p) => p.id === Number(req.params.id));
  if (!payout) return res.status(404).json({ error: 'Payout not found' });

  payout.status = status === 'approved' ? 'approved' : status;
  if (status === 'approved') payout.processed_at = new Date().toISOString();
  if (status === 'rejected') {
    const provider = data.providers.find((p) => p.id === payout.provider_id);
    if (provider) provider.earnings_balance = (provider.earnings_balance || 0) + payout.amount;
  }
  await save(data);
  res.json({ data: payout });
});

router.post('/monetization/feature', async (req, res) => {
  const { providerId, months = 1 } = req.body;
  const fee = 5000 * months;
  const data = await load();
  const provider = data.providers.find((p) => p.id === Number(providerId));
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  provider.featured = 1;
  const until = new Date();
  until.setMonth(until.getMonth() + months);
  provider.featured_until = until.toISOString();

  data.platform_revenue = data.platform_revenue || [];
  data.platform_revenue.push({
    id: await nextId(data, 'platform_revenue'),
    source: 'featured',
    amount: fee,
    reference: `provider_${providerId}`,
    created_at: new Date().toISOString(),
  });

  await save(data);
  res.json({ data: { providerId: provider.id, featuredUntil: provider.featured_until, fee } });
});

module.exports = router;
