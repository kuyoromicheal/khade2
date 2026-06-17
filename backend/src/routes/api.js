const express = require('express');
const { load, save, nextId } = require('../database');
const { initializeTransaction, verifyTransaction, hasPaystackSecret } = require('../paystack');
const { optionalAuth, requireAuth } = require('../middleware/auth');
const { cashbackRate, tierLabel } = require('../tier');
const { isConfigured, getClient } = require('../supabase-client');

const DEFAULT_OPENING_HOURS = {
  monday: { open: '09:00', close: '19:00' },
  tuesday: { open: '09:00', close: '19:00' },
  wednesday: { open: '09:00', close: '19:00' },
  thursday: { open: '09:00', close: '20:00' },
  friday: { open: '09:00', close: '20:00' },
  saturday: { open: '08:00', close: '21:00' },
  sunday: null,
};

const router = express.Router();
router.use(optionalAuth);

const authRoutes = require('./auth.routes');
const providerRoutes = require('./provider.routes');
const adminRoutes = require('./admin.routes');

router.use('/auth', authRoutes.router);
router.use('/provider', providerRoutes);
router.use('/admin', adminRoutes);

function wrapAsync(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

['get', 'post', 'patch', 'put', 'delete'].forEach((method) => {
  const register = router[method].bind(router);
  router[method] = (path, ...handlers) =>
    register(path, ...handlers.map((h) => (typeof h === 'function' ? wrapAsync(h) : h)));
});

function mapProvider(row) {
  const photos = row.photos?.length ? row.photos : (row.image_url ? [row.image_url] : []);
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    categorySlug: row.category_slug,
    emoji: row.emoji,
    rating: row.rating,
    reviewCount: row.review_count,
    distanceKm: row.distance_km,
    latitude: row.latitude,
    longitude: row.longitude,
    area: row.area,
    locationArea: row.location_area || row.area,
    priceFrom: row.price_from,
    badge: row.badge,
    verified: !!(row.is_verified || row.verified),
    featured: !!row.featured,
    gradientStart: row.gradient_start,
    gradientEnd: row.gradient_end,
    imageUrl: row.image_url,
    avatarUrl: row.avatar_url,
    phone: row.phone || null,
    status: row.status,
    bio: row.bio || '',
    openingHours: row.opening_hours || DEFAULT_OPENING_HOURS,
    instantConfirm: row.instant_confirm !== false,
    doesHomeVisits: row.does_home_visits !== false && row.visit_types !== 'salon',
    hasSalon: !!row.has_salon || row.visit_types === 'salon' || row.visit_types === 'both',
    acceptsGroups: row.accepts_groups !== false,
    isCertified: !!row.is_certified,
    hasTeam: !!row.has_team,
    photos,
    providerType: row.provider_type || (row.visit_types === 'salon' ? 'salon' : row.visit_types === 'both' ? 'both' : 'mobile'),
    travelRadiusKm: row.travel_radius_km ?? 10,
    travelFeePerKm: Number(row.travel_fee_per_km ?? 0),
    minTravelFee: Number(row.min_travel_fee ?? 0),
    baseArea: row.base_area || row.area || null,
    providerSubtype: row.provider_subtype || 'solo_pro',
    workLocations: row.work_locations || [],
    coverageAreas: row.coverage_areas?.length ? row.coverage_areas : (row.base_area ? [row.base_area] : [row.area]),
  };
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function mapCategory(c) {
  return {
    id: c.id,
    slug: c.slug,
    label: c.label,
    emoji: c.emoji,
    filter: c.filter,
    imageUrl: c.image_url,
  };
}

function mapFeedPost(f, data) {
  const p = data.providers.find(x => x.id === f.provider_id);
  return {
    id: f.id,
    imageEmoji: f.image_emoji,
    imageUrl: f.image_url,
    videoUrl: f.video_url || null,
    mediaType: f.media_type || 'image',
    badge: f.badge,
    caption: f.caption,
    likes: f.likes,
    comments: f.comments,
    provider: {
      id: f.provider_id,
      name: p?.name,
      category: p?.category,
      emoji: p?.emoji,
      rating: p?.rating,
      area: p?.area,
      avatarUrl: p?.avatar_url,
      imageUrl: p?.image_url,
    },
  };
}

function mapFeedComment(c) {
  return {
    id: c.id,
    postId: c.feed_post_id,
    authorName: c.author_name,
    text: c.text,
    createdAt: c.created_at,
  };
}

function mapReview(r, data) {
  const p = data.providers.find(x => x.id === r.provider_id);
  const u = data.users.find(x => x.id === r.user_id);
  return {
    id: r.id,
    providerId: r.provider_id,
    providerName: p?.name,
    rating: r.rating,
    comment: r.comment,
    authorName: r.author_name || u?.name || 'Guest',
    createdAt: r.created_at,
  };
}

async function pushNotification(data, { userId, title, body, emoji = '✦' }) {
  data.notifications = data.notifications || [];
  const id = await nextId(data, 'notifications');
  data.notifications.unshift({
    id,
    user_id: userId,
    title,
    body,
    emoji,
    read: 0,
    created_at: new Date().toISOString(),
  });
  return id;
}

router.get('/bootstrap', async (req, res) => {
  const data = await load();
  const userId = req.user?.id || Number(req.query.userId || 1);
  const user = data.users.find(u => u.id === userId);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const userLat = req.query.lat ? Number(req.query.lat) : null;
  const userLng = req.query.lng ? Number(req.query.lng) : null;

  const providers = data.providers
    .filter(p => p.status === 'active')
    .sort((a, b) => (b.featured - a.featured) || (b.rating - a.rating))
    .map((row) => {
      const p = mapProvider(row);
      if (userLat != null && userLng != null && row.latitude != null && row.longitude != null) {
        p.distanceKm = +haversineKm(userLat, userLng, row.latitude, row.longitude).toFixed(1);
      }
      return p;
    });

  const bookings = data.bookings
    .filter(b => b.user_id === userId)
    .sort((a, b) => new Date(b.scheduled_at) - new Date(a.scheduled_at))
    .map(r => {
      const p = data.providers.find(x => x.id === r.provider_id);
      const s = data.services.find(x => x.id === r.service_id);
      return {
        id: r.id,
        bookingCode: r.booking_code,
        status: r.status,
        locationType: r.location_type,
        address: r.address,
        scheduledAt: r.scheduled_at,
        totalAmount: r.total_amount,
        paymentMethod: r.payment_method,
        provider: { id: r.provider_id, name: p?.name ?? 'Provider', emoji: p?.emoji ?? '💄' },
        service: { id: r.service_id, name: s?.name ?? 'Service' },
      };
    });

  res.json({
    data: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        city: user.city,
        tier: user.tier,
        role: user.role || 'customer',
        providerId: user.provider_id || null,
        walletBalance: user.wallet_balance,
        bookingsCount: user.bookings_count,
        savedProviders: user.saved_providers,
        memberSince: user.member_since,
      },
      categories: (data.categories || []).map(mapCategory),
      providers,
      services: data.services.map(s => ({
        id: s.id,
        providerId: s.provider_id,
        name: s.name,
        duration: s.duration,
        price: s.price,
      })),
      bookings,
      feed: data.feed_posts.map(f => mapFeedPost(f, data)),
      notifications: data.notifications
        .filter(n => n.user_id === userId)
        .map(r => ({
          id: r.id,
          title: r.title,
          body: r.body,
          emoji: r.emoji,
          read: !!r.read,
          createdAt: r.created_at,
        })),
      walletTransactions: (data.wallet_transactions || [])
        .filter(t => t.user_id === userId)
        .map(t => ({
          id: t.id,
          type: t.type,
          amount: t.amount,
          description: t.description,
          reference: t.reference,
          createdAt: t.created_at,
        })),
      savedProviderIds: user.saved_provider_ids || [],
      reviews: (data.reviews || []).map(r => mapReview(r, data)),
      feedComments: (data.feed_comments || []).map(mapFeedComment),
    },
  });
});

