const express = require('express');
const { load, save, nextId } = require('../database');
const { initializeTransaction, verifyTransaction, hasPaystackSecret } = require('../paystack');

const router = express.Router();

function mapProvider(row) {
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
    priceFrom: row.price_from,
    badge: row.badge,
    verified: !!row.verified,
    featured: !!row.featured,
    gradientStart: row.gradient_start,
    gradientEnd: row.gradient_end,
    imageUrl: row.image_url,
    avatarUrl: row.avatar_url,
    status: row.status,
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

router.get('/bootstrap', (req, res) => {
  const data = load();
  const userId = Number(req.query.userId || 1);
  const user = data.users.find(u => u.id === userId);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const providers = data.providers
    .filter(p => p.status === 'active')
    .sort((a, b) => (b.featured - a.featured) || (b.rating - a.rating))
    .map(mapProvider);

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

router.get('/categories', (_req, res) => {
  const data = load();
  res.json({ data: (data.categories || []).map(mapCategory) });
});

router.get('/providers', (req, res) => {
  const data = load();
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

router.get('/providers/:id', (req, res) => {
  const data = load();
  const row = data.providers.find(p => p.id === Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Provider not found' });

  const services = data.services.filter(s => s.provider_id === row.id);
  res.json({
    data: {
      ...mapProvider(row),
      services: services.map(s => ({ id: s.id, name: s.name, duration: s.duration, price: s.price })),
    },
  });
});

router.get('/users/:id', (req, res) => {
  const data = load();
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

router.get('/bookings', (req, res) => {
  const data = load();
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

router.post('/bookings', (req, res) => {
  const data = load();
  const { userId = 1, providerId, serviceId, locationType = 'home', address, scheduledAt, paymentMethod = 'paystack' } = req.body;
  if (!providerId || !serviceId || !scheduledAt) {
    return res.status(400).json({ error: 'providerId, serviceId, and scheduledAt are required' });
  }

  const service = data.services.find(s => s.id === Number(serviceId) && s.provider_id === Number(providerId));
  if (!service) return res.status(404).json({ error: 'Service not found' });

  const fee = Math.round(service.price * 0.1);
  const total = service.price + fee;
  const code = `KHD-${Math.floor(1000 + Math.random() * 9000)}`;
  const id = nextId(data, 'bookings');

  data.bookings.push({
    id,
    user_id: Number(userId),
    provider_id: Number(providerId),
    service_id: Number(serviceId),
    status: 'upcoming',
    location_type: locationType,
    address: address || null,
    scheduled_at: scheduledAt,
    total_amount: total,
    booking_code: code,
    payment_method: paymentMethod,
    created_at: new Date().toISOString(),
  });

  const user = data.users.find(u => u.id === Number(userId));
  if (user) user.bookings_count = (user.bookings_count || 0) + 1;
  save(data);

  res.status(201).json({ data: { id, bookingCode: code, totalAmount: total, serviceFee: fee, status: 'upcoming' } });
});

router.get('/feed', (_req, res) => {
  const data = load();
  res.json({ data: data.feed_posts.map(f => mapFeedPost(f, data)) });
});

router.post('/feed/:id/like', (req, res) => {
  const data = load();
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
  save(data);
  res.json({ data: { liked: idx < 0, likes: post.likes } });
});

router.get('/feed/:id/comments', (req, res) => {
  const data = load();
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

router.post('/feed/:id/comments', (req, res) => {
  const data = load();
  const post = data.feed_posts.find(f => f.id === Number(req.params.id));
  if (!post) return res.status(404).json({ error: 'Post not found' });
  const { userId = 1, text, authorName } = req.body;
  if (!text || !text.trim()) return res.status(400).json({ error: 'text required' });
  const id = nextId(data, 'feed_comments');
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
  save(data);
  res.status(201).json({
    data: { id: comment.id, postId: post.id, authorName: comment.author_name, text: comment.text, createdAt: comment.created_at, commentCount: post.comments },
  });
});

router.get('/tracking/:bookingId', (req, res) => {
  const data = load();
  const booking = data.bookings.find(b => b.id === Number(req.params.bookingId));
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  const provider = data.providers.find(p => p.id === booking.provider_id);
  const destLat = 9.0765;
  const destLng = 7.4898;
  const startLat = provider?.latitude ?? 9.0833;
  const startLng = provider?.longitude ?? 7.495;
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
      address: booking.address,
    },
  });
});

router.get('/notifications', (req, res) => {
  const data = load();
  const userId = Number(req.query.userId || 1);
  const rows = data.notifications.filter(n => n.user_id === userId);
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

router.get('/wallet/transactions', (req, res) => {
  const data = load();
  const userId = Number(req.query.userId || 1);
  const rows = (data.wallet_transactions || []).filter(t => t.user_id === userId);
  res.json({
    data: rows.map(t => ({
      id: t.id,
      type: t.type,
      amount: t.amount,
      description: t.description,
      reference: t.reference,
      createdAt: t.created_at,
    })),
  });
});

router.post('/wallet/topup', (req, res) => {
  const data = load();
  const { userId = 1, amount } = req.body;
  const user = data.users.find(u => u.id === Number(userId));
  if (!user) return res.status(404).json({ error: 'User not found' });
  const amt = Number(amount) || 10000;
  user.wallet_balance += amt;
  const txId = nextId(data, 'wallet_transactions');
  data.wallet_transactions = data.wallet_transactions || [];
  data.wallet_transactions.push({
    id: txId,
    user_id: Number(userId),
    type: 'credit',
    amount: amt,
    description: 'Wallet top-up',
    reference: `TOPUP_${Date.now()}`,
    created_at: new Date().toISOString(),
  });
  save(data);
  res.json({ data: { success: true, newBalance: user.wallet_balance, amount: amt } });
});

router.post('/payments/wallet', (req, res) => {
  const data = load();
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
    id: nextId(data, 'wallet_transactions'),
    user_id: Number(userId),
    type: 'debit',
    amount: amt,
    description: 'Booking payment',
    reference: `WALLET_${Date.now()}`,
    created_at: new Date().toISOString(),
  });
  save(data);
  res.json({ data: { success: true, newBalance: user.wallet_balance, paid: amt } });
});

router.get('/admin/stats', (_req, res) => {
  const data = load();
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

router.post('/payments/initialize', async (req, res) => {
  const { amount, email = 'adaeze@example.com', bookingId } = req.body;
  const reference = `KHADE_${Date.now()}_${bookingId || 'bk'}`;
  const callbackBase = process.env.PAYSTACK_CALLBACK_BASE || `http://localhost:${process.env.PORT || 3001}`;
  const callbackUrl = `${callbackBase}/paystack/callback`;

  try {
    if (hasPaystackSecret()) {
      const result = await initializeTransaction({
        email,
        amountNaira: Number(amount) || 13200,
        reference,
        callbackUrl,
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

router.get('/reviews', (req, res) => {
  const data = load();
  const providerId = req.query.providerId ? Number(req.query.providerId) : null;
  let rows = data.reviews || [];
  if (providerId) rows = rows.filter(r => r.provider_id === providerId);
  res.json({ data: rows.map(r => mapReview(r, data)) });
});

router.post('/reviews', (req, res) => {
  const data = load();
  const { userId = 1, providerId, rating, comment, authorName } = req.body;
  if (!providerId || !rating || !comment) {
    return res.status(400).json({ error: 'providerId, rating, and comment are required' });
  }
  const id = nextId(data, 'reviews');
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
  save(data);
  res.status(201).json({ data: mapReview(review, data) });
});

router.get('/users/:id/saved-providers', (req, res) => {
  const data = load();
  const user = data.users.find(u => u.id === Number(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  const ids = user.saved_provider_ids || [];
  const providers = data.providers.filter(p => ids.includes(p.id)).map(mapProvider);
  res.json({ data: { ids, providers } });
});

router.post('/users/:id/saved-providers/:providerId', (req, res) => {
  const data = load();
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
  save(data);
  res.json({ data: { saved: idx < 0, savedProviderIds: user.saved_provider_ids, count: user.saved_providers } });
});

router.patch('/bookings/:id/cancel', (req, res) => {
  const data = load();
  const id = Number(req.params.id);
  const booking = data.bookings.find(b => b.id === id);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  booking.status = 'cancelled';
  save(data);
  res.json({ data: { id, status: 'cancelled' } });
});

router.post('/bookings/:id/cancel', (req, res) => {
  const data = load();
  const id = Number(req.params.id);
  const booking = data.bookings.find(b => b.id === id);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  booking.status = 'cancelled';
  save(data);
  res.json({ data: { id, status: 'cancelled' } });
});

module.exports = router;
