# Khade Phase 2 — Full Cursor Prompt

Copy everything below into Cursor as your implementation spec. **Stack: Flutter (khade_app) + Node/Express (backend) + Supabase — NOT React Native/Expo.**

---

## Context

Khade is a luxury on-demand beauty app for Nigeria (Abuja first), positioned to beat Fresha. Phase 1 is done: customer booking flow, Paystack, live tracking UI, video feed, wallet, JWT auth, 25 providers, provider/admin dashboards (basic).

Phase 2 must match Fresha's enterprise features **and** win on Nigeria-specific needs: Paystack, cash/POS, group owambe bookings, CAC verification, WhatsApp/SMS contact, 10% commission (not Fresha's 20%).

---

## Design System (do not change)

- Primary: Matcha `#4a7c59` · Accent Gold `#c9a84c` · Cream `#faf8f4` · Deep `#2d5c3f`
- Fonts: Cormorant Garamond (headings) + DM Sans (UI)
- Aesthetic: luxury, minimal, editorial — billion-dollar Nigerian brand

---

## Architecture Decisions (mandatory)

### Three apps, one codebase
Use **Flutter flavor / role-based routing**, not three separate repos:

| App | Users | Entry route | Bottom nav |
|-----|-------|-------------|------------|
| **Customer App** | Clients | `/home` | Home · Explore · Bookings · Feed · Profile |
| **Provider App** | Salons/pros | `/provider-home` | Today · Calendar · Posts · Earnings · Profile |
| **Admin** | Khade ops | **Web dashboard** (recommended) | N/A |

**Best admin platform:** **Next.js 15 + Supabase + shadcn/ui** deployed on Vercel. Reasons: large tables, charts, CSV export, moderation queues, payout approval — desktop-first. Keep Flutter `/admin` as mobile fallback for founders on the go.

### Database: Supabase as single source of truth
- All reads/writes through Express using `SUPABASE_SERVICE_ROLE_KEY` (server only)
- Run `backend/supabase/schema.sql` + `auth-extensions.sql` + new `phase2.sql`
- Migrate JSON seed → Supabase via `npm run migrate:supabase`
- Enable Supabase Realtime on: `khade_bookings`, `khade_notifications`, `khade_wallet_transactions`, `khade_feed_posts`, provider location table
- Optional: Supabase Auth replaces JWT later; Phase 2 keeps JWT + sync user row in `khade_users`

---

## Phase 2 Feature Spec

### A. Auth & Registration (Fresha-style split)

**Customer registration** (simple, 30 seconds):
- Name, email, phone (+234), password, city
- Optional: skip account to browse (guest mode — already exists)
- On signup: **₦2,000 welcome wallet credit** ("Free ₦2,000 is on us"), push notification + wallet transaction
- Default tier: **Bronze**

**Provider registration** (verified business, like Fresha):
- Step 1: Account — name, email, phone, password
- Step 2: Business — business name, category, CAC registration number (required), TIN optional
- Step 3: Location — salon address OR home-visit only OR both; Abuja area; map pin
- Step 4: Services — add 1+ services (name, duration, price ₦)
- Step 5: Portfolio — 3+ photos optional; status = `under_review`
- Admin approves → `active`; rejected → `suspended` with reason

**Provider tiers** (based on completed bookings + rating):
- Bronze (0–9) · Silver (10–24) · Gold (25+) — badge on profile, search boost for Gold

**Customer tiers** (based on completed bookings):
- Bronze (0–4) · Silver (5–14) · Gold (15+) — perks: priority slots, 5% cashback on Gold

---

### B. Real-time sync (Supabase Realtime + polling fallback)

Wire these to update UI without manual refresh:

| Feature | Mechanism |
|---------|-----------|
| Wallet balance | Realtime on `khade_wallet_transactions` + optimistic UI |
| Notifications | Realtime + 10s poll; FCM push in Phase 2b |
| Feed likes/comments | Realtime on `khade_feed_posts`, `khade_feed_comments` |
| Live tracking | Provider posts GPS every 5s → `khade_provider_locations`; customer subscribes |
| Chat | Supabase Realtime on `khade_messages` OR Twilio/Africa's Talking |
| Location | Customer GPS persisted; provider sees dest on map |

---

### C. Booking enhancements

- **Add note** — customer note on booking (`note` column), shown to provider
- **Real availability** — provider calendar blocks slots; booking UI fetches `/api/provider/:id/slots?date=`
- **Group bookings** — `khade_booking_groups` for bridal/owambe (1 lead customer, N services, N providers optional)
- **Waitlist** — when slot full, join waitlist; auto-notify on cancel
- **No-show protection** — deposit via Paystack (optional %), automated SMS/email reminders 24h + 1h before

---

### D. Communication

- **Call** — native `tel:` dialer (done)
- **Message** — WhatsApp + SMS with pre-filled booking context (done)
- **In-app chat** — thread per booking: `khade_messages(booking_id, sender_id, body, created_at)` with Realtime

---

### E. Fresha parity features (prioritized)

