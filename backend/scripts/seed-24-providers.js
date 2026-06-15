/**
 * Generate 24 demo providers across all categories for impressive demos.
 * Run: node scripts/seed-24-providers.js
 * Then: node scripts/import-real-providers.js (uses providers-real.json — copy output)
 */
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'data', 'providers-real.json');

const AREAS = ['Maitama', 'Wuse II', 'Garki', 'Gwarinpa', 'Asokoro', 'Utako', 'Jabi', 'Guzape'];

const CATALOG = [
  { cat: 'makeup', names: ['Glam Studio Pro', 'Beat by Ada', 'Luxury Face Abuja', 'Glamour by Chioma'] },
  { cat: 'nails', names: ['Royal Touch Nails', 'Polish House Abuja', 'Nail Affair Studio', 'Tips & Toes NG'] },
  { cat: 'spa', names: ['Serenity Spa Abuja', 'Zen Wellness Lounge', 'Oasis Day Spa'] },
  { cat: 'barbing', names: ['Fade House Abuja', 'Sharp Cuts Studio', 'The Grooming Lab', 'Elite Grooming Lounge'] },
  { cat: 'hair', names: ['Luxury Hair Lounge', 'Crown & Co Hair', 'Silk Strands Abuja', 'Hair Majesty Studio'] },
  { cat: 'skincare', names: ['Glow Skin Clinic', 'Derma Luxe Abuja', 'Radiance Skin Bar'] },
  { cat: 'braids', names: ['Braids & Beyond', 'Plait Perfect Abuja', 'African Crown Braids'] },
];

const PRICES = {
  barbing: [[3500, 'Classic Cut', '30 mins'], [5500, 'Fade + Beard', '45 mins'], [3000, 'Kids Cut', '25 mins']],
  nails: [[7000, 'Classic Manicure', '45 mins'], [8500, 'Gel Polish', '60 mins'], [12000, 'Full Set Acrylic', '90 mins']],
  makeup: [[8000, 'Soft Glam', '60 mins'], [15000, 'Full Glam', '90 mins'], [35000, 'Bridal Makeup', '120 mins']],
  spa: [[15000, 'Swedish Massage', '60 mins'], [22000, 'Deep Tissue', '75 mins'], [45000, 'Couples Spa', '120 mins']],
  hair: [[5000, 'Wash & Blow', '45 mins'], [12000, 'Silk Press', '90 mins'], [25000, 'Install + Style', '180 mins']],
  skincare: [[10000, 'Express Facial', '45 mins'], [18000, 'Hydra Facial', '60 mins'], [30000, 'Anti-Age Treatment', '90 mins']],
  braids: [[12000, 'Box Braids', '180 mins'], [18000, 'Knotless Braids', '240 mins'], [35000, 'Ghana Weaving', '300 mins']],
};

const BADGES = ['🔥 Popular', '⭐ Top Rated', '✦ Featured', '💎 Premium', null];

let phoneBase = 8012345678;
const providers = [];

for (const group of CATALOG) {
  group.names.forEach((name, i) => {
    const area = AREAS[(providers.length + i) % AREAS.length];
    const priceList = PRICES[group.cat];
    providers.push({
      name,
      category_slug: group.cat,
      area,
      phone: `+234${phoneBase++}`,
      price_from: priceList[0][0],
      rating: +(4.5 + (i % 5) * 0.1).toFixed(1),
      review_count: 40 + providers.length * 7,
      verified: i % 2 === 0,
      featured: i === 0,
      badge: BADGES[i % BADGES.length],
      services: priceList.map(([price, sname, dur]) => ({ name: sname, duration: dur, price })),
    });
  });
}

fs.writeFileSync(OUT, JSON.stringify(providers, null, 2));
console.log(`Wrote ${providers.length} providers → ${OUT}`);
console.log('Run: npm run import:providers');