router.get('/categories', async (_req, res) => {
  const data = await load();
  res.json({ data: (data.categories || []).map(mapCategory) });
});

router.get('/providers', async (req, res) => {
  const data = await load();
  let rows = data.providers.filter(p => p.status === 'active');

  if (req.query.featured === 'true') rows = rows.filter(p => p.featured);
  if (req.query.category && req.query.category !== 'All') {
    const cat = req.query.category.toLowerCase();
    rows = rows.filter(p =>
      p.category.toLowerCase().includes(cat) ||
      (p.category_slug && p.category_slug.includes(cat))
    );
  }
  if (req.query.area) {
    const area = req.query.area.toLowerCase();
    rows = rows.filter(p => p.area.toLowerCase().includes(area));
  }
  if (req.query.minPrice) rows = rows.filter(p => p.price_from >= Number(req.query.minPrice));
  if (req.query.maxPrice) rows = rows.filter(p => p.price_from <= Number(req.query.maxPrice));

  const userLat = req.query.lat ? Number(req.query.lat) : null;
  const userLng = req.query.lng ? Number(req.query.lng) : null;
  const maxDistance = req.query.maxDistance ? Number(req.query.maxDistance) : null;

  let mapped = rows.map((row) => {
    const p = mapProvider(row);
    if (userLat != null && userLng != null && row.latitude != null && row.longitude != null) {
      p.distanceKm = +haversineKm(userLat, userLng, row.latitude, row.longitude).toFixed(1);
    }
    return p;
  });

  if (maxDistance != null && userLat != null) {
    mapped = mapped.filter(p => p.distanceKm <= maxDistance);
  }

  const sortBy = req.query.sortBy || 'featured';
  mapped.sort((a, b) => {
    switch (sortBy) {
      case 'price_asc': return a.priceFrom - b.priceFrom;
      case 'price_desc': return b.priceFrom - a.priceFrom;
      case 'distance': return a.distanceKm - b.distanceKm;
      case 'rating': return b.rating - a.rating;
      default: return (b.featured - a.featured) || (b.rating - a.rating);
    }
  });

  res.json({ data: mapped });
});

