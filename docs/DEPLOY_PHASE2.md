# Phase 2 — Deploy Khade API to the internet

Your API will live at a public URL (e.g. `https://khade-api.onrender.com`) so the app works without your PC on the same Wi‑Fi.

---

## Before you deploy

1. **Push the project to GitHub** (private repo is fine).
2. **Do not commit** `backend/.env` — secrets go in Render’s dashboard only.
3. Your **10 real providers** are bundled in `backend/data/khade.deploy.json` (copied to `khade.json` on first boot).

After changing providers locally, refresh the bundle:

```powershell
cd backend
npm run bundle:data
```

---

## Option A — Render (recommended, free tier)

### 1. Create account

Sign up at [render.com](https://render.com) and connect your GitHub account.

### 2. New Blueprint

1. Dashboard → **New** → **Blueprint**
2. Connect repo `khade2`
3. Render reads `render.yaml` at the repo root
4. Click **Apply**

### 3. Set environment variables

In the **khade-api** service → **Environment**:

| Key | Value |
|-----|--------|
| `PAYSTACK_SECRET_KEY` | Your secret from [Paystack dashboard](https://dashboard.paystack.com/#/settings/developer) |
| `PAYSTACK_PUBLIC_KEY` | Your public key (`pk_test_...` or live later) |
| `PAYSTACK_CALLBACK_BASE` | `https://YOUR-SERVICE-NAME.onrender.com` (no trailing slash) |

Use the exact URL Render gives you after deploy, e.g. `https://khade-api-xxxx.onrender.com`.

### 4. Deploy

Render builds and starts automatically. Check:

```text
https://YOUR-SERVICE.onrender.com/health
```

Should return: `{"status":"ok","service":"khade-api"}`

Test providers:

```text
https://YOUR-SERVICE.onrender.com/api/providers
```

You should see your 10 real salons.

### 5. Point the Flutter app at production

```powershell
cd khade_app
flutter run -d RRCYA02415N --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Release APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

---

## Option B — Railway

1. [railway.app](https://railway.app) → New Project → Deploy from GitHub
2. Set **Root Directory** to `backend`
3. Start command: `npm start`
4. Add the same env vars as above
5. Generate a public domain in Railway settings
6. Set `PAYSTACK_CALLBACK_BASE` to that domain

---

## Videos on production

Feed videos use the **Pexels proxy** at `/media/pexels/{id}.mp4` — no extra setup. The server streams clips; your phone loads them from your API URL.

---

## Paystack checklist

- [ ] `PAYSTACK_CALLBACK_BASE` = your **HTTPS** Render URL (not `http://10.x.x.x`)
- [ ] Test payment in app with backend live
- [ ] Paystack dashboard: callback URL can stay as your API `/paystack/callback`

---

## Updating data after deploy

Render free tier **resets disk** on redeploy unless you add a persistent disk (paid).

**Workflow:**

1. Edit `providers-real.json` locally
2. `npm run import:providers`
3. `npm run bundle:data`
4. Commit `khade.deploy.json` + push → Render redeploys

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App shows offline | Wrong `API_BASE_URL`; use `https://` not `http://` |
| Empty providers | Check `/api/providers`; redeploy with fresh `khade.deploy.json` |
| Paystack 404 | `PAYSTACK_CALLBACK_BASE` must match Render URL |
| Slow first request | Render free tier sleeps after ~15 min idle — first hit wakes it (~30s) |
| Videos won’t play | Confirm `/media/pexels/3195394.mp4` returns 200 on your API URL |

---

## Your next command after deploy

Replace with your real Render URL:

```powershell
flutter run --dart-define=API_BASE_URL=https://khade-api-xxxx.onrender.com
```
