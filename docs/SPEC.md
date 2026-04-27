# Aziza Food — Technical Specification

**Version:** 0.1 (initial draft)
**Date:** 2026-04-27
**Status:** active

---

## 1. Vision

Aziza Food — premium food-delivery service in Almaty specializing in Central Asian home cuisine (manty, pelmeni, samsa, sauces). Differentiator: subscription model with free delivery + flat discount, premium minimalist design, fully native experience on iOS and Android.

## 2. Goals

- **Primary:** Native mobile applications published on App Store and Google Play
- **Secondary:** Identical web preview (same Flutter codebase compiled to web) for stakeholder review
- **Tertiary:** Internal admin web panel for operators

## 3. Non-functional requirements

| Requirement | Target |
|---|---|
| Cold start (mobile) | ≤ 2 s on mid-range Android |
| Catalog scroll FPS | 60 fps sustained |
| API p95 latency | ≤ 150 ms (within Almaty region) |
| Time-to-first-byte (web preview) | ≤ 500 ms |
| Image bandwidth | progressive WebP/AVIF, blurhash placeholders |
| State management | per-feature scoped Riverpod providers; no global Redux store |
| Offline-tolerance | catalog cached; cart persisted locally |
| Languages | ru (default), kk, en — switchable from Settings, persisted |
| Currency | KZT, integer minor units (tïïn) in DB |

## 4. Design system

### 4.1 Palette
| Token | HEX | Usage |
|---|---|---|
| `surface.base` | `#FFFFFF` | screen background |
| `surface.muted` | `#F5F5F5` | cards, sections |
| `text.primary` | `#2C2C2C` | headings, body |
| `text.secondary` | `#7A7A7A` | hints, meta |
| `accent.gold` | `#D4AF37` | CTAs, active states |
| `accent.gold.pressed` | `#B5942C` | pressed CTA |
| `premium.bg` | `#1A1A1A` | dark inverted (subscription screen) |
| `premium.text` | `#FFFFFF` | text on premium bg |
| `state.success` | `#4A7C59` | order delivered |
| `state.warn` | `#C77C2D` | warnings |
| `state.error` | `#A23E3E` | errors |
| `divider` | `#EAEAEA` | thin separators |

### 4.2 Typography
- **Font:** Inter (variable) — weights 400/500/600/700
- Display 32 / Bold — screen titles
- Title 22 / SemiBold — section headers
- Body 16 / Regular — paragraphs
- Caption 13 / Medium — meta, badges

### 4.3 Iconography
- **Lucide** outline icons, 1.5 stroke
- Default: `text.primary`; active: `accent.gold`

### 4.4 Components
- Buttons: 48 dp height, 10 dp radius, gold fill primary, ghost secondary
- Cards: 16 dp padding, no border, soft shadow only on hover/press
- Lists: separators `divider` 1 dp
- Inputs: 48 dp, no border, `surface.muted` fill, gold focus ring

### 4.5 Motion
- Transitions: 200 ms cubic-bezier(0.2, 0, 0, 1)
- No parallax, no decorative animation; only functional feedback

## 5. Domain model

### 5.1 Entities

```
User
  id, phone, email, name, avatar_url, role (client|courier|admin),
  default_address_id, locale, created_at
  
Address
  id, user_id, label (home|work|custom), street, building, apt, entrance,
  floor, comment, lat, lng, is_default

Category
  id, slug, sort, name_i18n {ru,kk,en}, image_url

Product
  id, slug, category_id, name_i18n, description_i18n, ingredients_i18n,
  cooking_i18n, kbju (kcal/protein/fat/carb per 100g),
  variants: [{label_i18n, weight_g, price_minor}], main_image_url,
  gallery_urls[], is_active, sort

Order
  id, code (human ABC-1234), client_id, address_id, status
    (pending|confirmed|preparing|courier_assigned|in_transit|delivered|cancelled),
  items: [{product_id, variant_label, qty, unit_price_minor, total_minor}],
  subtotal_minor, delivery_fee_minor, discount_minor, total_minor,
  promo_code, payment_method, payment_status, courier_id,
  scheduled_for, comment, created_at, updated_at

CourierLocation
  courier_id, lat, lng, heading, updated_at  (live, in Redis)

Subscription
  id, user_id, plan (monthly|yearly), price_minor,
  status (active|cancelled|expired), benefits {free_delivery, discount_pct, gift},
  started_at, current_period_end, auto_renew

Promo
  id, code, type (percent|amount|free_delivery), value, valid_from, valid_to,
  max_uses, uses_count, min_order_minor

Push
  id, segment (all|subscribers|inactive), title_i18n, body_i18n, scheduled_for, sent_at
```

