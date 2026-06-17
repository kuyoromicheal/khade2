# Khade — Launch Readiness (Flutter stack)

Your guide targets **Expo + Supabase Auth + Edge Functions**. Khade is built differently — use this document instead.

| Layer | Actual stack |
|-------|----------------|
| Mobile | **Flutter** (`khade_app/`) — customer + Khade Pro flavors |
| API | **Node/Express** on Render (`https://khade-api.onrender.com`) |
| Database | **Supabase Postgres** — `khade_*` tables, backend uses `service_role` |
| Auth | **Custom JWT** via `/api/auth/*` (not Supabase Auth in the app yet) |
| Payments | **Paystack** — WebView checkout + server verify + webhook |

---

## Already done

- [x] Supabase connected — 13 `khade_*` tables, 136 providers, 405 services
- [x] Live API on Render with `database: supabase` health check
- [x] Flutter apps point phones at production API automatically
- [x] Paystack initialize / verify / wallet top-up (WebView)
- [x] Demo logins: `customer@khade.ng` / `provider@khade.ng` / `password123`
- [x] Provider dashboard, calendar, clients CRM, inbox, portfolio
- [x] Customer booking, wallet, tiers, cashback logic in API
- [x] Connection banner shows **Live · Supabase** when connected

---

## Part 1 — Accounts (manual, in dashboards)

### Supabase (`lqfzutfhhshditpewedt`)

Run migrations from `backend/`:

```powershell
cd backend
npm run supabase:status
npm run supabase:migrate    # needs SUPABASE_DB_URL in .env
npm run supabase:seed-app
```

**Dashboard (you):**

- **Authentication** → enable Email + Google (for future Supabase Auth migration)
- **Storage** → create buckets: `provider-photos`, `portfolio-videos`, `provider-docs`, `post-images`
- **Database → Realtime** — `phase7-launch.sql` adds bookings/messages; verify in dashboard

> RLS is **disabled** on `khade_*` tables today. The API uses `service_role`. Client-side Supabase access is not used yet — do not copy the guide’s `profiles` / `auth.uid()` policies verbatim.

### Paystack

- Test keys in `backend/.env` ✓
- **Webhook URL** (Render): `https://khade-api.onrender.com/api/payments/webhook`
- Live mode needs CAC + business verification

### Google Maps

Flutter uses `flutter_map` + `geolocator` today (no Google Maps SDK yet).

For production maps:

```powershell
flutter run --dart-define=GOOGLE_MAPS_KEY=AIza...
```

Enable in Google Cloud: Maps SDK (Android/iOS), Places, Geocoding, Distance Matrix.

### Firebase (push)

Not wired yet. Plan:

1. Firebase project → `google-services.json` / `GoogleService-Info.plist`
2. `firebase_messaging` + `flutter_local_notifications` in Flutter
3. Store token via `POST /api/users/fcm-token` → `khade_fcm_tokens`
4. Server sends push on booking/message/wallet events (Node + FCM HTTP v1)

### Cloudinary

Media today: Pexels catalog + `backend/public/media`. For user uploads, add Cloudinary unsigned presets and upload from Flutter `image_picker`.

### Google Sign-In

Not implemented. Options:

- **Short term:** keep email/password JWT auth (works now)
- **Later:** Supabase Auth + Google provider, or `google_sign_in` + backend OAuth

---

## Part 2 — Environment variables

### Backend (`backend/.env`) — server only, never in Flutter

```bash
SUPABASE_URL=https://lqfzutfhhshditpewedt.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
JWT_SECRET=...
PAYSTACK_SECRET_KEY=sk_test_...
PAYSTACK_PUBLIC_KEY=pk_test_...
PAYSTACK_CALLBACK_BASE=https://khade-api.onrender.com
SUPABASE_DB_URL=postgresql://...   # optional, for npm run supabase:migrate
```

Set the same on **Render** (`khade-api`).

### Flutter (`--dart-define` or CI secrets)

