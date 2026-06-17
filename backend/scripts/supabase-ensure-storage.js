/**
 * Create Supabase Storage buckets for Khade (idempotent).
 * Usage: npm run supabase:storage
 */
const { loadEnv } = require('./supabase-env');
loadEnv();

const { getClient, isConfigured } = require('../src/supabase-client');

const BUCKETS = [
  { id: 'provider-photos', public: true },
  { id: 'portfolio-videos', public: true },
  { id: 'provider-docs', public: false },
  { id: 'post-images', public: true },
];

async function main() {
  console.log('=== Khade Storage buckets ===\n');

  if (!isConfigured()) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  const client = getClient();
  const { data: existing, error: listErr } = await client.storage.listBuckets();
  if (listErr) {
    console.error('listBuckets:', listErr.message);
    process.exit(1);
  }

  const names = new Set((existing || []).map((b) => b.name));

  for (const bucket of BUCKETS) {
    if (names.has(bucket.id)) {
      console.log(`  ✓ ${bucket.id} (exists)`);
      continue;
    }
    const { error } = await client.storage.createBucket(bucket.id, {
      public: bucket.public,
      fileSizeLimit: bucket.id === 'portfolio-videos' ? 104857600 : 10485760,
    });
    if (error) {
      console.log(`  ✗ ${bucket.id}: ${error.message}`);
    } else {
      console.log(`  + ${bucket.id} created (public=${bucket.public})`);
    }
  }

  console.log('\nDone.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
