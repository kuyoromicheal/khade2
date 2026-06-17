/**
 * Import real providers from data/providers-real.json into khade.json.
 *
 * 1. Copy providers-real.example.json → providers-real.json
 * 2. Edit with your real salons (5–10 entries)
 * 3. Run: node scripts/import-real-providers.js
 * 4. Restart backend + hot restart Flutter app
 */
const fs = require('fs');
const path = require('path');
const { load, save } = require('../src/database');
const { providerImage, providerAvatar } = require('../src/media-urls');

const ROOT = path.join(__dirname, '..');
const INPUT = path.join(ROOT, 'data', 'providers-real.json');

const CATEGORY_META = {
  barbing: { label: 'Barbing', emoji: '✂️' },
  nails: { label: 'Nails', emoji: '💅' },
  makeup: { label: 'Makeup', emoji: '💄' },
  spa: { label: 'Spa', emoji: '🧖' },
  hair: { label: 'Hair', emoji: '💇' },
  skincare: { label: 'Skincare', emoji: '🧴' },
  braids: { label: 'Braids', emoji: '🪡' },
  lashes: { label: 'Lashes', emoji: '👁️' },
  brows_lashes: { label: 'Brows & Lashes', emoji: '👁️' },
  dental: { label: 'Dental', emoji: '🦷' },
  facials: { label: 'Facials', emoji: '🧖‍♂️' },
  massage: { label: 'Massage', emoji: '💆' },
  wellness: { label: 'Wellness', emoji: '💆' },
};

const AREA_COORDS = {
  'Wuse II': [9.0765, 7.4958],
  Maitama: [9.0833, 7.495],
  Garki: [9.0439, 7.4824],
  Gwarinpa: [9.1122, 7.4056],
  Asokoro: [9.045, 7.53],
  Utako: [9.065, 7.42],
  Lugbe: [8.996, 7.365],
  Wuse: [9.068, 7.489],
  Kubwa: [9.167, 7.398],
  Nyanya: [8.996, 7.585],
  Jabi: [9.078, 7.425],
  Guzape: [8.993, 7.518],
};

function nextId(data, key) {
  data._counters[key] = (data._counters[key] || 0) + 1;
  return data._counters[key];
}

async function main() {
  if (!fs.existsSync(INPUT)) {
    console.error(`Missing ${INPUT}`);
    console.error('Copy providers-real.example.json → providers-real.json and edit it.');
    process.exit(1);
  }

  const incoming = JSON.parse(fs.readFileSync(INPUT, 'utf8'));
  if (!Array.isArray(incoming) || incoming.length === 0) {
    console.error('providers-real.json must be a non-empty array.');
    process.exit(1);
  }

  const data = await load();

  // Keep demo providers inactive so app shows real ones first
  data.providers.forEach((p) => { p.status = 'inactive'; p.featured = 0; });

  let idx = 0;
  for (const row of incoming) {
    const cat = CATEGORY_META[row.category_slug];
    if (!cat) {
      console.warn(`Skip "${row.name}" — unknown category_slug: ${row.category_slug}`);
      continue;
    }

    const [baseLat, baseLng] = AREA_COORDS[row.area] || [9.0765, 7.4898];
    const providerId = nextId(data, 'providers');

    data.providers.push({
      id: providerId,
      status: 'active',
      name: row.name,
      category: cat.label,
      category_slug: row.category_slug,
      emoji: cat.emoji,
      rating: row.rating ?? 4.7,
      review_count: row.review_count ?? 0,
      distance_km: row.distance_km ?? 1.2,
      latitude: row.latitude ?? +(baseLat + (idx % 5) * 0.002).toFixed(6),
      longitude: row.longitude ?? +(baseLng + (idx % 3) * 0.002).toFixed(6),
      area: row.area || 'Wuse II',
      price_from: row.price_from ?? row.services?.[0]?.price ?? 5000,
      badge: row.badge ?? null,
      verified: row.verified ? 1 : 0,
      featured: row.featured !== false ? 1 : 0,
      gradient_start: '#e8f0ea',
      gradient_end: '#d4e6d8',
      image_url: row.image_url || providerImage(row.category_slug, providerId),
      avatar_url: row.avatar_url || providerAvatar(row.category_slug, providerId),
      phone: row.phone || null,
      bio: row.bio || '',
      provider_type: row.provider_type || 'mobile',
      provider_subtype: row.provider_subtype || (row.provider_type === 'salon' ? 'salon' : row.provider_type === 'mobile' ? 'mobile' : 'solo_pro'),
      work_locations: row.work_locations || ['client_home'],
      coverage_areas: row.coverage_areas || [row.area],
      travel_radius_km: row.travel_radius_km ?? 10,
      travel_fee_per_km: row.travel_fee_per_km ?? 0,
      min_travel_fee: row.min_travel_fee ?? 0,
      base_area: row.base_area || row.area || null,
      visit_types: row.provider_type === 'salon' ? 'salon' : row.provider_type === 'both' ? 'both' : 'home',
    });

    for (const s of row.services || []) {
      data.services.push({
        id: nextId(data, 'services'),
        provider_id: providerId,
        name: s.name,
        duration: s.duration,
        price: s.price,
      });
    }

    console.log(`Imported: ${row.name} (${cat.label}, ${row.area})`);
    idx++;
  }

  await save(data);
  await require('../src/export-bootstrap-file')();
  require('./bundle-deploy-data');
  console.log(`\nDone. ${idx} real providers active. Restart backend + Flutter app.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