router.get('/providers/recently-viewed', async (req, res) => {
  const userId = req.user?.id || Number(req.query.userId || 0);
  if (!userId) return res.json({ data: [] });

  const data = await load();
  let viewRows = [];

  if (isConfigured()) {
    const client = getClient();
    const { data: rows } = await client
      .from('khade_provider_views')
      .select('provider_id, viewed_at')
      .eq('user_id', userId)
      .order('viewed_at', { ascending: false })
      .limit(10);
    viewRows = rows || [];
  } else {
    viewRows = (data.provider_views || [])
      .filter(v => v.user_id === userId)
      .sort((a, b) => new Date(b.viewed_at) - new Date(a.viewed_at))
      .slice(0, 10);
  }

  const userLat = req.query.lat ? Number(req.query.lat) : null;
  const userLng = req.query.lng ? Number(req.query.lng) : null;

  const providers = viewRows
    .map(v => {
      const row = data.providers.find(p => p.id === v.provider_id && p.status === 'active');
      if (!row) return null;
      const p = mapProvider(row);
      if (userLat != null && userLng != null && row.latitude != null && row.longitude != null) {
        p.distanceKm = +haversineKm(userLat, userLng, row.latitude, row.longitude).toFixed(1);
      }
      return p;
    })
    .filter(Boolean);

  res.json({ data: providers });
});

router.get('/providers/:id', async (req, res) => {
  const data = await load();
  const row = data.providers.find(p => p.id === Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Provider not found' });

  const services = data.services.filter(s => s.provider_id === row.id);
  const reviews = (data.reviews || []).filter(r => r.provider_id === row.id);
  const staff = (data.staff || []).filter(s => s.provider_id === row.id && s.active !== 0);
  const branches = (data.provider_branches || []).filter(b => b.provider_id === row.id);

  res.json({
    data: {
      ...mapProvider(row),
      services: services.map(s => ({ id: s.id, name: s.name, duration: s.duration, price: s.price })),
      reviews: reviews.map(r => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        authorName: r.author_name,
        createdAt: r.created_at,
      })),
      team: staff.map(s => ({
        id: s.id,
        name: s.name,
        role: s.role || 'Specialist',
        rating: s.rating || 5,
        avatarUrl: s.avatar_url,
      })),
      branches: branches.map(b => ({
        id: b.id,
        branchName: b.branch_name,
        address: b.address,
        lat: b.lat,
        lng: b.lng,
        isPrimary: !!b.is_primary,
      })),
    },
  });
});

router.post('/providers/:id/view', async (req, res) => {
  const providerId = Number(req.params.id);
  const userId = req.user?.id || Number(req.body.userId || req.query.userId || 0);
  if (!userId) return res.status(400).json({ error: 'userId required' });

  if (isConfigured()) {
    const client = getClient();
    await client.from('khade_provider_views').upsert(
      { user_id: userId, provider_id: providerId, viewed_at: new Date().toISOString() },
      { onConflict: 'user_id,provider_id' },
    );
  } else {
    const data = await load();
    data.provider_views = data.provider_views || [];
    const existing = data.provider_views.find(v => v.user_id === userId && v.provider_id === providerId);
    if (existing) existing.viewed_at = new Date().toISOString();
    else data.provider_views.push({ user_id: userId, provider_id: providerId, viewed_at: new Date().toISOString() });
    await save(data);
  }
  res.json({ data: { success: true } });
});

router.get('/users/:id', async (req, res) => {
  const data = await load();
  const row = data.users.find(u => u.id === Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'User not found' });
  res.json({
    data: {
      id: row.id,
      name: row.name,
      email: row.email,
      city: row.city,
      tier: row.tier,
      walletBalance: row.wallet_balance,
      bookingsCount: row.bookings_count,
      savedProviders: row.saved_providers,
      memberSince: row.member_since,
    },
  });
});

