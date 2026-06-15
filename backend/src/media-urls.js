/**
 * Category- and provider-matched HQ media.
 * Videos: unique entries from data/video-catalog.json (no repeats in feed).
 */
const fs = require('fs');
const path = require('path');

const pexels = (id, w = 1600, h = 1200) =>
  `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=${w}&h=${h}&fit=crop`;

const CATEGORY_IMAGES = {
  all: pexels(3993449, 600, 600),
  barbing: pexels(3992865, 600, 600),
  nails: pexels(3993449, 600, 600),
  makeup: pexels(2533266, 600, 600),
  spa: pexels(3757942, 600, 600),
  hair: pexels(1319460, 600, 600),
  skincare: pexels(3762879, 600, 600),
  braids: pexels(1034062, 600, 600),
  lashes: pexels(2103127, 600, 600),
  wellness: pexels(3822621, 600, 600),
};

const PROVIDER_PHOTOS = {
  barbing: [3992865, 3998400, 28608055, 3992875, 3376998, 3992876, 3992865, 3998400, 28608055, 3992875],
  nails: [3993449, 4467687, 5240687, 3997379, 5240671, 3993449, 4467687, 5240687, 3997379, 5240671],
  makeup: [2533266, 3373736, 2103127, 3373736, 2533266, 2103127, 3373736, 2533266, 2103127, 3373736],
  spa: [3757942, 461074, 7869680, 3757942, 461074, 7869680, 3757942, 461074, 7869680, 3757942],
  hair: [1319460, 769283, 1034062, 1319460, 769283, 1034062, 1319460, 769283, 1034062, 1319460],
  skincare: [3762879, 4041392, 3762879, 4041392, 3762879, 4041392, 3762879, 4041392, 3762879, 4041392],
  braids: [1034062, 769283, 1319460, 1034062, 769283, 1319460, 1034062, 769283, 1319460, 1034062],
  lashes: [2103127, 2533266, 3373736, 2103127, 2533266, 3373736, 2103127, 2533266, 3373736, 2103127],
  wellness: [3822621, 8436722, 3757942, 3822621, 8436722, 3757942, 3822621, 8436722, 3757942, 3822621],
};

const FEED_IMAGES = {
  barbing: pexels(3992865, 1080, 1920),
  nails: pexels(3993449, 1080, 1920),
  makeup: pexels(2533266, 1080, 1920),
  spa: pexels(3757942, 1080, 1920),
  hair: pexels(1319460, 1080, 1920),
  skincare: pexels(3762879, 1080, 1920),
  braids: pexels(1034062, 1080, 1920),
  lashes: pexels(2103127, 1080, 1920),
  wellness: pexels(3822621, 1080, 1920),
};

const FALLBACK_VIDEOS = {
  barbing: ['barbing-1.mp4'],
  nails: ['nails-1.mp4'],
  makeup: ['makeup-1.mp4'],
  spa: ['spa-1.mp4'],
  hair: ['hair-1.mp4'],
  skincare: ['skincare-1.mp4'],
  braids: ['braids-1.mp4'],
  lashes: ['lashes-1.mp4'],
  wellness: ['wellness-1.mp4'],
};

let _catalog = null;

function loadVideoCatalog() {
  if (_catalog) return _catalog;
  const p = path.join(__dirname, '..', 'data', 'video-catalog.json');
  if (fs.existsSync(p)) {
    _catalog = JSON.parse(fs.readFileSync(p, 'utf8'));
    return _catalog;
  }
  _catalog = { byCategory: FALLBACK_VIDEOS, total: 9 };
  return _catalog;
}

/** Assign each feed post a unique video file for its category (never reused). */
function createVideoAllocator() {
  const catalog = loadVideoCatalog();
  const byCat = catalog.byCategory || FALLBACK_VIDEOS;
  const all = catalog.all || Object.values(byCat).flat();
  const used = new Set();

  return function takeUnique(catKey) {
    const pools = [byCat[catKey], catalog.all].filter(Boolean);
    for (const pool of pools) {
      const list = Array.isArray(pool) ? pool : [];
      for (const file of list) {
        if (!used.has(file)) {
          used.add(file);
          if (file.startsWith('pexels-')) {
            const id = file.replace('pexels-', '').replace('.mp4', '');
            return `/media/pexels/${id}.mp4`;
          }
          return `/media/videos/${file}`;
        }
      }
    }
    return null;
  };
}

function countUniqueVideos() {
  const c = loadVideoCatalog();
  return c.total || (c.all || []).length || 0;
}

function categoryImage(slug) {
  return CATEGORY_IMAGES[slug] || CATEGORY_IMAGES.all;
}

function providerImage(catKey, index) {
  const ids = PROVIDER_PHOTOS[catKey] || PROVIDER_PHOTOS.makeup;
  return pexels(ids[index % ids.length], 1600, 1200);
}

function providerAvatar(catKey, index) {
  const ids = PROVIDER_PHOTOS[catKey] || PROVIDER_PHOTOS.makeup;
  return pexels(ids[index % ids.length], 400, 400);
}

function feedImageForProvider(provider) {
  if (provider.image_url) return provider.image_url;
  const catKey = provider.category_slug || 'makeup';
  const ids = PROVIDER_PHOTOS[catKey] || PROVIDER_PHOTOS.makeup;
  return pexels(ids[provider.id % ids.length], 1080, 1920);
}

function feedMedia(catKey, providerId, type = 'image', providerImageUrl = null, videoUrl = null) {
  const image = providerImageUrl || providerImage(catKey, providerId);
  if (type === 'video') {
    return {
      media_type: 'video',
      image_url: image,
      video_url: videoUrl,
    };
  }
  return { media_type: 'image', image_url: image, video_url: null };
}

module.exports = {
  categoryImage,
  providerImage,
  providerAvatar,
  feedMedia,
  feedImageForProvider,
  loadVideoCatalog,
  createVideoAllocator,
  countUniqueVideos,
};
