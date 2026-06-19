const { isConfigured } = require('./supabase-client');

const backend = isConfigured() ? require('./database-supabase') : require('./database-json');

const loadAuth = backend.loadAuth || backend.load;
const loadLogin = backend.loadLogin || backend.loadAuth || backend.load;

module.exports = {
  ...backend,
  loadAuth,
  loadLogin,
  isSupabase: backend.mode === 'supabase',
  dbPath: backend.dbPath,
};