router.get('/bookings', async (req, res) => {
  const data = await load();
  const userId = Number(req.query.userId || 1);
  const status = req.query.status;

  let rows = data.bookings.filter(b => b.user_id === userId);
  if (status) rows = rows.filter(b => b.status === status);
  rows.sort((a, b) => new Date(b.scheduled_at) - new Date(a.scheduled_at));

  res.json({
    data: rows.map(r => {
      const p = data.providers.find(x => x.id === r.provider_id);
      const s = data.services.find(x => x.id === r.service_id);
      return {
        id: r.id,
        bookingCode: r.booking_code,
        status: r.status,
        locationType: r.location_type,
        address: r.address,
        scheduledAt: r.scheduled_at,
        totalAmount: r.total_amount,
        paymentMethod: r.payment_method,
        provider: { id: r.provider_id, name: p?.name ?? 'Provider', emoji: p?.emoji ?? '💄' },
        service: { id: r.service_id, name: s?.name ?? 'Service' },
      };
    }),
  });
});

router.post('/bookings', async (req, res) => {
  const data = await load();
  const { userId = 1, providerId, serviceId, locationType = 'home', address, scheduledAt, paymentMethod = 'cash', destLat, destLng, note, totalAmount } = req.body;
  if (!providerId || !serviceId || !scheduledAt) {
    return res.status(400).json({ error: 'providerId, serviceId, and scheduledAt are required' });
  }

  const service = data.services.find(s => s.id === Number(serviceId) && s.provider_id === Number(providerId));
  if (!service) return res.status(404).json({ error: 'Service not found' });

  const fee = totalAmount != null
    ? Math.max(0, Number(totalAmount) - service.price)
    : Math.round(service.price * 0.1);
  const total = totalAmount != null ? Number(totalAmount) : service.price + fee;
  const code = `KHD-${Math.floor(1000 + Math.random() * 9000)}`;
  const id = await nextId(data, 'bookings');
  const payMethod = (paymentMethod || 'cash').toLowerCase();

  data.bookings.push({
    id,
    user_id: Number(userId),
    provider_id: Number(providerId),
    service_id: Number(serviceId),
    status: 'upcoming',
    location_type: locationType,
    address: address || null,
    dest_lat: destLat != null ? Number(destLat) : null,
    dest_lng: destLng != null ? Number(destLng) : null,
    scheduled_at: scheduledAt,
    total_amount: total,
    booking_code: code,
    payment_method: payMethod,
    payment_status: payMethod === 'cash' ? 'pending' : 'paid',
    note: note || null,
    created_at: new Date().toISOString(),
  });

  const user = data.users.find(u => u.id === Number(userId));
  if (user) user.bookings_count = (user.bookings_count || 0) + 1;

  const provider = data.providers.find(p => p.id === Number(providerId));
  await pushNotification(data, {
    userId: Number(userId),
    title: 'Booking Confirmed!',
    body: `${service.name} with ${provider?.name ?? 'your provider'} · ${code}`,
    emoji: provider?.emoji ?? '✦',
  });

  await save(data, ['bookings', 'users', 'notifications', '_counters']);

  res.status(201).json({ data: { id, bookingCode: code, totalAmount: total, serviceFee: fee, status: 'upcoming' } });
});

router.get('/feed', async (_req, res) => {
  const data = await load();
  res.json({ data: data.feed_posts.map(f => mapFeedPost(f, data)) });
});

router.post('/feed/:id/like', async (req, res) => {
  const data = await load();
  const post = data.feed_posts.find(f => f.id === Number(req.params.id));
  if (!post) return res.status(404).json({ error: 'Post not found' });
  const userId = Number(req.body.userId || 1);
  post.liked_by = post.liked_by || [];
  const idx = post.liked_by.indexOf(userId);
  if (idx >= 0) {
    post.liked_by.splice(idx, 1);
    post.likes = Math.max(0, (post.likes || 0) - 1);
  } else {
    post.liked_by.push(userId);
    post.likes = (post.likes || 0) + 1;
  }
  await save(data, ['feed_posts']);
  res.json({ data: { liked: idx < 0, likes: post.likes } });
});

router.get('/feed/:id/comments', async (req, res) => {
  const data = await load();
  const postId = Number(req.params.id);
  const rows = (data.feed_comments || []).filter(c => c.feed_post_id === postId);
  res.json({
    data: rows.map(c => ({
      id: c.id,
      postId: c.feed_post_id,
      authorName: c.author_name,
      text: c.text,
      createdAt: c.created_at,
    })),
  });
});

