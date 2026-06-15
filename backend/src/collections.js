/** Shared in-memory / JSON collection defaults for Phase 2 tables */
function ensureCollections(data) {
  data.messages = data.messages || [];
  data.provider_locations = data.provider_locations || [];
  data.booking_groups = data.booking_groups || [];
  data.client_profiles = data.client_profiles || [];
  data.staff = data.staff || [];
  data.inventory = data.inventory || [];
  data.campaigns = data.campaigns || [];
  data.capital_loans = data.capital_loans || [];
  data.fcm_tokens = data.fcm_tokens || [];
  data.pending_payments = data.pending_payments || [];
  return data;
}

module.exports = { ensureCollections };
