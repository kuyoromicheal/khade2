/** Seed 3–4 feed posts per active provider. Run after import:providers */
const { load, save, nextId } = require('../src/database');
const { providerImage } = require('../src/media-urls');

const CAPTIONS = [
  'Book your slot before the weekend fills up ✦',
  'Transformation Tuesday — swipe to see the glow-up 💫',
  'Abuja\'s finest — home visits available',
  'New client special this week only 🔥',
];

async function main() {
  const data = await load();
  const active = data.providers.filter((p) => p.status === 'active');
  let added = 0;

  for (const p of active) {
    const existing = data.feed_posts.filter((f) => f.provider_id === p.id).length;
    const need = Math.max(0, 3 - existing);
    for (let i = 0; i < need; i++) {
      data.feed_posts.unshift({
        id: await nextId(data, 'feed_posts'),
        provider_id: p.id,
        image_emoji: p.emoji,
        image_url: p.image_url || providerImage(p.category_slug, p.id),
        video_url: null,
        media_type: i === 0 ? 'image' : 'image',
        badge: p.category_slug,
        caption: `${CAPTIONS[i % CAPTIONS.length]} · ${p.name}`,
        likes: 120 + p.id * 17 + i * 23,
        comments: 8 + i * 3,
        liked_by: [],
        created_at: new Date(Date.now() - i * 86400000).toISOString(),
      });
      added++;
    }
    if (!p.availability) {
      p.availability = {
        mon: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        tue: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        wed: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        thu: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        fri: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        sat: ['10:00', '11:00', '14:00', '15:00'],
        sun: [],
        blocked_dates: [],
      };
    }
  }

  await save(data);
  await require('../src/export-bootstrap-file')();
  console.log(`Added ${added} feed posts for ${active.length} providers.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