### 5.2 Money

All prices stored as `BIGINT` minor units (1 ₸ = 100 tïïn for math symmetry, even though tïïn aren't actively used in commerce). UI formats with `Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT' })`.

### 5.3 i18n storage

Translatable fields are `JSONB` with `{ru, kk, en}` keys. Fallback chain: requested → ru → first non-null.

## 6. API surface (v1)

### 6.1 Auth (mobile uses SMS in prod; web preview uses email magic-link OR demo login)

```
POST /api/v1/auth/request-otp  { phone | email }
POST /api/v1/auth/verify-otp   { phone|email, code }  -> { access, refresh, user }
POST /api/v1/auth/refresh      { refresh }            -> { access, refresh }
POST /api/v1/auth/logout
GET  /api/v1/auth/me
```

### 6.2 Catalog (public)

```
GET /api/v1/categories
GET /api/v1/products?category=&q=&limit=&offset=
GET /api/v1/products/{slug}
```

### 6.3 Cart & checkout

```
GET    /api/v1/cart
POST   /api/v1/cart/items       { product_id, variant_label, qty }
PATCH  /api/v1/cart/items/{id}  { qty }
DELETE /api/v1/cart/items/{id}
POST   /api/v1/cart/clear

POST   /api/v1/orders            { address_id, scheduled_for, comment, promo, payment_method }
GET    /api/v1/orders            list current user's orders
GET    /api/v1/orders/{id}
POST   /api/v1/orders/{id}/cancel
POST   /api/v1/orders/{id}/repeat
```

### 6.4 Subscription

```
GET    /api/v1/subscription/plans
GET    /api/v1/subscription/me
POST   /api/v1/subscription/subscribe  { plan }
POST   /api/v1/subscription/cancel
```

### 6.5 Address book

```
GET/POST/PATCH/DELETE /api/v1/addresses[/{id}]
```

### 6.6 Realtime tracking

```
WS /api/v1/orders/{id}/track   -> { status, courier: {lat, lng, heading}, eta_min }
```

### 6.7 Courier

```
GET  /api/v1/courier/orders/active
POST /api/v1/courier/orders/{id}/pickup
POST /api/v1/courier/orders/{id}/deliver
POST /api/v1/courier/location  { lat, lng, heading }
```

### 6.8 Admin

```
GET/POST/PATCH/DELETE /api/v1/admin/products[/{id}]
GET/POST/PATCH/DELETE /api/v1/admin/categories[/{id}]
GET/PATCH             /api/v1/admin/orders[/{id}]
POST                  /api/v1/admin/orders/{id}/assign-courier
GET                   /api/v1/admin/users
GET                   /api/v1/admin/subscriptions
GET                   /api/v1/admin/analytics/sales      ?from&to&granularity
GET                   /api/v1/admin/analytics/products
GET                   /api/v1/admin/analytics/subscribers
GET/POST/DELETE       /api/v1/admin/promos[/{id}]
GET/POST              /api/v1/admin/push[/{id}]
```

## 7. Mobile app — screens (client)

1. **Splash** — logo, while resolving session
2. **Onboarding** (first run) — 3 slides, language picker, "Continue"
3. **Auth** — phone input → OTP screen (mobile); email magic-link or demo (web preview)
4. **Home** — greeting + premium badge if subscriber, hero carousel (3-4 top products), category chips, recommended grid
5. **Catalog** — category list / grid, filter chip row, product cards
6. **Product detail** — gallery, name, weight/qty selector, KBJU, ingredients, description, "Add to cart" CTA
7. **Cart** — line items with qty stepper, promo input, delivery time selector, comment, total breakdown, "Checkout"
8. **Checkout** — address picker, payment method (card stub for now), confirm
9. **Order tracking** — status timeline, map with courier pin, ETA, contact courier
10. **Subscription** — premium dark screen, plan toggle (Monthly/Yearly with savings badge), benefits list, "Subscribe" CTA
11. **Profile** — name, addresses, orders history, subscription status, language, support, logout

## 8. Mobile app — screens (courier)

1. **Auth** — phone + OTP
2. **Active orders** — list of assigned orders
3. **Order detail** — items, address, customer phone (masked), "Picked up" / "Delivered" CTAs, route button
4. **Map view** — route to current order

## 9. Admin panel — screens

1. **Login**
2. **Dashboard** — KPIs: today's orders, revenue, active subscribers, top products
3. **Products** — table with search/filter, edit drawer (i18n fields, variants, gallery)
4. **Categories**
5. **Orders** — table, status filter, detail drawer with courier assignment
6. **Users** — table
7. **Subscriptions** — list with churn metrics
8. **Promo codes**
9. **Push** — composer with segment + i18n body
10. **Analytics** — charts: sales/day, top products, AOV, subscriber growth

## 10. Tech architecture

### 10.1 Backend

- **FastAPI** with async stack, uvicorn workers
- **SQLAlchemy 2 async** + **asyncpg**
- **Alembic** migrations versioned in repo
- **Pydantic v2** for schemas
- **JWT** access (15 min) + refresh (30 d) — refresh stored in HTTP-only cookie or secure storage on device
- **Argon2** for any password (admin login fallback)
- **Redis** for: rate limit, OTP store (5-min TTL), live courier location, websocket pub/sub
- Background tasks via **Arq** (async Redis-backed) for: send push, expire subscriptions, mark stale orders
- **OpenTelemetry** ready hooks (no vendor lock)

### 10.2 Flutter

```
lib/
  core/
    api/             dio client, interceptors, retrofit clients
    auth/            session repo, token storage
    design/          tokens (color, typo, spacing), widgets, theme
    i18n/            generated AppLocalizations + ARB
    money/           Money value object, formatter
    router/          go_router config (per app)
    utils/
  features/
    client/
      home/          screen + controller (Riverpod) + widgets
      catalog/
      product/
      cart/
      checkout/
      subscription/
      tracking/
      profile/
    courier/
      orders/
      route/
    admin/
      products/
      orders/
      users/
      analytics/
      ...
  main_client.dart
  main_courier.dart
  main_admin.dart
