const { load, save, nextId } = require('./database');

const data = load();
if (data.providers.length > 0) {
  console.log('Database already seeded.');
  process.exit(0);
}

const userId = nextId(data, 'users');
data.users.push({
  id: userId,
  name: 'Adaeze Chukwu',
  email: 'adaeze@example.com',
  phone: '+2348012345678',
  city: 'Abuja',
  tier: 'Gold',
  wallet_balance: 5400,
  bookings_count: 12,
  saved_providers: 7,
  member_since: 2024,
  created_at: new Date().toISOString(),
});

const providers = [
  { name: 'Zara Beauty Studio', category: 'Makeup & Glam', emoji: '💄', rating: 4.9, review_count: 128, distance_km: 1.4, area: 'Wuse II', price_from: 12000, badge: '✦ Premium', verified: 1, featured: 1, gradient_start: '#e8f0ea', gradient_end: '#d4e6d8' },
  { name: 'Chic Nails by Amaka', category: 'Nails & Pedicure', emoji: '💅', rating: 4.7, review_count: 203, distance_km: 0.9, area: 'Maitama', price_from: 7000, badge: '🔥 Popular', verified: 1, featured: 1, gradient_start: '#e8f5e8', gradient_end: '#c8e8c8' },
  { name: 'Tranquil Wellness Spa', category: 'Spa & Massage', emoji: '🧖', rating: 4.8, review_count: 94, distance_km: 3.2, area: 'Garki', price_from: 18000, badge: '✦ Verified', verified: 1, featured: 1, gradient_start: '#f0e8f0', gradient_end: '#dcc8dc' },
  { name: 'King Cuts Barber', category: 'Barbing', emoji: '✂️', rating: 4.9, review_count: 176, distance_km: 0.5, area: 'Gwarinpa', price_from: 3500, badge: '✦ Verified', verified: 1, featured: 1, gradient_start: '#f5f0e8', gradient_end: '#e8d8c8' },
  { name: 'Glam Nails Studio', category: 'Nails', emoji: '💅', rating: 4.9, review_count: 87, distance_km: 0.8, area: 'Maitama', price_from: 8500, badge: 'Featured', verified: 1, featured: 1, gradient_start: '#e8f0ea', gradient_end: '#c8dece' },
  { name: 'Ebun Hair Lounge', category: 'Hair', emoji: '💇', rating: 4.8, review_count: 112, distance_km: 1.2, area: 'Wuse', price_from: 5000, badge: 'Featured', verified: 1, featured: 0, gradient_start: '#f0e8f0', gradient_end: '#dcc8dc' },
  { name: 'Serenity Spa', category: 'Spa', emoji: '🧖', rating: 4.7, review_count: 65, distance_km: 2.1, area: 'Asokoro', price_from: 15000, badge: 'Featured', verified: 1, featured: 0, gradient_start: '#e8f0f5', gradient_end: '#c8d8e8' },
  { name: 'Skin by Tola', category: 'Skincare', emoji: '🧴', rating: 4.6, review_count: 54, distance_km: 2.4, area: 'Garki', price_from: 10000, badge: null, verified: 0, featured: 0, gradient_start: '#f5f0f5', gradient_end: '#e8d8e8' },
  { name: 'Braids by Chi', category: 'Braids', emoji: '🪡', rating: 4.7, review_count: 98, distance_km: 1.8, area: 'Utako', price_from: 12000, badge: null, verified: 0, featured: 0, gradient_start: '#fdf5e8', gradient_end: '#f5e0c8' },
  { name: 'Bliss Wellness', category: 'Wellness', emoji: '💆', rating: 4.5, review_count: 41, distance_km: 4.1, area: 'Lugbe', price_from: 22000, badge: null, verified: 0, featured: 0, gradient_start: '#e8f0ea', gradient_end: '#c8d8cc' },
];

const providerIds = providers.map(p => {
  const id = nextId(data, 'providers');
  data.providers.push({ id, status: 'active', ...p });
  return id;
});

const zaraId = providerIds[0];
[
  { name: 'Full Glam Makeup', duration: '90 mins', price: 12000 },
  { name: 'Natural / Everyday Look', duration: '60 mins', price: 8000 },
  { name: 'Bridal Package', duration: '3 hrs', price: 25000 },
  { name: 'Eyebrow Shaping', duration: '20 mins', price: 5000 },
].forEach(s => {
  data.services.push({ id: nextId(data, 'services'), provider_id: zaraId, ...s });
});

const serviceId = data.services[0].id;

[
  { user_id: userId, provider_id: zaraId, service_id: serviceId, status: 'upcoming', location_type: 'home', address: 'Plot 5, Abubakar Tafawa Balewa Way, Maitama, Abuja', scheduled_at: '2025-06-17T10:30:00', total_amount: 13200, booking_code: 'KHD-2847' },
  { user_id: userId, provider_id: providerIds[4], service_id: serviceId, status: 'upcoming', location_type: 'salon', address: 'Glam Nails Studio, Maitama', scheduled_at: '2025-06-20T14:00:00', total_amount: 9500, booking_code: 'KHD-2851' },
  { user_id: userId, provider_id: providerIds[3], service_id: serviceId, status: 'completed', location_type: 'salon', address: 'King Cuts, Gwarinpa', scheduled_at: '2025-06-07T09:00:00', total_amount: 4500, booking_code: 'KHD-2801' },
].forEach(b => {
  data.bookings.push({ id: nextId(data, 'bookings'), created_at: new Date().toISOString(), ...b });
});

[
  { provider_id: zaraId, image_emoji: '💫', badge: 'Bridal Glam ✦', caption: '✨ Bridal glow served! Soft glam with a dewy finish for the big day. Slots filling fast 💍', likes: 234, comments: 18 },
  { provider_id: providerIds[1], image_emoji: '💅', badge: 'Nail Art ✦', caption: '🌸 Cherry blossom gel set for the weekend! Long-lasting, chip-resistant.', likes: 89, comments: 7 },
  { provider_id: providerIds[3], image_emoji: '✂️', badge: 'Fresh Cut ✦', caption: '🔥 Skin fade + Edgar combo straight from our chair. Book Saturday slots now!', likes: 156, comments: 23 },
].forEach(p => {
  data.feed_posts.push({ id: nextId(data, 'feed_posts'), created_at: new Date().toISOString(), ...p });
});

[
  { user_id: userId, title: 'Booking Confirmed!', body: 'Your appointment with Zara Beauty Studio is set for Tue Jun 17 at 10:30 AM', emoji: '✦' },
  { user_id: userId, title: 'Chic Nails liked your review', body: 'Thank you for your 5-star review!', emoji: '💅' },
  { user_id: userId, title: 'You unlocked Gold tier!', body: 'You now enjoy priority booking & 5% cashback', emoji: '🎉' },
].forEach(n => {
  data.notifications.push({ id: nextId(data, 'notifications'), read: 0, created_at: new Date().toISOString(), ...n });
});

save(data);
console.log('Database seeded successfully.');
