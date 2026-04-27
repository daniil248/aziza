# Production migration notes

This project uses **SQLite for local development** because it's zero-setup, file-based, and lets us iterate fast without Docker, Postgres installs, or WSL2 issues.

When we go live (real users on App Store / Play Market), we move to managed services. This document is the migration checklist.

---

## TL;DR

- **Local dev now**: SQLite + `uvicorn` directly. One file `aziza.db`. No Docker. No infrastructure.
- **Production**: managed Postgres (Neon or Supabase), managed Redis (Upstash), API on Fly.io or Railway, Flutter web on Cloudflare Pages, mobile via App Store / Play Console + Codemagic for iOS CI.

The only **code-level change** between dev and prod is the value of `DATABASE_URL` in `.env`. SQLAlchemy's generic `JSON` type handles both backends. Everything else is a deployment concern.

---

## 1. Database — pick a managed Postgres

Recommendation order (most convenient first):

### 🥇 Neon (best free tier, branching, serverless)
- https://neon.tech
- Free: 0.5 GB storage, project never sleeps if it has activity, branching for staging
- Setup: create project → copy connection string → paste into `DATABASE_URL`
- Format: `postgresql+asyncpg://user:pass@host/db`

### 🥈 Supabase
- https://supabase.com
- Free: 500 MB, comes with auth, storage, realtime — useful if we ever want their auth instead of rolling our own
- Pauses after 7 days of inactivity (free tier only)

### 🥉 Render Postgres
- https://render.com
- Free tier expires after 90 days — not great for production

### Self-hosted on a VPS (Hetzner / DigitalOcean)
- ~$4–6/month, full control
- Only worth it past 1000 active users

**To switch:** install prod extras and update env.

```bash
# install Postgres driver
pip install ".[prod]"

# in .env, replace SQLite line with:
DATABASE_URL=postgresql+asyncpg://USER:PASS@HOST:5432/aziza
```

That's it. SQLAlchemy + Pydantic handle everything else identically.

---

## 2. Migrations

Right now we use `Base.metadata.create_all` on app startup — fine for dev, **NOT for prod** (it cannot evolve schema safely).

Before launch:
1. `alembic init alembic`
2. `alembic revision --autogenerate -m "initial"`
3. Commit migration files
4. Replace startup `create_all` with `alembic upgrade head` (already wired in API container if added)

This is one afternoon's work — defer until we have real data.

---

## 3. Cache + realtime — Redis

Used for: OTP storage, rate limiting, live courier location pubsub, websocket fanout.

- **Upstash** — https://upstash.com — free tier with 10k commands/day, REST + native Redis API. Works with our `redis-py` client unchanged.
- **Self-hosted** on the API VPS if we go that route.

Not needed in dev (we don't have OTP / live tracking yet locally).

---

## 4. API hosting

### 🥇 Fly.io
- Native Postgres-friendly, low cold-start, $0–5/month for our scale
- Single `fly.toml` + `Dockerfile` (we'll add when we deploy)
- Multi-region if we want Almaty edge presence

### 🥈 Railway
- Easiest first deploy: connect GitHub, it figures out Python
- $5 free credit, then pay-as-you-go

### 🥉 Render
- Web service free tier, spins down after 15 min idle (cold start ~30 s)

---

## 5. Web preview (Flutter web build)

We deploy the Flutter web build to a static host. Same code as mobile, just compiled differently.

### Cloudflare Pages (recommended)
- 100% free, unlimited bandwidth
- GitHub-driven or direct upload of `app/build/web/`
- Custom domain free

### Netlify
- Comparable, drag-drop deploy works for first preview

### Surge.sh
- Simplest CLI deploy: `surge ./build/web` → instant URL, no GitHub

Build command: `cd app && flutter build web --release --dart-define=API_BASE_URL=https://api.aziza.kz`

---

## 6. Mobile builds (App Store / Play Market)

### Android (works on Windows)
- `flutter build appbundle --release`
- Upload `.aab` to Play Console
- Cost: $25 one-time developer fee

### iOS (requires macOS or CI)
- **Codemagic** — https://codemagic.io — free 500 min/month of macOS build minutes, enough for a few releases
- Or rent a Mac mini in cloud (`MacInCloud` ~$30/month)
- Cost: $99/year Apple Developer Program

We'll wire Codemagic when ready to submit. Their config sits in `codemagic.yaml` at repo root.

---

## 7. Payments (Kazakhstan-specific)

Required: legal entity (TOO/ИП).

- **Kaspi Pay** — most popular Kazakh wallet, has REST API, requires merchant agreement
- **Halyk acquiring** — bank acquiring for cards, also requires merchant agreement
- **Stripe** — works for international cards, easier integration but takes higher fees and KZT not natively supported (forces USD/EUR conversion)

For Apple Pay / Google Pay on cards — uses the same acquiring channel, no separate setup beyond enabling in Stripe / Halyk dashboard.

---

## 8. SMS (real OTP, not the email magic-link stub)

- **Mobizon** — https://mobizon.kz — Kazakh provider, ₸4–6 per SMS
- **SMSC.kz** — alternative
- Both: REST API, easy `httpx` integration

---

## 9. Maps & geocoding (Almaty-first)

- **2GIS Flutter SDK** — https://docs.2gis.com — best Almaty coverage, free tier generous
- **Yandex Maps** — also good in Kazakhstan, free for small apps
- Avoid Google Maps in Kazakhstan — sparse data on small streets

---

## 10. Image storage

Right now: no uploads (catalog uses placeholder gradients).

Production:
- **Cloudflare R2** — S3-compatible, no egress fees, ~$0.015/GB/month — cheapest by far
- **Backblaze B2** — even cheaper for storage, has egress costs
- Self-hosted **MinIO** if we want full control

API code change: swap local placeholder with R2 presigned upload URL — ~50 LOC behind a clean interface.

---

## Migration order (when ready)

1. Pick managed Postgres (Neon recommended) → migrate data → swap `DATABASE_URL` ✅ schema unchanged
2. Add Alembic, capture initial migration ✅ blocks future schema changes from breaking prod
3. Deploy API to Fly.io with that DB URL ✅ public API
4. Build Flutter web with prod API URL → Cloudflare Pages ✅ public web preview
5. Add Upstash Redis when introducing OTP/realtime tracking
6. Add R2 when adding admin product image upload
7. Wire Codemagic when ready for App Store
8. Apply for legal entity → wire Kaspi/Halyk → real payments

Everything is **independent**. No big bang migration — flip pieces one at a time.
