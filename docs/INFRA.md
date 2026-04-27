# Aziza Food — infrastructure runbook

**Single source of truth: GitHub** ([github.com/daniil248/aziza](https://github.com/daniil248/aziza)).
Everything below is built **from `main` branch**. Never edit on the server.

---

## Topology

```
GitHub  github.com/daniil248/aziza
   │
   │  push to main
   ▼
Developer machine                     ← Flutter compile happens HERE
   ├── git pull
   ├── flutter build web (×3)         ← 2-3 GB RAM, takes ~2 min
   └── ./deploy.sh
       │
       │  tar+ssh + ssh redeploy.sh
       ▼
VPS  92.51.44.138  (3.8 GB RAM, shared with other tenants)
   │
   ├── /root/aziza/         ← git working copy (lightweight)
   │   ├── api/             ← FastAPI source
   │   ├── landing/         ← landing index.html
   │   └── redeploy.sh      ← backend-only redeploy
   │
   ├── /var/www/aziza/      ← static (overwritten by deploy.sh)
   │   ├── index.html
   │   ├── client/, admin/, courier/   ← Flutter web bundles
   │
   ├── systemd: aziza-api.service
   │   uvicorn  →  127.0.0.1:8765
   │   SQLite at /root/aziza/api/aziza.db
   │   uploads to /root/aziza/api/static/products/
   │
   └── nginx: /etc/nginx/sites-enabled/food.telegbot3td.ru
       https://food.telegbot3td.ru  (Let's Encrypt, auto-renewal)
       Routes:
         /                    → /var/www/aziza/index.html
         /{client,admin,courier}/  → static + SPA fallback
         /api/*               → 127.0.0.1:8765
         /static/*            → 127.0.0.1:8765 (uploaded images)
         /docs                → 127.0.0.1:8765 (Swagger)
```

**Why the build happens locally, not on the VPS:** Flutter's release web compile uses 2-3 GB of RAM. The VPS has 3.8 GB shared with other tenants (telegram bots, other sites). Compiling on the server starves them out. Local build, then rsync the static result — the proven pattern.

---

## Live URLs

| Path | Purpose |
|---|---|
| https://food.telegbot3td.ru/ | Landing page with 3 buttons |
| https://food.telegbot3td.ru/client/ | Customer mobile-first app |
| https://food.telegbot3td.ru/admin/ | Admin panel (full CRUD + photo upload) |
| https://food.telegbot3td.ru/courier/ | Courier app |
| https://food.telegbot3td.ru/api/v1/health | API health probe |
| https://food.telegbot3td.ru/docs | Swagger UI |

---

## Update flow (the only command you need)

After pushing changes to GitHub:

```bash
./deploy.sh
```

This runs **on your machine** and does:

1. `flutter pub get`
2. Build 3 web bundles (client / admin / courier) — verifies `main.dart.js` exists in each
3. tar+ssh the bundles to `$SERVER:/var/www/aziza/`
4. SSH to server → run `redeploy.sh` (which does `git pull` + python deps + `systemctl restart aziza-api`)
5. Smoke-test all endpoints (must return 200)

Total time: **~2-3 minutes**. Idempotent — safe to re-run.

Override defaults via env:
```bash
AZIZA_SERVER=root@1.2.3.4 AZIZA_DOMAIN=example.com FLUTTER=/path/to/flutter ./deploy.sh
```

---

## Update only backend (no Flutter changes)

```bash
ssh root@92.51.44.138 '/root/aziza/redeploy.sh'
```

This pulls main + restarts uvicorn. Takes ~5 seconds.

---

## Inspect / debug

```bash
ssh root@92.51.44.138

# Backend
systemctl status aziza-api
journalctl -u aziza-api -f
journalctl -u aziza-api -n 100

# nginx
nginx -t && systemctl reload nginx
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
.venv\Scripts\activate          # Windows; source .venv/bin/activate on Linux/Mac
pip install -e .
python -m app.seed.run
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd app
flutter pub get
flutter run -d chrome -t lib/main_client.dart
```

The Flutter app on web in **debug** mode hits `http://localhost:8000`. In **release** mode it uses **relative URLs** (`/api/v1`) — same-origin, the way it works in production.

---

## What is NOT in git

These are **runtime state**, regenerated locally / on server:
- `api/.venv/` — Python virtualenv
- `api/aziza.db` — SQLite database (server has its own)
- `api/static/products/` — uploaded images
- `app/.dart_tool/`, `app/build/` — Flutter caches and build output
- `app/deploy/`, `app/aziza-food-deploy.zip` — legacy local pre-build (no longer used)
- `*.env`, `*.key`, `secrets/` — secrets

`.gitignore` enforces this.

---

## Versioning + sync

- **Backend version** = `git rev-parse HEAD` in `/root/aziza` (printed by `redeploy.sh`)
- **Frontend version** = same — `deploy.sh` runs `redeploy.sh` after shipping bundles, so backend + frontend always come from the same commit

Verify in sync:
```bash
git rev-parse main                                     # local
ssh root@92.51.44.138 'cd /root/aziza && git rev-parse HEAD'   # server
```

If they diverge: someone edited on the server (don't). `git stash && git pull && ./deploy.sh` recovers.

---

## Cert renewal

Let's Encrypt for `food.telegbot3td.ru` auto-renews via `certbot.timer` (system-wide). Force-test:
```bash
certbot renew --dry-run
```

Renewal modifies cert files — nginx picks them up automatically.

---

## ⚠️ Do not install Flutter SDK on the VPS

A previous version of `redeploy.sh` ran `flutter build` on the server. This consumed all RAM and starved the user's other sites (telegbot3td.ru, develophub.pro etc) for ~30 minutes. **Don't.**

Build locally → ship the static output. The VPS only serves files and runs uvicorn (~110 MB combined footprint).

---

## Production-grade upgrades (when scaling beyond demo)

- **DB**: SQLite → managed Postgres. Change `DATABASE_URL` env in `aziza-api.service`, restart.
- **Image storage**: local `/root/aziza/api/static/` → Cloudflare R2 (presigned URLs).
- **Auth**: currently OTP screens are mocked. Wire SMS via Mobizon / SMSC.kz when ready.
- **Payments**: Kaspi / Halyk / Apple Pay — requires legal entity.
- **iOS build**: Codemagic CI from this repo (`codemagic.yaml`) — needs Apple Developer Program ($99/year).
- **Android build**: `flutter build appbundle --release` locally, upload to Play Console.

See [docs/PRODUCTION.md](PRODUCTION.md) for the full migration checklist.