router.post('/feed/:id/comments', async (req, res) => {
  const data = await load();
  const post = data.feed_posts.find(f => f.id === Number(req.params.id));
  if (!post) return res.status(404).json({ error: 'Post not found' });
  const { userId = 1, text, authorName } = req.body;
  if (!text || !text.trim()) return res.status(400).json({ error: 'text required' });
  const id = await nextId(data, 'feed_comments');
  data.feed_comments = data.feed_comments || [];
  const comment = {
    id,
    feed_post_id: post.id,
    user_id: Number(userId),
    author_name: authorName || data.users.find(u => u.id === Number(userId))?.name || 'Guest',
    text: text.trim(),
    created_at: new Date().toISOString(),
  };
  data.feed_comments.push(comment);
  post.comments = (post.comments || 0) + 1;
  await save(data, ['feed_comments', 'feed_posts', '_counters']);
  res.status(201).json({
    data: { id: comment.id, postId: post.id, authorName: comment.author_name, text: comment.text, createdAt: comment.created_at, commentCount: post.comments },
  });
});

router.get('/tracking/:bookingId', async (req, res) => {
  const data = await load();
  const booking = data.bookings.find(b => b.id === Number(req.params.bookingId));
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  const provider = data.providers.find(p => p.id === booking.provider_id);
  let destLat;
  let destLng;
  if (booking.location_type === 'salon' && provider?.latitude != null && provider?.longitude != null) {
    destLat = provider.latitude;
    destLng = provider.longitude;
  } else if (booking.dest_lat != null && booking.dest_lng != null) {
    destLat = booking.dest_lat;
    destLng = booking.dest_lng;
  } else {
    destLat = 9.0765;
    destLng = 7.4898;
  }
  const startLat = provider?.latitude ?? destLat;
  const startLng = provider?.longitude ?? destLng;
  const elapsed = (Date.now() % 600000) / 600000;
  const progress = Math.min(0.92, 0.15 + elapsed * 0.75);
  const curLat = startLat + (destLat - startLat) * progress;
  const curLng = startLng + (destLng - startLng) * progress;
  const totalKm = haversineKm(startLat, startLng, destLat, destLng);
  const remainKm = +(totalKm * (1 - progress)).toFixed(1);
  const etaMinutes = Math.max(1, Math.round(remainKm * 4));
  const step = progress < 0.25 ? 1 : progress < 0.5 ? 2 : progress < 0.8 ? 3 : 4;

  res.json({
    data: {
      bookingId: booking.id,
      providerLat: curLat,
      providerLng: curLng,
      destinationLat: destLat,
      destinationLng: destLng,
      providerStartLat: startLat,
      providerStartLng: startLng,
      distanceKm: remainKm,
      etaMinutes,
      progressStep: step,
      providerName: provider?.name,
      providerAvatarUrl: provider?.avatar_url,
      providerPhone: provider?.phone || null,
      bookingCode: booking.booking_code,
      address: booking.address,
    },
  });
});

router.get('/notifications', async (req, res) => {
  const data = await load();
  const userId = Number(req.query.userId || 1);
  const rows = data.notifications
    .filter(n => n.user_id === userId)
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  res.json({
    data: rows.map(r => ({
      id: r.id,
      title: r.title,
      body: r.body,
      emoji: r.emoji,
      read: !!r.read,
      createdAt: r.created_at,
    })),
  });
});

router.post('/notifications/mark-all-read', async (req, res) => {
  const data = await load();
  const userId = Number(req.body.userId || 1);
  data.notifications.filter(n => n.user_id === userId).forEach(n => { n.read = 1; });
  await save(data, ['notifications']);
  res.json({ data: { success: true } });
});

