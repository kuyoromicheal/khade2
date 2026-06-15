/** Stream Pexels MP4s through our backend (mobile clients get 403 direct). */
const https = require('https');

const UA = 'Mozilla/5.0 (compatible; KhadeMediaBot/1.0)';
const RESOLUTIONS = [
  'hd_1280_720_25fps',
  'hd_1280_720_30fps',
  'sd_960_540_25fps',
  'sd_640_360_25fps',
];

function pexelsUrl(id, res) {
  return `https://videos.pexels.com/video-files/${id}/${id}-${res}.mp4`;
}

function streamPexelsVideo(id, req, res) {
  let i = 0;

  const tryNext = () => {
    if (i >= RESOLUTIONS.length) {
      return res.status(404).json({ error: 'Video not found' });
    }
    const r = RESOLUTIONS[i++];
    const url = pexelsUrl(id, r);

    const opts = {
      headers: {
        'User-Agent': UA,
        ...(req.headers.range ? { Range: req.headers.range } : {}),
      },
    };

    https.get(url, opts, (upstream) => {
      if (upstream.statusCode !== 200 && upstream.statusCode !== 206) {
        upstream.resume();
        return tryNext();
      }

      res.status(upstream.statusCode);
      const pass = ['content-type', 'content-length', 'content-range', 'accept-ranges'];
      pass.forEach((h) => {
        if (upstream.headers[h]) res.setHeader(h, upstream.headers[h]);
      });
      if (!res.getHeader('content-type')) res.setHeader('Content-Type', 'video/mp4');
      upstream.pipe(res);
    }).on('error', tryNext);
  };

  tryNext();
}

function registerMediaRoutes(app) {
  app.get('/media/pexels/:id', (req, res) => {
    const raw = req.params.id.replace(/\.mp4$/i, '');
    const id = parseInt(raw, 10);
    if (!id || Number.isNaN(id)) return res.status(400).json({ error: 'Invalid video id' });
    streamPexelsVideo(id, req, res);
  });
}

module.exports = { registerMediaRoutes, streamPexelsVideo };
