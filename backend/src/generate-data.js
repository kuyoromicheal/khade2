/**
 * Regenerates khade.json with 100 providers, categories, feed posts, services.
 * Run: node src/generate-data.js
 */
const fs = require('fs');
const path = require('path');
const { dbPath } = require('./database');

const CATEGORIES = [
  { slug: 'all', label: 'All', emoji: '💆', filter: null },
  { slug: 'barbing', label: 'Barbing', emoji: '✂️', filter: 'barb' },
  { slug: 'nails', label: 'Nails', emoji: '💅', filter: 'nail' },
  { slug: 'makeup', label: 'Makeup', emoji: '💄', filter: 'makeup' },
  { slug: 'spa', label: 'Spa', emoji: '🧖', filter: 'spa' },
  { slug: 'hair', label: 'Hair', emoji: '💇', filter: 'hair' },
  { slug: 'skincare', label: 'Skincare', emoji: '🧴', filter: 'skin' },
  { slug: 'braids', label: 'Braids', emoji: '🪡', filter: 'braid' },
  { slug: 'lashes', label: 'Lashes', emoji: '👁️', filter: 'lash' },
  { slug: 'wellness', label: 'Wellness', emoji: '💆', filter: 'wellness' },
];

const AREAS = ['Wuse II', 'Maitama', 'Garki', 'Gwarinpa', 'Asokoro', 'Utako', 'Lugbe', 'Wuse', 'Kubwa', 'Nyanya', 'Jabi', 'Guzape'];
const AREA_COORDS = {
  'Wuse II': [9.0765, 7.4958],
  Maitama: [9.0833, 7.495],
  Garki: [9.0439, 7.4824],
  Gwarinpa: [9.1122, 7.4056],
  Asokoro: [9.045, 7.53],
  Utako: [9.065, 7.42],
  Lugbe: [8.996, 7.365],
  Wuse: [9.068, 7.489],
  Kubwa: [9.164, 7.325],
  Nyanya: [8.998, 7.595],
  Jabi: [9.078, 7.425],
  Guzape: [9.018, 7.518],
};
const REVIEW_AUTHORS = ['Adaeze C.', 'Ngozi W.', 'Tunde A.', 'Chioma B.', 'Fatima K.', 'Emeka O.', 'Amina S.', 'Blessing E.', 'Kemi T.', 'David M.'];
const REVIEW_SNIPPETS = [
  'Absolutely stunning work! Will book again.',
  'Professional and on time. Highly recommend!',
  'Clean studio, great vibe. Loved the result.',
  'Best in Abuja — worth every naira.',
  'So gentle and skilled. Five stars!',
  'My go-to every weekend. Never disappoints.',
  'Punctual, polite, and talented.',
  'The transformation was incredible ✨',
  'Fair price for amazing quality.',
  'Already recommended to all my friends.',
];
const GRADIENTS = [
  ['#e8f0ea', '#d4e6d8'], ['#f0e8f0', '#dcc8dc'], ['#f5f0e8', '#e8d8c8'],
  ['#e8f5e8', '#c8e8c8'], ['#e8f0f5', '#c8d8e8'], ['#fdf5e8', '#f5e0c8'],
  ['#f5f0f5', '#e8d8e8'], ['#e8f0ea', '#c8dece'],
];

const PREFIXES = {
  barbing: ['King', 'Fresh', 'Elite', 'Sharp', 'Classic', 'Urban', 'Prime', 'Gentle', 'Royal', 'Metro'],
  nails: ['Glam', 'Chic', 'Polish', 'Luxe', 'Sparkle', 'Velvet', 'Pearl', 'Rose', 'Crystal', 'Bloom'],
  makeup: ['Zara', 'Glam', 'Glow', 'Diva', 'Bella', 'Radiant', 'Posh', 'Elite', 'Star', 'Aura'],
  spa: ['Tranquil', 'Serenity', 'Bliss', 'Zen', 'Harmony', 'Calm', 'Pure', 'Revive', 'Oasis', 'Luna'],
  hair: ['Ebun', 'Crown', 'Silk', 'Curl', 'Wave', 'Tress', 'Mane', 'Luxe', 'Bloom', 'Sheen'],
  skincare: ['Glow', 'Pure', 'Dew', 'Fresh', 'Radiant', 'Velvet', 'Clear', 'Lumi', 'Skin', 'Bloom'],
  braids: ['Braids', 'Twist', 'Cornrow', 'Locs', 'Plait', 'Silk', 'Crown', 'Heritage', 'Art', 'Style'],
  lashes: ['Lash', 'Flutter', 'Blink', 'Glam', 'Wink', 'Luxe', 'Doll', 'Star', 'Velvet', 'Glow'],
  wellness: ['Bliss', 'Vitality', 'Balance', 'Harmony', 'Renew', 'Thrive', 'Nourish', 'Calm', 'Zen', 'Flow'],
};

