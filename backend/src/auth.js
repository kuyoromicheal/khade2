const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const SECRET = process.env.JWT_SECRET || 'khade-dev-secret-change-in-production';

async function hashPassword(password) {
  return bcrypt.hash(password, 10);
}

async function verifyPassword(password, hash) {
  if (!hash) return false;
  return bcrypt.compare(password, hash);
}

function signToken(user) {
  return jwt.sign(
    {
      id: user.id,
      role: user.role || 'customer',
      providerId: user.provider_id || null,
      email: user.email,
    },
    SECRET,
    { expiresIn: '30d' },
  );
}

function verifyToken(token) {
  return jwt.verify(token, SECRET);
}

function mapAuthUser(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone,
    city: row.city,
    tier: row.tier,
    role: row.role || 'customer',
    providerId: row.provider_id || null,
    walletBalance: row.wallet_balance,
    bookingsCount: row.bookings_count,
    savedProviders: row.saved_providers,
    memberSince: row.member_since,
  };
}

module.exports = { hashPassword, verifyPassword, signToken, verifyToken, mapAuthUser, SECRET };
