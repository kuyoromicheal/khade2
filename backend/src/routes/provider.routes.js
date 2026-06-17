const express = require('express');
const { load, save, nextId } = require('../database');
const { requireAuth, requireRole } = require('../middleware/auth');
const { DEFAULT_SLOTS } = require('./auth.routes');

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

router.post('/onboard', requireAuth, requireRole('provider'), async (req, res) => {
  const {
    categorySlug, services, visitTypes, area, bio, phone, providerType, providerSubtype,
    workLocations, coverageAreas, travelRadiusKm, brandName, website, additionalCategories,
    crewSize, workStyles, address, latitude, longitude, travelFeeNote,
  } = req.body;
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
  if (brandName) {
    provider.name = brandName;
    provider.business_name = brandName;
  }
  if (website) provider.website = website;
  if (Array.isArray(additionalCategories)) provider.additional_categories = additionalCategories;
  if (crewSize) provider.crew_size = crewSize;
  if (Array.isArray(workStyles)) {
    provider.work_styles = workStyles;
    provider.does_home_visits = workStyles.includes('mobile');
    provider.has_salon = workStyles.includes('in_studio');
    provider.does_virtual = workStyles.includes('virtual');
  }
  if (address) provider.address = address;
  if (latitude != null) provider.latitude = Number(latitude);
  if (longitude != null) provider.longitude = Number(longitude);
  if (travelFeeNote) provider.travel_fee_note = travelFeeNote;
  if (area) provider.area = area;
  if (bio) provider.bio = bio;
  if (phone) provider.phone = phone;
  if (visitTypes) provider.visit_types = visitTypes;
  if (providerType) provider.provider_type = providerType;
  if (providerSubtype) provider.provider_subtype = providerSubtype;
  if (Array.isArray(workLocations)) provider.work_locations = workLocations;
  if (Array.isArray(coverageAreas)) provider.coverage_areas = coverageAreas;
  if (travelRadiusKm) provider.travel_radius_km = Number(travelRadiusKm);
  if (area) provider.base_area = area;
  if (Array.isArray(coverageAreas) && coverageAreas.length) provider.coverage_areas = coverageAreas;
  else if (area) provider.coverage_areas = [area];
  provider.status = 'active';
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

function mapProviderBooking(booking, data) {
  const customer = data.users.find((u) => u.id === booking.user_id);
  const service = data.services.find((s) => s.id === booking.service_id);
  return {
    id: booking.id,
    bookingCode: booking.booking_code,
    status: booking.status,
    locationType: booking.location_type,
    address: booking.address,
    scheduledAt: booking.scheduled_at,
    totalAmount: booking.total_amount,
    paymentMethod: booking.payment_method,
    userId: booking.user_id,
    customer: {
      id: customer?.id,
      name: customer?.name ?? 'Client',
      phone: customer?.phone ?? null,
      email: customer?.email ?? null,
    },
    service: {
      id: service?.id ?? booking.service_id,
      name: service?.name ?? 'Service',
    },
  };
}

router.get('/bookings', requireAuth, requireRole('provider', 'admin'), async (req, res) => {
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  let rows = data.bookings.filter((b) => b.provider_id === provider.id);
  const { status, from, to } = req.query;
  if (status) rows = rows.filter((b) => b.status === status);
  if (from) rows = rows.filter((b) => (b.scheduled_at || '').slice(0, 10) >= from);
  if (to) rows = rows.filter((b) => (b.scheduled_at || '').slice(0, 10) <= to);
  rows.sort((a, b) => new Date(a.scheduled_at) - new Date(b.scheduled_at));
  res.json({ data: rows.map((b) => mapProviderBooking(b, data)) });
});

router.get('/clients', requireAuth, requireRole('provider'), async (req, res) => {
  const data = await load();
  const provider = providerForUser(data, req.user);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const bookings = data.bookings.filter((b) => b.provider_id === provider.id && b.status !== 'cancelled');
  const byUser = new Map();
  for (const b of bookings) {
    const customer = data.users.find((u) => u.id === b.user_id);
    const uid = b.user_id;
    if (!byUser.has(uid)) {
      byUser.set(uid, {
        userId: uid,
        name: customer?.name ?? 'Client',
        phone: customer?.phone ?? null,
        email: customer?.email ?? null,
        bookingCount: 0,
        lifetimeValue: 0,
        lastBookingAt: b.scheduled_at,
        upcomingCount: 0,
      });
    }
    const c = byUser.get(uid);
    c.bookingCount += 1;
    if (b.status === 'completed') c.lifetimeValue += b.total_amount;
    if (b.status === 'upcoming') c.upcomingCount += 1;
    if ((b.scheduled_at || '') > (c.lastBookingAt || '')) c.lastBookingAt = b.scheduled_at;
  }
  const clients = [...byUser.values()].sort((a, b) => new Date(b.lastBookingAt) - new Date(a.lastBookingAt));
  res.json({ data: clients });
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

    const customer = data.users.find((u) => u.id === booking.user_id);
    if (customer) {
      const { cashbackRate, applyTierUpgrade, tierLabel } = require('../tier');
      const paidViaWallet = (booking.payment_method || '').toLowerCase() === 'wallet';
      const rate = paidViaWallet ? cashbackRate(customer.tier) : 0;
      if (rate > 0) {
        const cashback = Math.round(booking.total_amount * rate);
        customer.wallet_balance = (customer.wallet_balance || 0) + cashback;
        data.wallet_transactions = data.wallet_transactions || [];
        data.wallet_transactions.push({
          id: await nextId(data, 'wallet_transactions'),
          user_id: customer.id,
          type: 'cashback',
          amount: cashback,
          description: `${tierLabel(customer.tier)} cashback — ${Math.round(rate * 100)}% on ${booking.booking_code}`,
          reference: `CASHBACK_${booking.booking_code}`,
          status: 'completed',
          created_at: new Date().toISOString(),
        });
        data.notifications = data.notifications || [];
        data.notifications.unshift({
          id: await nextId(data, 'notifications'),
          user_id: customer.id,
          title: 'Cashback credited ✦',
          body: `₦${cashback.toLocaleString()} added to your wallet`,
          emoji: '💰',
          read: 0,
          created_at: new Date().toISOString(),
        });
      }
      const tierChange = applyTierUpgrade(customer, data);
      if (tierChange.upgraded) {
        data.notifications = data.notifications || [];
        data.notifications.unshift({
          id: await nextId(data, 'notifications'),
          user_id: customer.id,
          title: `You're now ${tierChange.newTier}! 🎉`,
          body: `You've unlocked ${tierChange.newTier} member perks`,
          emoji: '✦',
          read: 0,
          created_at: new Date().toISOString(),
        });
      }
    }
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
