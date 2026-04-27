# Aziza Food

Premium food delivery for Almaty — iOS + Android (Flutter), admin panel, FastAPI backend in a single transparent monorepo.

**Live**: https://food.telegbot3td.ru

| Path | What |
|---|---|
| [`/`](https://food.telegbot3td.ru/) | Landing page |
| [`/client/`](https://food.telegbot3td.ru/client/) | Customer app |
| [`/admin/`](https://food.telegbot3td.ru/admin/) | Admin panel — products + photo upload |
| [`/courier/`](https://food.telegbot3td.ru/courier/) | Courier app |
| [`/docs`](https://food.telegbot3td.ru/docs) | API Swagger |

## Structure

```
fooddelivery/
├── api/                   # FastAPI backend (Python)
│   ├── app/
│   │   ├── core/          # config, db, security
│   │   ├── models/        # SQLAlchemy entities
│   │   ├── schemas/       # Pydantic shapes
│   │   ├── api/v1/        # routes (catalog + admin + health)
│   │   └── seed/          # demo data loader
│   └── pyproject.toml
│
├── app/                   # Flutter — ONE codebase, three apps
│   └── lib/
│       ├── core/          # design system, i18n, API client (shared)
│       ├── features/
│       │   ├── client/    # customer screens
│       │   ├── courier/   # courier screens
│       │   └── admin/     # admin screens
│       ├── l10n/          # ARB translations (ru/kk/en)
│       ├── main_client.dart    # entry: customer
│       ├── main_courier.dart   # entry: courier
│       └── main_admin.dart     # entry: admin
│
├── landing/               # Landing page (index.html)
│
├── deploy.sh              # ← one-command deploy from your laptop
│
└── docs/
    ├── SPEC.md            # full technical specification
    ├── INFRA.md           # deployment runbook (read this!)
    └── PRODUCTION.md      # production migration checklist
```

## Stack

| Layer | Tool | Notes |
|---|---|---|
| Mobile + courier + admin | Flutter 3.41 | one codebase → iOS + Android + Web |
| State | Riverpod 2 | scoped, no global pollution |
| Routing | go_router | declarative, deep-linkable |
| HTTP | dio | with bundled-JSON fallback |
| Backend | FastAPI 0.115 | async, type-safe |
| ORM | SQLAlchemy 2 (async) | dialect-agnostic SQLite ↔ Postgres |
| DB (dev + demo) | SQLite | zero-setup, file-based |
| DB (prod) | Postgres | one env var swap, see `docs/PRODUCTION.md` |
| Image upload | FastAPI multipart → `/static/products/` | swap to R2 in prod |
| i18n | Flutter ARB (compiled) | ru / kk / en |
| Currency | KZT (₸) | integer minor units |
| Hosting | VPS Ubuntu 22.04 + nginx + Let's Encrypt | one server, one domain |

## Quick start (local)

```bash
# Backend
cd api
python -m venv .venv
.venv\Scripts\activate
pip install -e .
python -m app.seed.run
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd app
flutter pub get
flutter run -d chrome -t lib/main_client.dart
```

Switch between apps:
```bash
flutter run -d chrome -t lib/main_courier.dart
flutter run -d chrome -t lib/main_admin.dart
```

## Deploy a change

```bash
git push                  # share the source
./deploy.sh               # build + ship + restart (~2-3 minutes)
```

`deploy.sh` builds Flutter web on your machine, ships the static bundles to the VPS via tar+ssh, runs `redeploy.sh` on the server (git pull + Python deps + restart uvicorn), and smoke-tests all endpoints. See [`docs/INFRA.md`](docs/INFRA.md) for everything.

## Languages

Russian (default), Kazakh, English. Switchable from Profile screen, persisted across launches.

## Design

White / graphite / gold (`#D4AF37`). Inter typography. Lucide outline icons. Full spec in [`docs/SPEC.md`](docs/SPEC.md).
