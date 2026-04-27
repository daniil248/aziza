# Aziza Food

Premium food delivery for Almaty — iOS + Android (Flutter), admin panel, and FastAPI backend in a single, transparent monorepo.

## Structure

```
fooddelivery/
├── api/                   # FastAPI backend (Python, SQLite for dev)
│   ├── app/
│   │   ├── core/          # config, db, security
│   │   ├── models/        # SQLAlchemy entities
│   │   ├── schemas/       # Pydantic request/response shapes
│   │   ├── api/v1/        # HTTP routes
│   │   └── seed/          # demo data loader
│   ├── pyproject.toml
│   └── .env.example
│
├── app/                   # Flutter — ONE codebase, three apps
│   └── lib/
│       ├── core/          # design system, i18n, API client (shared)
│       │   ├── design/    # tokens, theme, typography, widgets
│       │   ├── i18n/      # generated localizations
│       │   ├── api/       # dio client, DTOs
│       │   └── router/
│       ├── features/
│       │   ├── client/    # customer app screens
│       │   ├── courier/   # courier app screens
│       │   └── admin/     # admin panel screens
│       ├── l10n/          # ARB translation files (ru/kk/en)
│       ├── main_client.dart   # entry: customer app
│       ├── main_courier.dart  # entry: courier app
│       └── main_admin.dart    # entry: admin panel
│
└── docs/
    ├── SPEC.md            # full technical specification
    └── PRODUCTION.md      # production migration checklist
```

## Quick start (local)

### 1. Backend

```bash
cd api
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # Linux/Mac
pip install -e .
copy .env.example .env

# seed demo data (creates aziza.db with categories + products)
python -m app.seed.run

# run API
uvicorn app.main:app --reload --port 8000
```

API at http://localhost:8000 — docs at http://localhost:8000/docs

### 2. Flutter (web preview)

```bash
cd app
flutter pub get
flutter run -d chrome -t lib/main_client.dart
```

Other apps:
```bash
flutter run -d chrome -t lib/main_courier.dart   # courier
flutter run -d chrome -t lib/main_admin.dart     # admin
```

## Stack

| Layer | Choice | Why |
|---|---|---|
| Mobile + courier + admin | Flutter 3.41 | one codebase → iOS + Android + Web |
| State management | Riverpod 2 | scoped, no global pollution, testable |
| Routing | go_router | declarative, deep-linkable |
| HTTP | dio | most flexible Dart HTTP client |
| Backend | FastAPI 0.115 | async, fast, type-safe |
| ORM | SQLAlchemy 2 (async) | dialect-agnostic between SQLite/Postgres |
| DB (dev) | **SQLite** | zero-setup, file-based |
| DB (prod) | Postgres | see [docs/PRODUCTION.md](docs/PRODUCTION.md) |
| i18n | Flutter ARB | compiled, no runtime translation lookups |
| Currency | KZT (₸) | stored as integer minor units |

## Languages

- **Russian (ru)** — default
- **Kazakh (kk)**
- **English (en)**

Switch from Profile screen. Persisted across launches.

## Design

- **White / graphite / gold** — see [docs/SPEC.md §4](docs/SPEC.md)
- Inter typography
- Lucide outline icons (1.5 stroke)
- Material 3 base, custom theme overrides

## Production

When ready to ship: see [docs/PRODUCTION.md](docs/PRODUCTION.md). TL;DR — swap `DATABASE_URL` to managed Postgres (Neon), deploy API to Fly.io, deploy Flutter web to Cloudflare Pages, build mobile via App Store / Play Console (iOS via Codemagic CI). No code changes, only env vars.