const SUFFIXES = {
  barbing: ['Cuts', 'Barber Shop', 'Grooming', 'Studio', 'Lounge', 'Cuts & Styles'],
  nails: ['Nails', 'Nail Studio', 'Nail Bar', 'Nails & Spa', 'Nail Lounge'],
  makeup: ['Beauty', 'Beauty Studio', 'Glam', 'Makeup Artistry', 'Beauty Lounge'],
  spa: ['Spa', 'Wellness Spa', 'Day Spa', 'Retreat', 'Spa Lounge'],
  hair: ['Hair Lounge', 'Hair Studio', 'Salon', 'Hair Bar', 'Hair Co'],
  skincare: ['Skincare', 'Skin Studio', 'Derma Lounge', 'Skin Bar', 'Skin Lab'],
  braids: ['by Chi', 'Studio', 'Braiding', 'Hair Art', 'Styles'],
  lashes: ['Lashes', 'Lash Bar', 'Lash Studio', 'Lash Lounge', 'Lash Co'],
  wellness: ['Wellness', 'Holistic', 'Body Studio', 'Therapy', 'Centre'],
};

const SERVICE_TEMPLATES = {
  barbing: [
    { name: 'Classic Haircut', duration: '30 mins', price: 3500 },
    { name: 'Skin Fade', duration: '45 mins', price: 5000 },
    { name: 'Beard Trim & Shape', duration: '20 mins', price: 2500 },
  ],
  nails: [
    { name: 'Gel Manicure', duration: '60 mins', price: 7000 },
    { name: 'Acrylic Full Set', duration: '90 mins', price: 12000 },
    { name: 'Pedicure Deluxe', duration: '75 mins', price: 9000 },
  ],
  makeup: [
    { name: 'Full Glam Makeup', duration: '90 mins', price: 12000 },
    { name: 'Natural Look', duration: '60 mins', price: 8000 },
    { name: 'Bridal Package', duration: '3 hrs', price: 25000 },
  ],
  spa: [
    { name: 'Swedish Massage', duration: '60 mins', price: 15000 },
    { name: 'Deep Tissue', duration: '90 mins', price: 22000 },
    { name: 'Body Scrub', duration: '45 mins', price: 12000 },
  ],
  hair: [
    { name: 'Wash & Blow Dry', duration: '45 mins', price: 5000 },
    { name: 'Silk Press', duration: '90 mins', price: 8000 },
    { name: 'Hair Treatment', duration: '60 mins', price: 6500 },
  ],
  skincare: [
    { name: 'Facial Glow', duration: '60 mins', price: 10000 },
    { name: 'Acne Treatment', duration: '75 mins', price: 14000 },
    { name: 'Microdermabrasion', duration: '45 mins', price: 12000 },
  ],
  braids: [
    { name: 'Box Braids', duration: '4 hrs', price: 18000 },
    { name: 'Cornrows', duration: '2 hrs', price: 10000 },
    { name: 'Twists', duration: '3 hrs', price: 14000 },
  ],
  lashes: [
    { name: 'Classic Lash Set', duration: '90 mins', price: 8000 },
    { name: 'Volume Lashes', duration: '2 hrs', price: 12000 },
    { name: 'Lash Lift', duration: '60 mins', price: 6000 },
  ],
  wellness: [
    { name: 'Aromatherapy Session', duration: '60 mins', price: 18000 },
    { name: 'Reflexology', duration: '45 mins', price: 12000 },
    { name: 'Yoga & Stretch', duration: '60 mins', price: 8000 },
  ],
};

const CAPTIONS = [
  'Serving looks today ✨ Book your slot!',
  'Client glow-up 🔥 Who\'s next?',
  'Weekend vibes only 💅',
  'Before & after magic ✦',
  'Abuja\'s finest at work 🇳🇬',
  'Slots filling fast — DM to book!',
  'Fresh from the chair 💫',
  'This transformation though 😍',
  'Your beauty era starts here ✨',
  'Another happy client 🎉',
];

const COMMENT_LINES = [
  'So good! 🔥', 'Booked immediately 💅', 'Need this look!', 'Abuja girls know ✨', 'How much?',
  'Which area are you in?', 'Love this! 😍', 'Saving for later', 'Is Saturday open?', 'Perfect work!',
  'My third booking here', 'Highly recommend', 'So talented!', 'Worth every naira', 'On my way to book',
];