```bash
flutter run --flavor customer -t lib/main.dart \
  --dart-define=API_BASE_URL=https://khade-api.onrender.com \
  --dart-define=PAYSTACK_PUBLIC_KEY=pk_test_... \
  --dart-define=GOOGLE_MAPS_KEY=AIza...
```

Never put `SUPABASE_SERVICE_ROLE_KEY`, `PAYSTACK_SECRET_KEY`, or Firebase server keys in the app.

---

## Part 3 — API routes (not Supabase Edge Functions)

| Guide Edge Function | Khade equivalent |
|---------------------|------------------|
| `paystack-webhook` | `POST /api/payments/webhook` |
| `create-booking` | `POST /api/bookings` |
| `complete-booking` | `PATCH /api/provider/bookings/:id/status` |
| `cancel-booking` | `PATCH /api/bookings/:id/cancel` |
| `provider-payout` | `POST /api/provider/payouts` (+ Paystack Transfer — TODO) |
| `send-push-notification` | TODO — Node + FCM |
| `apply-cashback` / `check-tier-upgrade` | In `provider.routes.js` + `tier.js` on complete |

---

## Part 4 — Database migrations (order)

```
backend/supabase/
  auth-extensions.sql
  phase2.sql
  phase2-full.sql
  add-booking-dest.sql
  fix-rls.sql
  phase3-mobile.sql
  phase3-v3.sql
  phase5-solo.sql
  phase6-instant-signup.sql
  phase7-launch.sql          ← bank fields, FCM, realtime
```

---

## Part 5 — App store (Flutter, not EAS/Expo)

| | Customer | Khade Pro |
|---|----------|-----------|
| Android package | `com.khade.khade_app` | `com.khade.khade_provider` |
| iOS bundle | set in Xcode | separate target |

**Build release APK:**

```powershell
cd khade_app
flutter build apk --flavor customer -t lib/main.dart --release
flutter build apk --flavor provider -t lib/main_provider.dart --release
```

**iOS:** Apple Developer ($99/yr) → archive in Xcode → TestFlight.

**Android:** Play Console ($25 once) → upload AAB.

Add signing config before store submit (currently debug signing in release).

---

## Part 6 — Testing checklist

Use demo accounts on a real device:

```powershell
cd khade_app
flutter run --flavor customer -t lib/main.dart -d <device-id>
flutter run --flavor provider -t lib/main_provider.dart -d <device-id>
```

### Customer

- [ ] Login / register → wallet bonus
- [ ] Browse 136 providers from Supabase
- [ ] Book service (wallet + cash)
- [ ] Paystack wallet top-up
- [ ] Chat / notifications
- [ ] Cancel booking
- [ ] Tier upgrade after completions

### Provider

- [ ] Login → dashboard with real bookings
- [ ] Calendar + block dates
- [ ] Accept / complete booking → earnings
- [ ] Clients CRM
- [ ] Portfolio post
- [ ] Bank resolve (Paystack)
- [ ] Payout request

---

## Part 7 — Launch order (5 weeks)

| Week | Focus |
|------|--------|
| 1 | All API keys in Render + `.env`; run migrations + seed; Paystack webhook live |
| 2 | Firebase push; Google Maps provider tracking; Cloudinary uploads |
| 3 | Full device testing both apps; fix bugs |
| 4 | Privacy policy at `khade.app/privacy`; Play + App Store listings; internal APK |
| 5 | Store submit; CAC for Paystack live; launch |

---

## Part 8 — Legal

- Privacy policy + terms (required by stores and Paystack)
- Domain `khade.app` + `support@khade.app`
- CAC registration for Paystack live mode (~₦20k–35k, 2–4 weeks)

---

## Quick commands

```powershell
# Database health
cd backend
npm run supabase:status
npm run supabase:seed-app

# Local API
npm run dev

# Live API health
curl https://khade-api.onrender.com/health
```

Expected: `{"status":"ok","service":"khade-api","database":"supabase"}`
