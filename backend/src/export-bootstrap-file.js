/** Export bootstrap JSON from khade.json (no server needed). */
const fs = require('fs');
const path = require('path');
const { load } = require('./database');

// Reuse mapping from api.js inline
function mapProvider(row) {
  return {
    id: row.id, name: row.name, category: row.category, categorySlug: row.category_slug,
    emoji: row.emoji, rating: row.rating, reviewCount: row.review_count, distanceKm: row.distance_km,
    area: row.area, priceFrom: row.price_from, badge: row.badge, verified: !!row.verified,
    featured: !!row.featured, gradientStart: row.gradient_start, gradientEnd: row.gradient_end,
    imageUrl: row.image_url, avatarUrl: row.avatar_url, status: row.status,
    latitude: row.latitude, longitude: row.longitude,
  };
}

const data = load();
const userId = 1;
const user = data.users.find(u => u.id === userId);

const out = {
  user: {
    id: user.id, name: user.name, email: user.email, city: user.city, tier: user.tier,
    walletBalance: user.wallet_balance, bookingsCount: user.bookings_count,
    savedProviders: user.saved_providers, memberSince: user.member_since,
  },
  categories: (data.categories || []).map(c => ({
    id: c.id, slug: c.slug, label: c.label, emoji: c.emoji, filter: c.filter, imageUrl: c.image_url,
  })),
  providers: data.providers.filter(p => p.status === 'active').sort((a, b) => (b.featured - a.featured) || (b.rating - a.rating)).map(mapProvider),
  services: data.services.map(s => ({ id: s.id, providerId: s.provider_id, name: s.name, duration: s.duration, price: s.price })),
  bookings: data.bookings.filter(b => b.user_id === userId).map(r => {
    const p = data.providers.find(x => x.id === r.provider_id);
    const s = data.services.find(x => x.id === r.service_id);
    return {
      id: r.id, bookingCode: r.booking_code, status: r.status, locationType: r.location_type,
      address: r.address, scheduledAt: r.scheduled_at, totalAmount: r.total_amount,
      paymentMethod: r.payment_method,
      provider: { id: r.provider_id, name: p?.name, emoji: p?.emoji },
      service: { id: r.service_id, name: s?.name },
    };
  }),
  feed: data.feed_posts.map(f => {
    const p = data.providers.find(x => x.id === f.provider_id);
    return {
      id: f.id, imageEmoji: f.image_emoji, imageUrl: f.image_url, videoUrl: f.video_url || null, mediaType: f.media_type || 'image',
      badge: f.badge, caption: f.caption, likes: f.likes, comments: f.comments,
      provider: { id: f.provider_id, name: p?.name, category: p?.category, emoji: p?.emoji, rating: p?.rating, area: p?.area, avatarUrl: p?.avatar_url, imageUrl: p?.image_url },
    };
  }),
  feedComments: (data.feed_comments || []).map(c => ({
    id: c.id, postId: c.feed_post_id, authorName: c.author_name, text: c.text, createdAt: c.created_at,
  })),
  notifications: data.notifications.filter(n => n.user_id === userId).map(r => ({
    id: r.id, title: r.title, body: r.body, emoji: r.emoji, read: !!r.read, createdAt: r.created_at,
  })),
  walletTransactions: (data.wallet_transactions || []).filter(t => t.user_id === userId).map(t => ({
    id: t.id, type: t.type, amount: t.amount, description: t.description, reference: t.reference, createdAt: t.created_at,
  })),
  savedProviderIds: user.saved_provider_ids || [],
  reviews: (data.reviews || []).map(r => {
    const p = data.providers.find(x => x.id === r.provider_id);
    return {
      id: r.id, providerId: r.provider_id, providerName: p?.name, rating: r.rating,
      comment: r.comment, authorName: r.author_name, createdAt: r.created_at,
    };
  }),
};

const dest = path.join(__dirname, '..', '..', 'khade_app', 'assets', 'data', 'bootstrap.json');
fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.writeFileSync(dest, JSON.stringify(out));
console.log(`Exported ${out.providers.length} providers → ${dest}`);
