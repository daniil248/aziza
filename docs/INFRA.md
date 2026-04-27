# Aziza Food — infrastructure runbook

**Single source of truth: GitHub** ([github.com/daniil248/aziza](https://github.com/daniil248/aziza)).
Everything below is built **from `main` branch**. Never edit on the server. Never deploy local builds.

---

## Topology

```
GitHub  github.com/daniil248/aziza
   │
   │  git push (your laptop → main)
   ▼
VPS  92.51.44.138  (single host, single domain)
   │
   ├── /root/aziza            ← git working copy (pulled by redeploy.sh)
   │   ├── api/               ← FastAPI source
   │   ├── app/               ← Flutter source (3 apps from one codebase)
   │   ├── landing/           ← landing page (index.html)
   │   ├── docs/              ← SPEC, INFRA, PRODUCTION
   │   └── redeploy.sh        ← one-command rebuild + restart
   │
   ├── /var/www/aziza/        ← built static (served by nginx)
   │   ├── index.html         ← landing
   │   ├── client/            ← Flutter web — customer
   │   ├── admin/             ← Flutter web — admin (CRUD + photo upload)
   │   └── courier/           ← Flutter web — courier
   │
   ├── /opt/flutter/          ← Flutter SDK (stable, used by redeploy.sh)
   │
   ├── systemd: aziza-api.service
   │   ExecStart: /root/aziza/api/.venv/bin/uvicorn app.main:app
   │              --host 127.0.0.1 --port 8765
   │   uses SQLite at /root/aziza/api/aziza.db
   │   uploads to /root/aziza/api/static/products/<uuid>.<ext>
   │
   └── nginx: /etc/nginx/sites-enabled/food.telegbot3td.ru
       Public domain:  https://food.telegbot3td.ru
       Cert:           Let's Encrypt (auto-renewal via certbot.timer)
       Routes:
         /                    → /var/www/aziza/index.html (landing)
         /client/  /admin/  /courier/  → Flutter web SPAs
         /api/*               → 127.0.0.1:8765
         /static/*            → 127.0.0.1:8765 (uploaded images)
         /docs                → 127.0.0.1:8765 (Swagger UI)
```

**Why this layout:** frontend and backend share one origin. No CORS. No mixed content. One deploy command. One source of truth.

---

## Live URLs

| Path | Purpose |
|---|---|
| https://food.telegbot3td.ru/ | Landing page with 3 buttons |
| https://food.telegbot3td.ru/client/ | Customer mobile-first app |
| https://food.telegbot3td.ru/admin/ | Admin panel (full CRUD + photo upload) |
| https://food.telegbot3td.ru/courier/ | Courier app |
| https://food.telegbot3td.ru/api/v1/health | API health probe |
| https://food.telegbot3td.ru/docs | Swagger UI (FastAPI auto-generated) |

---

## Update flow (after any change)

1. **On your laptop:** edit code → commit → push to `main`.
2. **On the server:** run one command:
   ```bash
   ssh root@92.51.44.138 '/root/aziza/redeploy.sh'
   ```

`redeploy.sh` does:
1. `git pull` (latest main)
2. Update Python deps (`pip install -e .`)
3. Rebuild all 3 Flutter web apps **into a temp dir**, then **atomically swap** with `/var/www/aziza/` — users never see a half-built site
4. `systemctl restart aziza-api`
5. Print last commit + live URLs

A full redeploy takes **~3-5 minutes** (Flutter rebuild dominates).

---

## Inspect / debug

```bash
ssh root@92.51.44.138

# Backend
systemctl status aziza-api          # current state
journalctl -u aziza-api -f          # live log
journalctl -u aziza-api -n 100      # last 100 lines

# nginx
nginx -t                            # test config
systemctl reload nginx              # apply config without dropping conns
tail -f /var/log/nginx/access.log

# Quick smoke
curl https://food.telegbot3td.ru/api/v1/health
curl https://food.telegbot3td.ru/api/v1/categories | jq
```

---

## Reset database (dev/demo only — wipes orders, products, uploads)

```bash
ssh root@92.51.44.138 <<'EOF'
systemctl stop aziza-api
rm /root/aziza/api/aziza.db
rm -rf /root/aziza/api/static/products/*
cd /root/aziza/api && .venv/bin/python -m app.seed.run
systemctl start aziza-api
EOF
```

---

## Local development (no server needed)

```bash
# Backend
cd api
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -e .
python -m app.seed.run
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd app
flutter pub get
flutter run -d chrome -t lib/main_client.dart
```

The Flutter app on web in **debug** mode hits `http://localhost:8000`. In **release** mode it uses **relative URLs** (`/api/v1`) — same-origin, the way it works in production.

To target a remote API from a local web build:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://food.telegbot3td.ru -t lib/main_client.dart
```

---

## What is NOT in git

These are **runtime state**, regenerated locally / on server:
- `api/.venv/` — Python virtualenv
- `api/aziza.db` — SQLite database
- `api/static/products/` — uploaded images
- `app/.dart_tool/`, `app/build/` — Flutter caches and build output
- `app/deploy/`, `app/aziza-food-deploy.zip` — legacy local pre-build (no longer used)
- `*.env`, `*.key`, `secrets/` — secrets

`.gitignore` enforces this.

---

## Versioning + sync guarantees

- **Backend version** = `git rev-parse HEAD` in `/root/aziza`
- **Frontend version** = same — both rebuilt from the same commit by `redeploy.sh`
- **They cannot drift** — single rebuild path, atomic swap

To verify in sync:
```bash
# locally
git rev-parse main

# server (both backend and frontend run from this commit)
ssh root@92.51.44.138 'cd /root/aziza && git rev-parse HEAD'
```

If they diverge: someone edited on the server (don't). Run `git stash && git pull && /root/aziza/redeploy.sh` to recover.

---

## Cert renewal

Let's Encrypt cert for `food.telegbot3td.ru` auto-renews via the system-installed `certbot.timer`. To force test:
```bash
certbot renew --dry-run
```

Renewal modifies cert files only — nginx picks them up via reload (handled by certbot's deploy hooks).

---

## Production-grade upgrades (when scaling beyond demo)

- **DB**: SQLite → managed Postgres (Neon / Supabase / self-hosted on same VPS via existing `localhost:5432`). Change `DATABASE_URL` in `aziza-api.service`, restart.
- **Image storage**: local `/root/aziza/api/static/` → Cloudflare R2 (presigned URLs). Trivially swappable behind one upload service.
- **Auth**: currently OTP screens are mocked. Wire SMS via Mobizon / SMSC.kz when ready.
- **Payments**: Kaspi / Halyk / Apple Pay — requires legal entity.
- **iOS build**: Codemagic CI from this repo (`codemagic.yaml`) — needs Apple Developer Program ($99/year).
- **Android build**: `flutter build appbundle --release` locally, upload to Play Console ($25 one-time).

See [docs/PRODUCTION.md](PRODUCTION.md) for the full migration checklist.