```

- **Riverpod 2** with code-generated providers (`@riverpod`)
- **freezed** + `json_serializable` for immutable models
- **dio** + **retrofit** for typed API client
- **go_router** per-app router instance
- **flutter_intl / arb** for translations
- **cached_network_image** with blurhash placeholders
- Forms: `flutter_hooks` for ergonomics where useful (kept minimal)

### 10.3 Local infrastructure

`infra/docker-compose.yml` brings up:
- `postgres:16-alpine` on 5432 (volume-mounted)
- `redis:7-alpine` on 6379
- `api` (FastAPI) on 8000 with hot reload (volume-mount of `api/`)

Single command: `docker compose up -d`. Health endpoint: `GET /health`.

### 10.4 Production deployment (out of scope phase 1, planned)

- API: Fly.io or Hetzner VPS + Caddy
- DB: managed Postgres (Neon free tier or Supabase)
- Static (web preview): Cloudflare Pages
- iOS/Android: App Store, Play Console
- iOS CI from Windows: Codemagic with macOS runners

## 11. Security

- Token rotation on refresh
- OTP rate limit: 1/min per phone, 5/h per IP
- Strict CORS (mobile uses no origin, web preview only from configured domain)
- Input validation: Pydantic strict mode
- SQL: parametrized via SQLAlchemy core
- Secrets: env vars only, never committed; `.env.example` checked in
- Image uploads (admin): MIME + size validation, server-side resize, S3-compatible storage in prod (R2/MinIO local)

## 12. Data privacy

- Phone numbers PII — masked in courier views (last 2 digits visible)
- GDPR-style export/delete endpoint planned for App Store compliance
- Analytics anonymous on device until login

## 13. Testing strategy

- Backend: `pytest` + `pytest-asyncio` + httpx test client; ≥80% coverage on services
- Flutter: `flutter_test` for widgets, `mocktail` for mocks, golden tests for design system primitives
- E2E: deferred to phase 2

## 14. Phasing

**Phase 1 (in progress):**
- Monorepo skeleton ✅
- SPEC ✅
- Docker compose, FastAPI skeleton with auth + catalog + orders ✅
- Seed demo data ✅
- Flutter project with design system + i18n ✅
- Client app: home, catalog, product, cart (full)
- Admin: dashboard, products list (read-only)

**Phase 2:**
- Checkout, subscription, profile, tracking on client
- Full admin CRUD + analytics
- Courier app
- Real auth (SMS via provider)
- Real payment (Kaspi/Halyk/Stripe)
- iOS CI on Codemagic
- Production deploy

## 15. Open questions (track as they arise)

- SMS provider (Mobizon? SMSC.kz?) — needs juridical entity contract
- Map provider — 2GIS Flutter SDK preferred for Almaty
- Image storage provider for prod
