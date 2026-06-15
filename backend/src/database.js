const { isConfigured } = require('./supabase-client');

const backend = isConfigured() ? require('./database-supabase') : require('./database-json');

module.exports = {
  ...backend,
  isSupabase: backend.mode === 'supabase',
  dbPath: backend.dbPath,
};