const { categoryImage, providerImage, providerAvatar, feedMedia, feedImageForProvider, createVideoAllocator, countUniqueVideos } = require('./media-urls');

function pick(arr, i) {
  return arr[i % arr.length];
}

const data = {
  categories: CATEGORIES.map((c, i) => ({
    id: i + 1,
    slug: c.slug,
    label: c.label,
    emoji: c.emoji,
    filter: c.filter,
    image_url: categoryImage(c.slug),
  })),
  users: [],
  providers: [],
  services: [],
  bookings: [],
  feed_posts: [],
  feed_comments: [],
  notifications: [],
  wallet_transactions: [],
  reviews: [],
  _counters: { users: 0, providers: 0, services: 0, bookings: 0, feed_posts: 0, feed_comments: 0, notifications: 0, wallet_transactions: 0, reviews: 0 },
};

let uid = 0;
const next = (table) => { data._counters[table] = (data._counters[table] || 0) + 1; return data._counters[table]; };

data.users.push({
  id: next('users'),
  name: 'Adaeze Chukwu',
  email: 'adaeze@example.com',
  phone: '+2348012345678',
  city: 'Abuja',
  tier: 'Gold',
  wallet_balance: 85000,
  bookings_count: 12,
  saved_providers: 7,
  saved_provider_ids: [],
  member_since: 2024,
  created_at: new Date().toISOString(),
});
const userId = data.users[0].id;

const catKeys = Object.keys(PREFIXES);
let providerId = 0;

for (let i = 0; i < 100; i++) {
  const catKey = catKeys[i % catKeys.length];
  const catLabel = CATEGORIES.find(c => c.slug === catKey)?.label || 'Beauty';
  const prefix = pick(PREFIXES[catKey], i);
  const suffix = pick(SUFFIXES[catKey], Math.floor(i / 10));
  const name = `${prefix} ${suffix}${i > 9 ? ` ${i}` : ''}`.trim();
  const [gs, ge] = pick(GRADIENTS, i);
  const id = next('providers');
  providerId = id;

  const area = pick(AREAS, i);
  const [baseLat, baseLng] = AREA_COORDS[area] || [9.0765, 7.4898];
  const lat = +(baseLat + ((i % 7) - 3) * 0.004).toFixed(6);
  const lng = +(baseLng + ((i % 5) - 2) * 0.004).toFixed(6);

  data.providers.push({
    id,
    status: 'active',
    name,
    category: catLabel,
    category_slug: catKey,
    emoji: CATEGORIES.find(c => c.slug === catKey)?.emoji || '✨',
    rating: +(4.3 + (i % 7) * 0.1).toFixed(1),
    review_count: 0,
    distance_km: +((0.4 + (i % 12) * 0.3).toFixed(1)),
    latitude: lat,
    longitude: lng,
    area,
    price_from: SERVICE_TEMPLATES[catKey][0].price,
    badge: i % 5 === 0 ? '✦ Premium' : i % 3 === 0 ? '🔥 Popular' : i % 7 === 0 ? 'Featured' : null,
    verified: i % 4 !== 0 ? 1 : 0,
    featured: i < 20 ? 1 : 0,
    gradient_start: gs,
    gradient_end: ge,
    image_url: providerImage(catKey, i),
    avatar_url: providerAvatar(catKey, i),
  });

  SERVICE_TEMPLATES[catKey].forEach((s, si) => {
    data.services.push({
      id: next('services'),
      provider_id: id,
      name: s.name,
      duration: s.duration,
      price: s.price + (si * 500),
    });
  });

}

function seedCommentsForPost(postId, count, userId) {
  for (let c = 0; c < count; c++) {
    data.feed_comments.push({
      id: next('feed_comments'),
      feed_post_id: postId,
      user_id: userId,
      author_name: pick(REVIEW_AUTHORS, postId + c),
      text: pick(COMMENT_LINES, postId + c),
      created_at: new Date(Date.now() - c * 4200000).toISOString(),
    });
  }
}

function addFeedPost(provider, mediaType, caption, badge, commentCount, userId, videoUrl = null) {
  const catKey = provider.category_slug;
  const media = feedMedia(catKey, provider.id, mediaType, provider.image_url, videoUrl);
  const postId = next('feed_posts');
  data.feed_posts.push({
    id: postId,
    created_at: new Date(Date.now() - postId * 3600000).toISOString(),
    provider_id: provider.id,
    image_emoji: provider.emoji,
    image_url: media.image_url,
    video_url: media.video_url,
    media_type: media.media_type,
    badge,
    caption,
    likes: 80 + (postId * 31) % 600,
    comments: commentCount,
    liked_by: [],
  });
  seedCommentsForPost(postId, commentCount, userId);
}

