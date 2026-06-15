const express = require('express');
const { load, save, nextId } = require('../database');
const { requireAuth, requireRole } = require('../middleware/auth');
const { DEFAULT_SLOTS } = require('./auth.routes');
const { ensureCollections } = require('../collections');

const router = express.Router();

const DAY_KEYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

function providerForUser(data, user) {
  if (!user.provider_id) return null;
  return data.providers.find((p) => p.id === user.provider_id);
}

router.get('/me', requireAuth, requireRole('provider', 'admin'), async (req, res) => {
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider profile not found' });
  res.json({
    data: {
      id: provider.id,
      name: provider.name,
      category: provider.category,
      area: provider.area,
      status: provider.status,
      verified: !!provider.verified,
      featured: !!provider.featured,
      earningsBalance: provider.earnings_balance || 0,
      visitTypes: provider.visit_types || 'both',
      bio: provider.bio || '',
      availability: provider.availability || DEFAULT_SLOTS,
    },
  });
});

/** Provider GPS for live map tracking */
router.post('/location', requireAuth, requireRole('provider', 'admin'), async (req, res) => {
  const data = ensureCollections(await load());
  const { lat, lng } = req.body;
  const providerId = req.user.provider_id;
  if (!providerId) return res.status(400).json({ error: 'No provider linked to account' });

  const existing = data.provider_locations.find((l) => l.provider_id === providerId);
  const row = {
    provider_id: providerId,
    lat: Number(lat),
    lng: Number(lng),
    updated_at: new Date().toISOString(),
  };
  if (existing) Object.assign(existing, row);
  else data.provider_locations.push(row);
  await save(data);
  res.json({ data: { providerId, lat: row.lat, lng: row.lng, updatedAt: row.updated_at } });
});

router.post('/onboard', requireAuth, requireRole('provider'), async (req, res) => {
  const { categorySlug, services, visitTypes, area, bio, phone } = req.body;
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const CATEGORY_META = {
    barbing: { label: 'Barbing', emoji: '✂️' },
    nails: { label: 'Nails', emoji: '💅' },
    makeup: { label: 'Makeup', emoji: '💄' },
    spa: { label: 'Spa', emoji: '🧖' },
    hair: { label: 'Hair', emoji: '💇' },
    skincare: { label: 'Skincare', emoji: '🧴' },
    braids: { label: 'Braids', emoji: '🪡' },
  };

  const cat = CATEGORY_META[categorySlug] || { label: 'Beauty', emoji: '💄' };
  provider.category = cat.label;
  provider.category_slug = categorySlug || provider.category_slug;
  provider.emoji = cat.emoji;
  if (area) provider.area = area;
  if (bio) provider.bio = bio;
  if (phone) provider.phone = phone;
  if (visitTypes) provider.visit_types = visitTypes;
  provider.status = 'under_review';
  provider.availability = provider.availability || DEFAULT_SLOTS;

  if (Array.isArray(services)) {
    data.services = data.services.filter((s) => s.provider_id !== provider.id);
    for (const s of services) {
      data.services.push({
        id: await nextId(data, 'services'),
        provider_id: provider.id,
        name: s.name,
        duration: s.duration || '60 mins',
        price: Number(s.price) || 5000,
      });
    }
    provider.price_from = Math.min(...services.map((s) => Number(s.price) || 5000));
  }

  await save(data);
  res.json({ data: { success: true, providerId: provider.id, status: provider.status } });
});

router.patch('/availability', requireAuth, requireRole('provider'), async (req, res) => {
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  provider.availability = { ...(provider.availability || DEFAULT_SLOTS), ...req.body };
  await save(data);
  res.json({ data: provider.availability });
});

router.get('/earnings', requireAuth, requireRole('provider'), async (req, res) => {
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const bookings = data.bookings.filter((b) => b.provider_id === provider.id);
  const completed = bookings.filter((b) => b.status === 'completed');
  const upcoming = bookings.filter((b) => b.status === 'upcoming');
  const gross = completed.reduce((s, b) => s + b.total_amount, 0);
  const commission = Math.round(gross * 0.1);
  const net = gross - commission;

  res.json({
    data: {
      gross,
      commission,
      net,
      availableBalance: provider.earnings_balance || net,
      upcomingCount: upcoming.length,
      completedCount: completed.length,
      completionRate: bookings.length ? Math.round((completed.length / bookings.length) * 100) : 98,
    },
  });
});

