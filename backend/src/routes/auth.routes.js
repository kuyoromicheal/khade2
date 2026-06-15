const express = require('express');
const { load, save, nextId } = require('../database');
const { hashPassword, verifyPassword, signToken, mapAuthUser } = require('../auth');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const DEFAULT_SLOTS = {
  mon: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
  tue: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
  wed: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
  thu: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
  fri: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
  sat: ['10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
  sun: [],
  blocked_dates: [],
};

async function ensureDemoAccounts(data) {
  const demos = [
    { email: 'customer@khade.ng', password: 'password123', name: 'Adaeze Chukwu', role: 'customer', city: 'Abuja', tier: 'Gold', wallet: 85000, bookings: 12 },
    { email: 'provider@khade.ng', password: 'password123', name: 'Zara Okonkwo', role: 'provider', city: 'Abuja', providerLink: true },
    { email: 'admin@khade.ng', password: 'password123', name: 'Khade Admin', role: 'admin', city: 'Abuja' },
  ];

  for (const demo of demos) {
    const existing = data.users.find((u) => u.email === demo.email);
    if (existing) {
      if (!existing.password_hash) {
        existing.password_hash = await hashPassword(demo.password);
        existing.role = demo.role;
      }
      if (demo.role === 'provider' && demo.providerLink && !existing.provider_id) {
        const provider = data.providers.find((p) => p.status === 'active');
        if (provider) {
          existing.provider_id = provider.id;
          provider.owner_user_id = existing.id;
        }
      }
      continue;
    }

    const id = await nextId(data, 'users');
    let providerId = null;
    if (demo.role === 'provider') {
      const provider = data.providers.find((p) => p.status === 'active');
      providerId = provider?.id || null;
      if (provider) provider.owner_user_id = id;
    }

    data.users.push({
      id,
      name: demo.name,
      email: demo.email,
      phone: '+2348000000000',
      city: demo.city,
      tier: demo.tier || 'Standard',
      role: demo.role,
      password_hash: await hashPassword(demo.password),
      provider_id: providerId,
      wallet_balance: demo.wallet || 0,
      bookings_count: demo.bookings || 0,
      saved_providers: 0,
      saved_provider_ids: [],
      member_since: 2024,
      gold_subscriber: 0,
      created_at: new Date().toISOString(),
    });
  }
}

router.post('/register', async (req, res) => {
  const {
    email, password, name, role = 'customer', city = 'Abuja', phone,
    businessName, cacNumber, visitTypes = 'both', area = 'Wuse II',
  } = req.body;
  if (!email || !password || !name) {
    return res.status(400).json({ error: 'email, password, and name are required' });
  }
  if (!['customer', 'provider'].includes(role)) {
    return res.status(400).json({ error: 'role must be customer or provider' });
  }
  if (role === 'provider' && !cacNumber) {
    return res.status(400).json({ error: 'CAC registration number is required for providers' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  const data = await load();
  await ensureDemoAccounts(data);

  if (data.users.some((u) => u.email?.toLowerCase() === email.toLowerCase())) {
    return res.status(409).json({ error: 'Email already registered' });
  }

  const welcomeBonus = role === 'customer' ? 2000 : 0;
  const id = await nextId(data, 'users');
  const user = {
    id,
    name,
    email: email.toLowerCase(),
    phone: phone || null,
    city,
    tier: 'Bronze',
    role,
    password_hash: await hashPassword(password),
    provider_id: null,
    wallet_balance: welcomeBonus,
    bookings_count: 0,
    saved_providers: 0,
    saved_provider_ids: [],
    member_since: new Date().getFullYear(),
    gold_subscriber: 0,
    created_at: new Date().toISOString(),
  };

  if (role === 'provider') {
    const providerId = await nextId(data, 'providers');
    user.provider_id = providerId;
    data.providers.push({
      id: providerId,
      status: 'under_review',
      name: businessName || `${name.split(' ')[0]} Studio`,
      business_name: businessName || null,
      cac_number: cacNumber || null,
      category: 'Beauty',
      category_slug: 'makeup',
      emoji: '💄',
      rating: 0,
      review_count: 0,
      distance_km: 2,
      latitude: 9.0765,
      longitude: 7.4898,
      area,
      price_from: 5000,
      badge: null,
      verified: 0,
      featured: 0,
      provider_tier: 'Bronze',
      gradient_start: '#e8f0ea',
      gradient_end: '#d4e6d8',
      image_url: null,
      avatar_url: null,
      phone: phone || null,
      owner_user_id: id,
      bio: '',
      visit_types: visitTypes,
      availability: DEFAULT_SLOTS,
      earnings_balance: 0,
      featured_until: null,
      boost_until: null,
      verified_paid: 0,
    });
  }

  data.users.push(user);

  if (welcomeBonus > 0) {
    data.wallet_transactions = data.wallet_transactions || [];
    data.wallet_transactions.push({
      id: await nextId(data, 'wallet_transactions'),
      user_id: id,
      type: 'credit',
      amount: welcomeBonus,
      description: 'Welcome bonus — ₦2,000 is on us!',
      reference: `WELCOME_${id}`,
      created_at: new Date().toISOString(),
    });
    data.notifications = data.notifications || [];
    data.notifications.unshift({
      id: await nextId(data, 'notifications'),
      user_id: id,
      title: 'Welcome to Khade ✦',
      body: '₦2,000 has been added to your wallet. Book your first service today!',
      emoji: '🎁',
      read: 0,
      created_at: new Date().toISOString(),
    });
  }

  await save(data);

  const token = signToken(user);
  res.status(201).json({
    data: {
      token,
      user: mapAuthUser(user),
      welcomeBonus: welcomeBonus > 0 ? welcomeBonus : null,
    },
  });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }

  const data = await load();
  await ensureDemoAccounts(data);
  await save(data);

  const user = data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
  if (!user || !(await verifyPassword(password, user.password_hash))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const token = signToken(user);
  res.json({ data: { token, user: mapAuthUser(user) } });
});

router.get('/me', requireAuth, async (req, res) => {
  res.json({ data: mapAuthUser(req.user) });
});

router.post('/guest', async (_req, res) => {
  const data = await load();
  await ensureDemoAccounts(data);
  await save(data);
  const guest = data.users.find((u) => u.id === 1) || data.users[0];
  if (!guest) return res.status(404).json({ error: 'No guest user' });
  res.json({ data: { user: mapAuthUser(guest), guest: true } });
});

module.exports = { router, ensureDemoAccounts, DEFAULT_SLOTS };
