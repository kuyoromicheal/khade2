# Khade Beauty Platform

Luxury beauty & wellness on demand — Flutter mobile app + Node.js REST API.

## Project structure

```
khade2/
├── khade_app/          ← Flutter mobile app
├── backend/            ← REST API (Express + JSON store)
├── docs/               ← Setup guides
└── scripts/            ← Helper scripts
```

---

## 1. Backend API

```bash
cd backend
npm install
npm start
```

Runs at **http://localhost:3001**

| Endpoint | Description |
|----------|-------------|
| `GET /api/providers` | List providers |
| `GET /api/providers/:id` | Provider + services |
| `GET /api/bookings?userId=1` | User bookings |
| `POST /api/bookings` | Create booking |
| `GET /api/feed` | Inspiration feed |
| `GET /api/users/1` | User profile |
| `POST /api/payments/initialize` | Paystack stub |

---

## 2. Flutter app

```bash
cd khade_app
flutter pub get
flutter run -d <your-phone-id>
```

**With backend + phone on same Wi‑Fi:**
```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3001
```

Find your PC IP: `ipconfig` (look for IPv4 under Wi‑Fi, e.g. `192.168.1.250`)

---

## 3. Android Studio setup

Android SDK is **not installed yet** on this machine.

Full guide: **[docs/ANDROID_SETUP.md](docs/ANDROID_SETUP.md)**

Quick steps:
1. Install [Android Studio](https://developer.android.com/studio)
2. SDK Manager → install Android 14 (API 34) + Platform Tools
3. Run `.\scripts\setup-android-env.ps1` from project root
4. Restart terminal → `flutter doctor --android-licenses`
5. `cd khade_app && flutter run`

Build release APK:
```bash
flutter build apk --release
```

---

## 4. Paystack (production)

The payment endpoint is a stub. For real payments:
1. Get API keys from [paystack.com](https://paystack.com)
2. Replace `POST /api/payments/initialize` in `backend/src/routes/api.js`
3. Add webhook handler for payment confirmation

---

## What's next?

| Priority | Task |
|----------|------|
| Now | Install Android Studio → run on phone |
| Next | Wire real Paystack payments |
| Later | User auth (JWT / Firebase) |
| Later | Provider GPS tracking (Google Maps) |
| Later | Push notifications (FCM) |
