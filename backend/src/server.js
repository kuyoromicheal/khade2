const fs = require('fs');
const path = require('path');

// Load backend/.env without extra dependencies
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  fs.readFileSync(envPath, 'utf8').split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const eq = trimmed.indexOf('=');
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim();
      const val = trimmed.slice(eq + 1).trim();
      if (!process.env[key]) process.env[key] = val;
    }
  });
}

const express = require('express');
const cors = require('cors');
const api = require('./routes/api');
const { registerMediaRoutes } = require('./media-proxy');
const { load, isSupabase, save } = require('./database');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

require('../scripts/ensure-data');

async function start() {
  const data = await load();
  if (data.providers.length === 0) {
    await require('./seed')();
  } else {
    const { ensureDemoAccounts } = require('./routes/auth.routes');
    const changed = await ensureDemoAccounts(data);
    if (changed.length) await save(data, [...changed, '_counters']);
  }

  const app = express();
  const PORT = process.env.PORT || 3001;

  app.use(cors());

  app.post(
    '/api/payments/webhook',
    express.raw({ type: 'application/json' }),
    async (req, res) => {
      try {
        const { handlePaystackWebhook } = require('./paystack-webhook');
        const result = await handlePaystackWebhook(req.body, req.headers['x-paystack-signature']);
        res.status(result.status).send(result.body);
      } catch (e) {
        console.error('Paystack webhook error:', e);
        res.status(500).send('error');
      }
    },
  );

  app.use(express.json());

  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', service: 'khade-api', database: isSupabase ? 'supabase' : 'json' }),
  );

  registerMediaRoutes(app);

  const mediaDir = path.join(__dirname, '..', 'public', 'media');
  if (fs.existsSync(mediaDir)) {
    app.use('/media', express.static(mediaDir, { maxAge: '7d' }));
  }

  /** Paystack redirects here after payment — WebView detects this URL */
  app.get('/paystack/callback', (req, res) => {
    const ref = req.query.reference || req.query.trxref || '';
    res.send(`<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width"><title>Payment</title>
<style>body{font-family:sans-serif;text-align:center;padding:40px;background:#e8f0ea;color:#2d4a35}
.ok{font-size:48px}h1{margin:16px 0}</style></head>
<body><div class="ok">✓</div><h1>Payment Successful</h1><p>Reference: ${ref}</p><p>You can return to the Khade app.</p></body></html>`);
  });

  app.use('/api', api);

  app.use((err, _req, res, _next) => {
    console.error(err);
    res.status(500).json({ error: err.message || 'Server error' });
  });

  app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Khade API running at http://localhost:${PORT}`);
    console.log(`  Database:  ${isSupabase ? 'Supabase' : 'JSON file'}`);
    console.log(`  Paystack:  ${process.env.PAYSTACK_SECRET_KEY ? 'configured' : 'MISSING — add PAYSTACK_SECRET_KEY to backend/.env'}`);
  });
}

start().catch((e) => {
  console.error('Failed to start:', e);
  process.exit(1);
});
