# Phase 2 Prototype — What's Built Now

This document maps the **live prototype** in the repo vs the full Phase 2 spec in [PHASE2_CURSOR_PROMPT.md](./PHASE2_CURSOR_PROMPT.md).

---

## Architecture recommendation

| Role | Best platform | Why |
|------|---------------|-----|
| **Customer** | Flutter app (`/home` shell) | Mobile-first booking, feed, tracking |
| **Provider** | Flutter app (`/provider-home` shell) | Separate bottom nav, earnings, calendar |
| **Admin** | **Next.js web dashboard** (build in Phase 2b) | Tables, charts, moderation, CSV — desktop ops |
| **Admin fallback** | Flutter `/admin` | Founder on-the-go approvals |

---

## Prototype flow (try on phone)

```
Splash (animated) → Onboarding (3 slides) → Role Picker
    ├── Customer → Home / Explore / Feed (guest OK)
    └── Provider → Login → Provider App (4-tab shell)

Register Customer → ₦2,000 wallet bonus dialog → Bronze tier
Register Provider → CAC required → under_review → Provider onboarding

Book service → Add note → Pay → Track → Call/WhatsApp provider
```

---

## Built in this prototype

| Feature | Status | Files |
|---------|--------|-------|
| Premium splash | ✅ | `splash_screen.dart` |
| Role picker (2 apps) | ✅ | `role_picker_screen.dart` |
| Customer vs provider registration | ✅ | `register_screen.dart` |
| CAC for providers | ✅ | backend `auth.routes.js` |
| ₦2,000 welcome bonus | ✅ | backend + `tier_badge.dart` dialog |
| Bronze/Silver/Gold tiers (UI) | ✅ | `tier_badge.dart`, profile |
| Provider app shell (4 tabs) | ✅ | `provider_app_shell.dart` |
| Provider add services | ✅ | `provider_services_screen.dart` |
| Booking notes | ✅ | `booking_screen.dart` → API |
| JWT auth (3 roles) | ✅ | Phase 1 + demo accounts |
| 25 providers + 75 posts | ✅ | `npm run seed:providers` |
| Call + WhatsApp/SMS | ✅ | `tracking_screen.dart` |
| Admin tabs (overview/providers/bookings/payouts) | ✅ | `admin_screen.dart` |

---

## Not yet real-time (Phase 2 next)

- Supabase Realtime on wallet, notifications, feed
- In-app chat per booking
- Provider GPS upload for live map
- FCM push notifications
- Group/owambe bookings
- Paystack webhooks
- Full Supabase as only DB on Render

---

## Demo accounts

| Email | Password | Goes to |
|-------|----------|---------|
| customer@khade.ng | password123 | Customer home |
| provider@khade.ng | password123 | Provider app |
| admin@khade.ng | password123 | Admin dashboard |

---

## Launch command

```powershell
cd C:\Users\mikeg\OneDrive\Desktop\khade2\khade_app
flutter run -d RRCYA02415N --dart-define=API_BASE_URL=https://khade-api.onrender.com
```

Push latest backend to Render for auth + ₦2000 bonus to work live.

---

## Use the Cursor prompt

Open [PHASE2_CURSOR_PROMPT.md](./PHASE2_CURSOR_PROMPT.md) in Cursor and say:

> Implement Phase 2 per docs/PHASE2_CURSOR_PROMPT.md, starting with Supabase Realtime and in-app chat.
