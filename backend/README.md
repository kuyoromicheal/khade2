# Khade Backend API

REST API for the Khade beauty platform. Uses Express + SQLite with seed data matching the app prototype.

## Quick start

```bash
cd backend
npm install
npm start
```

Server runs at **http://localhost:3001**

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/api/providers` | List providers (`?featured=true`, `?category=Makeup`) |
| GET | `/api/providers/:id` | Provider detail + services |
| GET | `/api/users/:id` | User profile |
| GET | `/api/bookings?userId=1` | User bookings (`?status=upcoming`) |
| POST | `/api/bookings` | Create booking |
| GET | `/api/feed` | Inspiration feed |
| GET | `/api/notifications?userId=1` | Notifications |
| GET | `/api/admin/stats` | Admin dashboard stats |
| POST | `/api/payments/initialize` | Paystack stub |

## Create booking example

```bash
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "providerId": 1,
    "serviceId": 1,
    "locationType": "home",
    "address": "Maitama, Abuja",
    "scheduledAt": "2025-06-25T14:00:00"
  }'
```

## Paystack (production)

Replace the stub in `src/routes/api.js` with real [Paystack Initialize Transaction](https://paystack.com/docs/api/transaction/#initialize) calls using your secret key in `PAYSTACK_SECRET_KEY` env var.

## Database

SQLite file: `backend/data/khade.db`

Re-seed from scratch:
```bash
rm data/khade.db
npm run seed
```