1. **Client CRM** — provider sees customer history, notes, lifetime value, allergies/color formulas
2. **Marketing campaigns** — provider sends promo to past clients (SMS/WhatsApp template)
3. **Staff management** — provider adds team members, assigns to bookings
4. **Inventory** — product SKM, low-stock alerts (Phase 2b)
5. **Analytics** — provider dashboard: rebooking rate, peak hours, revenue charts
6. **Digital intake forms** — skin type, allergies, consent; attached to client profile
7. **Khade Capital** — provider loan product, repay % of earnings (Phase 3)

---

### F. Monetization (backend logic)

| Revenue stream | Amount | Trigger |
|----------------|--------|---------|
| Commission | 10% | Every completed booking |
| Featured listing | ₦5,000/mo | Provider purchase |
| Khade Gold (customer) | ₦3,000/mo | Subscription |
| Search boost | ₦2,500/7 days | Provider purchase |
| Verified badge | ₦15,000/yr | After CAC check |

Track all in `khade_platform_revenue`.

---

### G. Provider service management

- Provider App → Services tab: CRUD services (name, duration, price, active/inactive)
- API: `POST/PATCH/DELETE /api/provider/services`
- Changes reflect immediately on customer booking screen

---

### H. Splash & onboarding

- Premium animated splash: deep green gradient, gold logo mark, tagline "your beauty, on demand"
- 3-slide onboarding → **Role picker**: "I'm a Customer" / "I'm a Provider"
- Role picker sets default registration path; guest can skip

---

## API Routes to Add/Complete

```
POST   /api/auth/register          — customer + provider variants, ₦2000 bonus
POST   /api/auth/login
GET    /api/auth/me

GET    /api/provider/:id/slots
POST   /api/provider/services
PATCH  /api/provider/services/:id
DELETE /api/provider/services/:id
POST   /api/provider/location      — GPS heartbeat for tracking

GET    /api/bookings/:id/messages
POST   /api/bookings/:id/messages

POST   /api/bookings/group         — group/owambe booking
POST   /api/waitlist

GET    /api/admin/dashboard
PATCH  /api/admin/providers/:id/status
PATCH  /api/admin/payouts/:id

POST   /api/payments/webhook       — Paystack webhook
```

---

## Flutter Screens to Add/Update

| Screen | Action |
|--------|--------|
| `splash_screen.dart` | Premium animation |
| `role_picker_screen.dart` | Customer vs Provider entry |
| `register_screen.dart` | Split customer vs provider forms (CAC) |
| `provider_app_shell.dart` | Separate bottom nav for providers |
| `provider_services_screen.dart` | Add/edit services |
| `booking_screen.dart` | Working note field → API |
| `chat_screen.dart` | In-app chat per booking |
| `wallet_screen.dart` | Realtime balance |
| `welcome_bonus_dialog.dart` | ₦2,000 on signup |

---

## Supabase SQL (phase2.sql)

```sql
alter table khade_users add column if not exists tier text default 'Bronze';
alter table khade_bookings add column if not exists note text;
alter table khade_providers add column if not exists provider_tier text default 'Bronze';
alter table khade_providers add column if not exists cac_number text;
alter table khade_providers add column if not exists business_name text;

create table if not exists khade_messages (
  id int primary key,
  booking_id int references khade_bookings(id),
  sender_id int references khade_users(id),
  body text not null,
  created_at timestamptz default now()
);

create table if not exists khade_provider_locations (
  provider_id int primary key references khade_providers(id),
  lat numeric, lng numeric,
  updated_at timestamptz default now()
);

create table if not exists khade_booking_groups (
  id int primary key,
  lead_user_id int references khade_users(id),
  title text,
  event_date timestamptz,
  status text default 'pending'
);
```

---

## Implementation Order

1. Supabase phase2 migration + full migrate from JSON
2. Auth: split registration, ₦2000 bonus, tiers
3. Role picker + provider app shell (separate nav)
4. Real-time: wallet, notifications, feed (Supabase Realtime)
5. Booking notes + real slots + group booking MVP
6. Provider services CRUD
7. In-app chat + provider GPS tracking
8. Admin web dashboard (Next.js)
9. Fresha parity: CRM, campaigns, staff, analytics
10. Khade Capital (Phase 3)

---

## Testing Checklist

- [ ] Customer signup → ₦2,000 in wallet, Bronze tier, welcome notification
- [ ] Provider signup with CAC → under_review → admin approves → visible in Explore
- [ ] Guest browses without account; prompted to sign in at payment
- [ ] Booking note appears on provider dashboard
- [ ] Provider adds service → shows on customer booking screen
- [ ] Wallet top-up syncs in real time
- [ ] Notification bell updates within 10s of booking
- [ ] Call + WhatsApp work on tracking screen
- [ ] Customer app and Provider app have different bottom navs
- [ ] Admin web: approve provider, approve payout, view revenue

---

## Do NOT

- Rebuild in React Native/Expo
- Use Fresha's 20% marketplace fee (Khade = 10% flat)
- Force account creation to browse
- Require $499 hardware — Paystack + cash only

---

*End of Phase 2 prompt. Point Cursor at `khade2/` and say: "Implement Phase 2 per docs/PHASE2_CURSOR_PROMPT.md, starting with item 1."*
