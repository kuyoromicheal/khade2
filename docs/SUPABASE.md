# Supabase setup for Khade

Connect your Khade API to a persistent Supabase PostgreSQL database. Bookings, reviews, and wallet changes survive redeploys (unlike the JSON file on Render free tier).

---

## Cursor ↔ Supabase (automated)

1. **MCP is configured** in `.cursor/mcp.json` for project `lqfzutfhhshditpewedt`
2. Open **Cursor Settings → Tools & MCP** → enable **supabase** → restart Cursor
3. Log in via browser when prompted (one-time OAuth)
4. From now on, ask Cursor: *"Run supabase:status"* or *"Apply phase2-full.sql via MCP"*

Cursor rule: `.cursor/rules/supabase-automation.mdc` (always on for this repo)

---

## NPM automation (from `backend/`)

```powershell
npm run supabase:status    # check all khade_* tables
npm run supabase:migrate   # apply SQL files (needs SUPABASE_DB_URL)
npm run supabase:sync      # migrate + seed data
npm run supabase:setup     # full pipeline
```

---

## 1. Create tables in Supabase

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project
2. Go to **SQL Editor** → **New query**
3. Paste the contents of `backend/supabase/schema.sql`
4. Click **Run**

---

## 2. Get your keys

In Supabase → **Project Settings** → **API**:

| Key | Use |
|-----|-----|
| **Project URL** | `SUPABASE_URL` |
| **service_role** (secret) | `SUPABASE_SERVICE_ROLE_KEY` — backend only, never in Flutter |

The **anon** key is not enough for the backend unless you add write policies. Use **service_role** on Render.

---

## 3. Local `.env`

Add to `backend/.env`:

```env
SUPABASE_URL=https://lqfzutfhhshditpewedt.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...your_service_role_key...
```

Keep your existing Paystack vars. When `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` are set, the API uses Supabase instead of `khade.json`.

---

## 4. Upload your data

```powershell
cd backend
npm run migrate:supabase
```

This copies `khade.deploy.json` (or `khade.json`) into Supabase — providers, services, feed, bookings, etc.

---

## 5. Start the API

```powershell
npm start
```

Check:

```text
http://localhost:3001/health
```

Should return:

```json
{"status":"ok","service":"khade-api","database":"supabase"}
```

---

## 6. Render (production)

In **khade-api** → **Environment**, add:

| Variable | Value |
|----------|--------|
| `SUPABASE_URL` | your project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | service role key |

Save → redeploy. Health check should show `"database":"supabase"`.

---

## How it works

- **Without Supabase env vars** → API uses `backend/data/khade.json` (local dev default)
- **With Supabase env vars** → API reads/writes PostgreSQL tables
- Flutter app unchanged — still calls your REST API at `https://khade-api.onrender.com`

---

## Updating providers after migration

```powershell
cd backend
npm run import:providers
npm run migrate:supabase
```

Or edit data in Supabase Table Editor directly.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Supabase load providers: ...` | Run `schema.sql` first |
| `permission denied` | Use **service_role** key, not anon |
| Empty providers | Run `npm run migrate:supabase` |
| Still shows `"database":"json"` | Restart API after adding env vars |