router.patch('/notifications/:id/read', async (req, res) => {
  const data = await load();
  const row = data.notifications.find(n => n.id === Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Notification not found' });
  row.read = 1;
  await save(data, ['notifications']);
  res.json({ data: { id: row.id, read: true } });
});

router.get('/wallet/transactions', async (req, res) => {
  const data = await load();
  const userId = req.user?.id || Number(req.query.userId || 1);
  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const offset = Number(req.query.offset) || 0;
  const rows = (data.wallet_transactions || [])
    .filter(t => t.user_id === userId)
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(offset, offset + limit);
  res.json({
    data: rows.map(t => ({
      id: t.id,
      type: t.type,
      amount: t.amount,
      description: t.description,
      reference: t.reference,
      status: t.status || 'completed',
      createdAt: t.created_at,
    })),
    meta: { userId, cashbackRate: Math.round(cashbackRate(data.users.find(u => u.id === userId)?.tier) * 100) },
  });
});

router.post('/wallet/topup', async (req, res) => {
  const data = await load();
  const userId = req.user?.id || Number(req.body.userId || 1);
  const user = data.users.find(u => u.id === userId);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const { amount, paystackReference } = req.body;
  const amt = Number(amount) || 10000;

  if (paystackReference) {
    const existing = (data.wallet_transactions || []).find(t => t.reference === paystackReference);
    if (existing) {
      return res.json({ data: { success: true, newBalance: user.wallet_balance, amount: existing.amount, duplicate: true } });
    }
    if (hasPaystackSecret()) {
      const verified = await verifyTransaction(paystackReference);
      if (verified.status !== 'success') {
        return res.status(400).json({ error: 'Paystack payment not verified' });
      }
    }
  }

  user.wallet_balance = (user.wallet_balance || 0) + amt;
  const txId = await nextId(data, 'wallet_transactions');
  data.wallet_transactions = data.wallet_transactions || [];
  data.wallet_transactions.push({
    id: txId,
    user_id: userId,
    type: 'credit',
    amount: amt,
    description: 'Wallet top-up via Paystack',
    reference: paystackReference || `TOPUP_${Date.now()}`,
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
  res.json({ data: { success: true, newBalance: user.wallet_balance, amount: amt } });
});

router.post('/payments/wallet', async (req, res) => {
  const data = await load();
  const { userId = 1, amount } = req.body;
  const user = data.users.find(u => u.id === Number(userId));
  if (!user) return res.status(404).json({ error: 'User not found' });
  const amt = Number(amount);
  if (!amt || amt <= 0) return res.status(400).json({ error: 'Invalid amount' });
  if (user.wallet_balance < amt) {
    return res.status(400).json({ error: 'Insufficient wallet balance', walletBalance: user.wallet_balance });
  }
  user.wallet_balance -= amt;
  data.wallet_transactions = data.wallet_transactions || [];
  data.wallet_transactions.push({
    id: await nextId(data, 'wallet_transactions'),
    user_id: Number(userId),
    type: 'debit',
    amount: amt,
    description: 'Booking payment',
    reference: `WALLET_${Date.now()}`,
    created_at: new Date().toISOString(),
  });
  await save(data, ['users', 'wallet_transactions', '_counters']);
  res.json({ data: { success: true, newBalance: user.wallet_balance, paid: amt } });
});

router.get('/admin/stats', async (_req, res) => {
  const data = await load();
  const completed = data.bookings.filter(b => b.status === 'completed');
  const revenue = completed.reduce((sum, b) => sum + b.total_amount, 0);

  res.json({
    data: {
      totalRevenue: revenue || 8400000,
      platformFees: Math.round((revenue || 8400000) * 0.1) || 840000,
      bookings: data.bookings.length || 1204,
      activeUsers: data.users.length || 3847,
      providers: data.providers.length,
    },
  });
});

router.get('/payments/banks', async (_req, res) => {
  try {
    const { listBanks } = require('../paystack');
    const banks = await listBanks();
    res.json({ data: banks });
  } catch (e) {
    res.status(502).json({ error: e.message });
  }
});

router.post('/payments/resolve-account', async (req, res) => {
  const { accountNumber, bankCode } = req.body;
  if (!accountNumber || !bankCode) {
    return res.status(400).json({ error: 'accountNumber and bankCode required' });
  }
  try {
    const { resolveBankAccount } = require('../paystack');
    const result = await resolveBankAccount(accountNumber, bankCode);
    res.json({ data: result });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/users/fcm-token', requireAuth, async (req, res) => {
  const { token, platform } = req.body;
  if (!token) return res.status(400).json({ error: 'token required' });
  const data = await load();
  const user = data.users.find((u) => u.id === req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  user.fcm_token = token;
  await save(data, ['users']);
  if (isConfigured()) {
    const client = getClient();
    await client.from('khade_fcm_tokens').upsert(
      { id: req.user.id, user_id: req.user.id, token, platform: platform || 'unknown' },
      { onConflict: 'id' },
    );
  }
  res.json({ data: { success: true } });
});

router.post('/payments/initialize', async (req, res) => {
  const { amount, email = 'adaeze@example.com', bookingId, userId } = req.body;
  const reference = `KHADE_${Date.now()}_${bookingId || 'bk'}`;
  const callbackBase = process.env.PAYSTACK_CALLBACK_BASE || `http://localhost:${process.env.PORT || 3001}`;
  const callbackUrl = `${callbackBase}/paystack/callback`;
  const payerId = req.user?.id || userId;

  try {
    if (hasPaystackSecret()) {
      const result = await initializeTransaction({
        email,
        amountNaira: Number(amount) || 13200,
        reference,
        callbackUrl,
        metadata: payerId ? { user_id: String(payerId) } : {},
      });
      return res.json({
        data: {
          authorizationUrl: result.authorizationUrl,
          reference: result.reference,
          amount: Number(amount) || 13200,
          email,
          publicKey: process.env.PAYSTACK_PUBLIC_KEY || '',
        },
      });
    }
  } catch (e) {
    return res.status(502).json({ error: e.message });
  }

  res.status(503).json({
    error: 'Paystack not configured. Set PAYSTACK_SECRET_KEY in backend/.env',
  });
});

router.post('/payments/verify', async (req, res) => {
  const { reference } = req.body;
  if (!reference) return res.status(400).json({ error: 'reference required' });

  try {
    if (hasPaystackSecret()) {
      const result = await verifyTransaction(reference);
      return res.json({
        data: {
          status: result.status === 'success' ? 'success' : 'failed',
          reference: result.reference,
          paidAt: result.paidAt,
          amount: result.amount,
          channel: result.channel,
        },
      });
    }
  } catch (e) {
    return res.status(502).json({ error: e.message });
  }

  res.status(503).json({ error: 'Paystack not configured' });
});

router.get('/reviews', async (req, res) => {
  const data = await load();
  const providerId = req.query.providerId ? Number(req.query.providerId) : null;
  let rows = data.reviews || [];
  if (providerId) rows = rows.filter(r => r.provider_id === providerId);
  res.json({ data: rows.map(r => mapReview(r, data)) });
});

router.post('/reviews', async (req, res) => {
  const data = await load();
  const { userId = 1, providerId, rating, comment, authorName } = req.body;
  if (!providerId || !rating || !comment) {
    return res.status(400).json({ error: 'providerId, rating, and comment are required' });
  }
  const id = await nextId(data, 'reviews');
  const review = {
    id,
    user_id: Number(userId),
    provider_id: Number(providerId),
    rating: Math.min(5, Math.max(1, Number(rating))),
    comment,
    author_name: authorName || data.users.find(u => u.id === Number(userId))?.name,
    created_at: new Date().toISOString(),
  };
  data.reviews = data.reviews || [];
  data.reviews.unshift(review);

  const provider = data.providers.find(p => p.id === Number(providerId));
  if (provider) {
    const provReviews = data.reviews.filter(r => r.provider_id === provider.id);
    provider.review_count = provReviews.length;
    provider.rating = +(provReviews.reduce((s, r) => s + r.rating, 0) / provReviews.length).toFixed(1);
  }
  await save(data, ['reviews', 'providers', '_counters']);
  res.status(201).json({ data: mapReview(review, data) });
});

router.get('/users/:id/saved-providers', async (req, res) => {
  const data = await load();
  const user = data.users.find(u => u.id === Number(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  const ids = user.saved_provider_ids || [];
  const providers = data.providers.filter(p => ids.includes(p.id)).map(mapProvider);
  res.json({ data: { ids, providers } });
});

router.post('/users/:id/saved-providers/:providerId', async (req, res) => {
  const data = await load();
  const user = data.users.find(u => u.id === Number(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  const pid = Number(req.params.providerId);
  user.saved_provider_ids = user.saved_provider_ids || [];
  const idx = user.saved_provider_ids.indexOf(pid);
  if (idx >= 0) {
    user.saved_provider_ids.splice(idx, 1);
  } else {
    user.saved_provider_ids.push(pid);
  }
  user.saved_providers = user.saved_provider_ids.length;
  await save(data, ['users']);
  res.json({ data: { saved: idx < 0, savedProviderIds: user.saved_provider_ids, count: user.saved_providers } });
});

router.patch('/bookings/:id/cancel', async (req, res) => {
  const data = await load();
  const id = Number(req.params.id);
  const booking = data.bookings.find(b => b.id === id);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  booking.status = 'cancelled';
  const provider = data.providers.find(p => p.id === booking.provider_id);
  await pushNotification(data, {
    userId: booking.user_id,
    title: 'Booking Cancelled',
    body: `${booking.booking_code} with ${provider?.name ?? 'provider'} was cancelled`,
    emoji: '✕',
  });
  await save(data, ['bookings', 'notifications', '_counters']);
  res.json({ data: { id, status: 'cancelled' } });
});

router.post('/bookings/:id/cancel', async (req, res) => {
  const data = await load();
  const id = Number(req.params.id);
  const booking = data.bookings.find(b => b.id === id);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  booking.status = 'cancelled';
  const provider = data.providers.find(p => p.id === booking.provider_id);
  await pushNotification(data, {
    userId: booking.user_id,
    title: 'Booking Cancelled',
    body: `${booking.booking_code} with ${provider?.name ?? 'provider'} was cancelled`,
    emoji: '✕',
  });
  await save(data, ['bookings', 'notifications', '_counters']);
  res.json({ data: { id, status: 'cancelled' } });
});

router.get('/messages/conversations', requireAuth, async (req, res) => {
  const data = await load();
  const user = req.user;
  const msgs = data.messages || [];

  if (user.role === 'provider' && user.provider_id) {
    const providerBookings = data.bookings.filter(
      (b) => b.provider_id === user.provider_id && b.status !== 'cancelled',
    );
    const convos = providerBookings.map((b) => {
      const customer = data.users.find((u) => u.id === b.user_id);
      const service = data.services.find((s) => s.id === b.service_id);
      const thread = msgs
        .filter((m) => m.booking_id === b.id)
        .sort((a, c) => new Date(c.created_at) - new Date(a.created_at));
      const last = thread[0];
      const customerName = customer?.name ?? 'Client';
      return {
        bookingId: b.id,
        customerName,
        customerEmoji: '👤',
        providerName: customerName,
        providerEmoji: '👤',
        lastMessage: last?.body ?? `${service?.name ?? 'Booking'} · ${b.status}`,
        updatedAt: (last?.created_at ?? b.scheduled_at ?? '').toString().slice(0, 10),
        unread: 0,
      };
    });
    convos.sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || ''));
    return res.json({ data: convos });
  }

  const userId = Number(req.query.userId || user.id || 1);
  const userBookings = data.bookings.filter((b) => b.user_id === userId && b.status !== 'cancelled');
  const convos = userBookings.map((b) => {
    const provider = data.providers.find((p) => p.id === b.provider_id);
    const service = data.services.find((s) => s.id === b.service_id);
    const thread = msgs
      .filter((m) => m.booking_id === b.id)
      .sort((a, c) => new Date(c.created_at) - new Date(a.created_at));
    const last = thread[0];
    return {
      bookingId: b.id,
      providerName: provider?.name ?? 'Provider',
      providerEmoji: provider?.emoji ?? '💄',
      lastMessage: last?.body ?? `${service?.name ?? 'Booking'} · ${b.status}`,
      updatedAt: (last?.created_at ?? b.scheduled_at ?? '').toString().slice(0, 10),
      unread: 0,
    };
  });
  convos.sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || ''));
  res.json({ data: convos });
});

function canAccessBooking(booking, user) {
  if (!booking || !user) return false;
  if (user.role === 'admin') return true;
  if (user.role === 'provider' && booking.provider_id === user.provider_id) return true;
  if (booking.user_id === user.id) return true;
  return false;
}

router.get('/messages/:bookingId', requireAuth, async (req, res) => {
  const data = await load();
  const bookingId = Number(req.params.bookingId);
  const booking = data.bookings.find((b) => b.id === bookingId);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  if (!canAccessBooking(booking, req.user)) return res.status(403).json({ error: 'Forbidden' });

  const msgs = (data.messages || [])
    .filter((m) => m.booking_id === bookingId)
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

  res.json({
    data: msgs.map((m) => ({
      id: m.id,
      bookingId: m.booking_id,
      senderId: m.sender_id,
      senderName: m.sender_name,
      body: m.body,
      createdAt: m.created_at,
      isMine: m.sender_id === req.user.id,
    })),
  });
});

router.post('/messages', requireAuth, async (req, res) => {
  const { bookingId, body } = req.body;
  if (!bookingId || !body?.trim()) {
    return res.status(400).json({ error: 'bookingId and body are required' });
  }

  const data = await load();
  const booking = data.bookings.find((b) => b.id === Number(bookingId));
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  if (!canAccessBooking(booking, req.user)) return res.status(403).json({ error: 'Forbidden' });

  data.messages = data.messages || [];
  const msg = {
    id: await nextId(data, 'messages'),
    booking_id: Number(bookingId),
    sender_id: req.user.id,
    sender_name: req.user.name,
    body: body.trim(),
    created_at: new Date().toISOString(),
  };
  data.messages.push(msg);

  const provider = data.providers.find((p) => p.id === booking.provider_id);
  const notifyUserId = req.user.role === 'provider' ? booking.user_id : provider?.owner_user_id;
  if (notifyUserId) {
    await pushNotification(data, {
      userId: notifyUserId,
      title: `Message from ${req.user.name}`,
      body: body.trim().slice(0, 80),
      emoji: '💬',
    });
  }

  await save(data, ['messages', 'notifications', '_counters']);
  res.status(201).json({
    data: {
      id: msg.id,
      bookingId: msg.booking_id,
      senderId: msg.sender_id,
      senderName: msg.sender_name,
      body: msg.body,
      createdAt: msg.created_at,
      isMine: true,
    },
  });
});

module.exports = router;