// Feed: one unique video reel per provider (no repeats; capped by catalog size)
const takeVideo = createVideoAllocator();
const maxPosts = Math.min(data.providers.length * 2, countUniqueVideos());

for (let i = 0; i < data.providers.length && i * 2 < maxPosts; i++) {
  const p = data.providers[i];
  for (let slot = 0; slot < 2; slot++) {
    if (i * 2 + slot >= maxPosts) break;
    const videoUrl = takeVideo(p.category_slug);
    if (!videoUrl) break;
    addFeedPost(
      p,
      'video',
      `${slot === 0 ? 'Behind the chair' : 'Client glow up'} at ${p.name} — ${p.category} in ${p.area} 🎬 #${p.name.replace(/\s/g, '')}`,
      `${p.category} Reel`,
      3 + ((p.id + slot) % 12),
      userId,
      videoUrl,
    );
  }
}
console.log(`Feed videos: ${data.feed_posts.length} unique (catalog has ${countUniqueVideos()})`);

// Sample bookings
const p1 = data.providers[0].id;
const s1 = data.services.find(s => s.provider_id === p1).id;
[
  { provider_id: p1, service_id: s1, status: 'upcoming', location_type: 'home', address: 'Plot 5, Abubakar Tafawa Balewa Way, Maitama, Abuja', scheduled_at: '2025-06-17T10:30:00', total_amount: 13200, booking_code: 'KHD-2847' },
  { provider_id: data.providers[4].id, service_id: data.services.find(s => s.provider_id === data.providers[4].id).id, status: 'upcoming', location_type: 'salon', address: 'Salon visit', scheduled_at: '2025-06-20T14:00:00', total_amount: 9500, booking_code: 'KHD-2851' },
  { provider_id: data.providers[3].id, service_id: data.services.find(s => s.provider_id === data.providers[3].id).id, status: 'completed', location_type: 'salon', address: 'Gwarinpa', scheduled_at: '2025-06-07T09:00:00', total_amount: 5500, booking_code: 'KHD-2801', payment_method: 'paystack' },
].forEach(b => {
  data.bookings.push({ id: next('bookings'), created_at: new Date().toISOString(), user_id: userId, ...b });
});

[
  { user_id: userId, title: 'Booking Confirmed!', body: 'Your appointment is set for Tue Jun 17 at 10:30 AM', emoji: '✦' },
  { user_id: userId, title: 'Wallet topped up', body: '₦50,000 added to your Khade Wallet', emoji: '👛' },
  { user_id: userId, title: 'You unlocked Gold tier!', body: 'Priority booking & 5% cashback', emoji: '🎉' },
].forEach(n => {
  data.notifications.push({ id: next('notifications'), read: 0, created_at: new Date().toISOString(), ...n });
});

[
  { user_id: userId, type: 'credit', amount: 50000, description: 'Wallet top-up via Paystack', reference: 'KHADE_TOPUP_001' },
  { user_id: userId, type: 'debit', amount: 13200, description: 'Booking KHD-2801', reference: 'KHD-2801' },
].forEach(t => {
  data.wallet_transactions.push({ id: next('wallet_transactions'), created_at: new Date().toISOString(), ...t });
});

data.users[0].saved_provider_ids = data.providers.slice(0, 7).map(p => p.id);

for (let i = 0; i < 80; i++) {
  const provider = data.providers[i];
  const count = 2 + (i % 2);
  for (let r = 0; r < count; r++) {
    data.reviews.push({
      id: next('reviews'),
      user_id: userId,
      provider_id: provider.id,
      rating: 4 + (r % 2),
      comment: pick(REVIEW_SNIPPETS, i + r),
      author_name: pick(REVIEW_AUTHORS, i + r),
      created_at: new Date(Date.now() - (i * 86400000) - r * 3600000).toISOString(),
    });
  }
}

data.providers.forEach((p) => {
  const provReviews = data.reviews.filter((r) => r.provider_id === p.id);
  if (provReviews.length) {
    p.review_count = provReviews.length;
    p.rating = +(provReviews.reduce((s, r) => s + r.rating, 0) / provReviews.length).toFixed(1);
  } else {
    p.review_count = 0;
  }
});

fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
console.log(`Generated: ${data.providers.length} providers, ${data.services.length} services, ${data.feed_posts.length} feed posts, ${data.reviews.length} reviews`);
console.log(`Saved to ${dbPath}`);
