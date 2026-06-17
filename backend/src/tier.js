/** Customer tier perks — Bronze / Silver / Gold only */

const TIER_ORDER = ['bronze', 'silver', 'gold'];

function normalizeTier(tier) {
  const t = (tier || 'bronze').toLowerCase();
  if (t === 'platinum') return 'gold';
  return TIER_ORDER.includes(t) ? t : 'bronze';
}

function tierFromBookings(totalBookings) {
  if (totalBookings >= 10) return 'gold';
  if (totalBookings >= 5) return 'silver';
  return 'bronze';
}

function cashbackRate(tier) {
  switch (normalizeTier(tier)) {
    case 'gold': return 0.05;
    case 'silver': return 0.03;
    default: return 0;
  }
}

function tierLabel(tier) {
  const t = normalizeTier(tier);
  return t.charAt(0).toUpperCase() + t.slice(1);
}

function applyTierUpgrade(user, data) {
  const completed = (data.bookings || []).filter(
    (b) => b.user_id === user.id && b.status === 'completed',
  ).length;
  const newTier = tierFromBookings(completed);
  const oldTier = normalizeTier(user.tier);
  user.bookings_count = completed;
  const label = tierLabel(newTier);
  if (newTier !== oldTier) {
    user.tier = label;
    return { upgraded: true, oldTier, newTier: label };
  }
  user.tier = label;
  return { upgraded: false, tier: user.tier };
}

module.exports = {
  TIER_ORDER,
  normalizeTier,
  tierFromBookings,
  cashbackRate,
  tierLabel,
  applyTierUpgrade,
};
