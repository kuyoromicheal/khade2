const { verifyToken } = require('../auth');
const { load } = require('../database');

function getBearerToken(req) {
  const header = req.headers.authorization || '';
  if (header.startsWith('Bearer ')) return header.slice(7);
  return null;
}

async function optionalAuth(req, _res, next) {
  const token = getBearerToken(req);
  req.userId = Number(req.query.userId || req.body?.userId || 1);
  req.userRole = 'guest';
  req.providerId = null;

  if (!token) return next();

  try {
    const payload = verifyToken(token);
    const data = await load();
    const user = data.users.find((u) => u.id === payload.id);
    if (user) {
      req.user = user;
      req.userId = user.id;
      req.userRole = user.role || payload.role || 'customer';
      req.providerId = user.provider_id || payload.providerId || null;
    }
  } catch (_) {
    /* invalid token — fall back to guest */
  }
  return next();
}

function requireAuth(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  return next();
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'Authentication required' });
    if (!roles.includes(req.userRole)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    return next();
  };
}

module.exports = { optionalAuth, requireAuth, requireRole, getBearerToken };