router.post('/payouts', requireAuth, requireRole('provider'), async (req, res) => {
  const { amount, bankName, accountNumber } = req.body;
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const balance = provider.earnings_balance || 0;
  const amt = Number(amount) || balance;
  if (amt <= 0 || amt > balance) {
    return res.status(400).json({ error: 'Invalid withdrawal amount' });
  }

  data.payouts = data.payouts || [];
  const payout = {
    id: await nextId(data, 'payouts'),
    provider_id: provider.id,
    amount: amt,
    status: 'pending',
    bank_name: bankName || 'Access Bank',
    account_number: accountNumber || '****',
    created_at: new Date().toISOString(),
  };
  data.payouts.push(payout);
  provider.earnings_balance = balance - amt;
  await save(data);
  res.status(201).json({ data: payout });
});

router.patch('/bookings/:id/status', requireAuth, requireRole('provider', 'admin'), async (req, res) => {
  const { status } = req.body;
  const allowed = ['accepted', 'in_progress', 'completed', 'cancelled'];
  if (!allowed.includes(status)) return res.status(400).json({ error: 'Invalid status' });

  const data = await load();
  const booking = data.bookings.find((b) => b.id === Number(req.params.id));
  if (!booking) return res.status(404).json({ error: 'Booking not found' });

  if (req.userRole === 'provider' && booking.provider_id !== req.user.provider_id) {
    return res.status(403).json({ error: 'Not your booking' });
  }

  booking.status = status === 'accepted' ? 'upcoming' : status === 'in_progress' ? 'upcoming' : status;

  if (status === 'completed') {
    const provider = data.providers.find((p) => p.id === booking.provider_id);
    const net = Math.round(booking.total_amount * 0.9);
    if (provider) provider.earnings_balance = (provider.earnings_balance || 0) + net;

    data.platform_revenue = data.platform_revenue || [];
    data.platform_revenue.push({
      id: await nextId(data, 'platform_revenue'),
      source: 'commission',
      amount: booking.total_amount - net,
      reference: booking.booking_code,
      created_at: new Date().toISOString(),
    });
  }

  await save(data);
  res.json({ data: { id: booking.id, status: booking.status } });
});

router.post('/posts', requireAuth, requireRole('provider'), async (req, res) => {
  const { caption, imageUrl, videoUrl, mediaType = 'image', categorySlug } = req.body;
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const post = {
    id: await nextId(data, 'feed_posts'),
    provider_id: provider.id,
    image_emoji: provider.emoji,
    image_url: imageUrl || null,
    video_url: videoUrl || null,
    media_type: mediaType,
    badge: categorySlug || provider.category_slug,
    caption: caption || `${provider.name} — book now on Khade ✦`,
    likes: 0,
    comments: 0,
    liked_by: [],
    created_at: new Date().toISOString(),
  };
  data.feed_posts.unshift(post);
  await save(data);
  res.status(201).json({ data: post });
});

router.get('/:providerId/slots', async (req, res) => {
  const data = await load();
  const provider = data.providers.find((p) => p.id === Number(req.params.providerId));
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const dateStr = req.query.date || new Date().toISOString().slice(0, 10);
  const dt = new Date(`${dateStr}T12:00:00`);
  const dayKey = DAY_KEYS[dt.getDay()];
  const avail = provider.availability || DEFAULT_SLOTS;
  const blocked = new Set(avail.blocked_dates || []);
  if (blocked.has(dateStr)) {
    return res.json({ data: { date: dateStr, slots: [] } });
  }

  const daySlots = avail[dayKey] || [];
  const booked = data.bookings
    .filter((b) => b.provider_id === provider.id && b.status !== 'cancelled' && b.scheduled_at?.startsWith(dateStr))
    .map((b) => {
      const t = new Date(b.scheduled_at);
      return `${t.getHours().toString().padStart(2, '0')}:${t.getMinutes().toString().padStart(2, '0')}`;
    });

  const slots = daySlots.filter((s) => !booked.includes(s));
  res.json({ data: { date: dateStr, slots } });
});

module.exports = router;
