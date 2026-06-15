const { createClient } = require('@supabase/supabase-js');

let client;

function isConfigured() {
  return !!(process.env.SUPABASE_URL && (process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY));
}

function getClient() {
  if (!isConfigured()) {
    throw new Error('Supabase not configured — set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env');
  }
  if (!client) {
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
    if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
      console.warn('Warning: using SUPABASE_ANON_KEY — add SUPABASE_SERVICE_ROLE_KEY for production');
    }
    client = createClient(process.env.SUPABASE_URL, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}

function usingServiceRole() {
  return !!process.env.SUPABASE_SERVICE_ROLE_KEY;
}

module.exports = { getClient, isConfigured, usingServiceRole };
