# Aziza Food — infrastructure runbook

Single source of truth: **GitHub** ([github.com/daniil248/aziza](https://github.com/daniil248/aziza)).
Everything below is built **from `main` branch**. Never edit on the server. Never deploy local builds.

---

## Topology

```
GitHub  github.com/daniil248/aziza
   │
   ├── Netlify (frontend)        Auto-deploys on every push to main.
   │   azizza.netlify.app
   │   Build: bash netlify-build.sh → public/ → deployed.
   │
   ├── VPS 92.51.44.138 (backend)  Manual update: ./redeploy.sh on server.
   │   /root/aziza  (git working copy)
   │   systemd unit: aziza-api.service  →  uvicorn on 127.0.0.1:8765
   │   nginx server block:  <subdomain> → proxy_pass http://127.0.0.1:8765
   │   Let's Encrypt cert via certbot
   │
   └── App Store / Play Console (mobile, Phase 2)
       Built via Codemagic (iOS) and locally / GitHub Actions (Android)
```

---

## Frontend (Netlify)

- **Source**: `app/lib/main_client.dart`, `main_admin.dart`, `main_courier.dart` + `deploy/index.html`
- **Build script**: [`netlify-build.sh`](../netlify-build.sh) — clones Flutter stable, builds 3 web apps, assembles `public/`
- **Deploy trigger**: every `git push` to `main` → Netlify webhook → rebuild
- **Live URLs**:
  - `/` — landing page with 3 buttons
  - `/client/` — customer app
  - `/admin/` — admin panel
  - `/courier/` — courier app
- **Backend URL injection**: build environment variable `API_BASE_URL` (Netlify Site Settings → Environment Variables, OR pinned in `netlify.toml`). Read in Flutter via `String.fromEnvironment('API_BASE_URL')`.
- **Site ID**: `90d416c3-e12e-4f4c-a60e-9a56cba3d980` (URL `https://azizza.netlify.app`)

To force rebuild without code change: Netlify dashboard → Deploys → **Trigger deploy → Clear cache and deploy**.

---

## Backend (VPS)

- **Server**: `92.51.44.138` (Ubuntu 22.04)
- **Path**: `/root/aziza` (git clone of main)
- **Service**: `aziza-api.service` (systemd) — runs `uvicorn` on `127.0.0.1:8765`
- **Database**: SQLite `/root/aziza/api/aziza.db` (file-based, persisted across restarts)
- **Image uploads**: `/root/aziza/api/static/products/<uuid>.<ext>` (served via FastAPI's StaticFiles at `/static/...`)
- **Public URL**: `https://<subdomain>` (TBD — set after DNS) — nginx proxies → uvicorn
- **TLS**: Let's Encrypt via certbot, auto-renewal via cron

### Update backend (after a push to GitHub)

SSH to server then:
```bash
/root/aziza/redeploy.sh
```

Equivalent of:
```bash
cd /root/aziza
git pull --ff-only
cd api
.venv/bin/pip install -e . --quiet
systemctl restart aziza-api
```

The script also tails the latest log lines so you can confirm it started cleanly.

### Inspect / debug

```bash
systemctl status aziza-api          # current state
journalctl -u aziza-api -f          # live log
journalctl -u aziza-api -n 100      # last 100 lines

curl http://127.0.0.1:8765/api/v1/health           # local healthcheck
curl https://<subdomain>/api/v1/health             # via nginx
```

### Reset database (dev only — wipes orders, products, uploads)

```bash
systemctl stop aziza-api
rm /root/aziza/api/aziza.db
rm -rf /root/aziza/api/static/products/*
cd /root/aziza/api
.venv/bin/python -m app.seed.run
systemctl start aziza-api
```

---

## Local development

```bash
# Backend (one-time)
cd api
python -m venv .venv
.venv/Scripts/activate     # Windows
pip install -e .
python -m app.seed.run
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd app
flutter pub get
flutter run -d chrome -t lib/main_client.dart
```

The Flutter app auto-detects `localhost:8000` for web builds and falls back to bundled JSON snapshots in `assets/demo/` if the API is unreachable. So even with backend down, the catalog is browsable for design demo.

---

## What is NOT in git

These are **runtime state**, regenerated locally / on server:
- `api/.venv/` — Python virtualenv
- `api/aziza.db` — SQLite database
- `api/static/products/` — uploaded images
- `app/.dart_tool/`, `app/build/` — Flutter caches and build output
- `app/deploy/` — local pre-build artifact (only Netlify produces the canonical build)
- `app/aziza-food-deploy.zip` — local zip for manual drop deploys
- `*.env`, `*.key`, `secrets/` — secrets

`.gitignore` enforces this.

---

## Versioning + sync guarantees

- Frontend version = `git rev-parse HEAD` in Netlify build log
- Backend version = `git rev-parse HEAD` in `/root/aziza` (run `cd /root/aziza && git rev-parse HEAD`)
- They should match after any push + redeploy

To verify in sync:
```bash
# locally
git rev-parse main

# server backend
ssh root@92.51.44.138 'cd /root/aziza && git rev-parse HEAD'

# frontend (open dashboard or DevTools network tab → check `commit_ref` in Netlify deploy)
curl -s https://api.netlify.com/api/v1/sites/<SITE_ID>/deploys?per_page=1 | jq -r '.[0].commit_ref'
```

If they diverge: push to GitHub first, then run `redeploy.sh` on server. Netlify catches up automatically.
