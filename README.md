# Ticketly — Voice-Enabled Multi-Modal Ticketing Platform (Bangladesh)

A voice-controlled ticketing aggregator for the Bangladeshi transport ecosystem.
Users search, compare and book **train / bus / launch / flight** tickets using natural
Bengali or Banglish voice commands, while the platform automatically applies the most
cost-effective price: MFS cashback (bKash, Nagad, Rocket), bank offers and promo codes.

> "আগামী শুক্রবার ঢাকা থেকে খুলনার সবচেয়ে কম ভাড়ার টিকিট দেখাও"

---

## Architecture

```
                       ┌──────────────────────────────────────────────┐
   Flutter app ───────▶│  api-gateway  :8080                          │
   (voice + UI)        │  routing · CORS · rate limit · JWT validate  │
                       └───┬──────┬──────┬──────┬──────┬──────┬───────┘
                           │      │      │      │      │      │
              ┌────────────┘      │      │      │      │      └─────────────┐
              ▼                   ▼      ▼      ▼      ▼                   ▼
      ┌──────────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────┐  ┌───────────────┐
      │ user-service │  │voice-nlp-svc │  │aggregator │  │  cost    │  │booking-payment│
      │    :8081     │  │    :8082     │  │  :8083    │  │  :8084   │  │    :8085      │
      │ register/    │  │ STT → intent │  │ providers │  │ pricing  │  │ book · pay ·  │
      │ login · JWT  │  │ → NER → date │  │ Redis cache│  │ formula  │  │ Kafka events  │
      └──────┬───────┘  └──────┬───────┘  │ Mongo log │  │ offers   │  └──────┬────────┘
             │                 │          └─────┬─────┘  └────┬─────┘         │
             │                 │                │   REST      │               │ Kafka
             ▼                 ▼                ▼             ▼               ▼
      ┌──────────┐      ┌──────────────┐  ┌───────────┐  ┌──────────┐  ┌──────────────────┐
      │PostgreSQL│      │   (stateless)│  │   Redis   │  │PostgreSQL│  │ notification-svc │
      │ticketly_ │      │              │  │  MongoDB  │  │ticketly_ │  │      :8086       │
      │   user   │      │              │  │           │  │  offers  │  │  Kafka consumer  │
      └──────────┘      └──────────────┘  └───────────┘  └──────────┘  └────────┬─────────┘
                                                                                ▼
                                                                        ┌──────────────┐
                                                                        │   MongoDB    │
                                                                        │ notifications│
                                                                        └──────────────┘
                     Apache Kafka: booking.confirmed · booking.cancelled
```

### Services

| Service | Port | Responsibility | Store |
|---|---|---|---|
| `api-gateway` | 8080 | Routing, CORS, per-IP token-bucket rate limit, JWT validation | — |
| `user-service` | 8081 | Register / login / profile, issues HMAC-signed JWT | PostgreSQL `ticketly_user` |
| `voice-nlp-service` | 8082 | Speech-to-text → intent → NER → date/budget resolution | — (stateless) |
| `aggregator-service` | 8083 | Parallel provider fan-out, Redis cache, Mongo search log | Redis + MongoDB |
| `cost-optimization-service` | 8084 | Pricing formula, MFS/bank offers, ranking, badges | PostgreSQL `ticketly_offers` |
| `booking-payment-service` | 8085 | Booking lifecycle, mock MFS/card payment, Kafka events | PostgreSQL `ticketly_booking` |
| `notification-service` | 8086 | Consumes booking events, mock SMS/e-mail delivery | MongoDB `notifications` |

Infra: **PostgreSQL 16 · MongoDB 7 · Redis 7 · Apache Kafka 3.7 (KRaft)** — all in `docker-compose.yml`.

---

## Quick start

### Option A — everything in Docker

```bash
make up          # mvn install, then docker compose --profile apps up -d --build --wait
make smoke       # end-to-end API test through the gateway
```

### Option B — infra in Docker, services on the host (faster iteration)

```bash
make dev         # starts postgres/mongo/redis/kafka, then the 7 jars on the host
make smoke
make stop        # stop the host-run services
```

Then:

```bash
curl http://localhost:8080/actuator/health
```

Other targets: `make build`, `make test`, `make logs`, `make down`, `make clean`, `make help`.

> **Requirements:** JDK 17+, Maven 3.8+, Docker + Docker Compose v2. For the mobile app: Flutter 3.47+.

---

## Mobile app

```bash
cd mobile
flutter pub get
flutter run                              # device/emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android emulator
```

Hold the mic button, speak, and the app fills the search form from the parsed query:
route, transport, date, budget and priority are all extracted client-side from
`POST /api/v1/nlp/parse`.

### Screens

| Screen | File | What it does |
|---|---|---|
| Splash | `splash_screen.dart` | Restores the cached session, routes to login or the home shell |
| Login | `login_screen.dart` | Sign in with phone/e-mail + password |
| Register | `register_screen.dart` | Create a new account |
| Home shell | `home_screen.dart` | Three-tab shell (search / bookings / profile) + notifications bell; `homeTabIndex` lets child routes switch tabs |
| Search | `home_screen.dart` (`_HomeTab`) | Route picker, voice input, transport/date/budget filters → `POST /api/v1/nlp/parse`, `POST /api/v1/search` |
| Results | `results_screen.dart` | Optimised fares, sort chips (price/duration), inline price breakdown |
| Checkout | `booking_checkout_screen.dart` | Passenger + payment + promo form, creates the booking, shows the inline success state |
| My bookings | `my_bookings_screen.dart` | Booking list with an inline detail bottom sheet (cancel with reason) |
| Notifications | `notifications_screen.dart` | Unread list, marks everything read on open |
| Profile | `profile_screen.dart` | Identity, account details, sign out |

### Current status

All ten screens are implemented and wired to the gateway; `flutter analyze`
reports no issues and `flutter test` passes (models, pricing, formatting and
screen smoke tests). Payment, STT and transport providers run against mocks
unless real keys/URLs are configured — see [Configuration](#configuration).

---

## API reference

Base URL: `http://localhost:8080` (gateway). All protected calls need
`Authorization: Bearer <token>`.

| Method | Path | Auth | Body → Response |
|---|---|---|---|
| POST | `/api/v1/auth/register` | – | `{name, phone, email, password}` → `{token, tokenType, expiresInMs, user}` |
| POST | `/api/v1/auth/login` | – | `{identifier, password}` → same |
| GET | `/api/v1/users/me` | ✔ | → `{id, name, phone, email, createdAt}` |
| POST | `/api/v1/nlp/parse` | – | `{text\|audioBase64, contentType?, sessionId?}` → `{sessionId, text, transcript, intent, source, destination, transportType, travelDate, budgetLimit, priority, confidence, detectedTerms[]}` |
| POST | `/api/v1/search` | – | `{source, destination, travelDate, transportType, budgetLimit?, priority, sessionId?}` → `{searchId, items: OptimizedFare[], cached, totalFound, generatedAt}` |
| GET | `/api/v1/offers` | – | → `[OfferResponse]` |
| POST | `/api/v1/optimize` | – (internal) | `{items, paymentMethods?, priority?, budgetLimit?, promoCode?}` → `{items, cheapestId, recommendedId, generatedAt}` |
| POST | `/api/v1/bookings` | ✔ | `{searchId, fare, passengerName, passengerPhone, quantity, paymentMethod, mfsProvider?, cardLast4?, promoCode?}` → `BookingResponse` |
| GET | `/api/v1/bookings` | ✔ | → `[BookingResponse]` (own, newest first) |
| GET | `/api/v1/bookings/{id}` | ✔ | → `BookingResponse` |
| POST | `/api/v1/bookings/{id}/cancel` | ✔ | `{reason}` → `BookingResponse` |
| GET | `/api/v1/notifications` | ✔ | → `[NotificationResponse]` |
| GET | `/api/v1/notifications/unread-count` | ✔ | → `{count}` |
| POST | `/api/v1/notifications/{id}/read` | ✔ | → `NotificationResponse` |

### Core shapes

```jsonc
// OptimizedFare
{
  "fare": {
    "id": "bus-shohoz-1042", "provider": "Shohoz", "providerRef": "SHZ-1042",
    "transportType": "BUS", "source": "ঢাকা", "destination": "খুলনা",
    "travelDate": "2026-11-13", "departTime": "23:30", "arriveTime": "05:45",
    "durationMins": 375, "baseFare": 750.00, "currency": "BDT",
    "seatsAvailable": 22, "vehicleClass": "AC", "cancellationPolicy": "Free until 6h before departure",
    "meta": { "operator": "Green Line" }
  },
  "price": {
    "baseFare": 750.00, "mfsCashback": 37.50, "promoDiscount": 0.00,
    "convenienceFee": 20.00, "effectivePrice": 732.50, "savedAmount": 37.50
  },
  "appliedOffers": ["bKash 5% cashback"],
  "badge": "CHEAPEST"
}
```

**Pricing formula** (single source of truth in `cost-optimization-service`):

```
Effective Price = Base Fare − MFS Cashback − Promo Discount + Convenience Fee
```

### Error envelope

```json
{ "status": 400, "code": "validation_failed", "message": "...", "details": {"field": "reason"}, "timestamp": "..." }
```

---

## Voice & NLP pipeline

1. **Audio capture** (hold-to-talk) → base64 → `POST /api/v1/nlp/parse`2. **STT** — `voice.stt.provider=mock` (default, offline) or `openai` for real
   Whisper (`OPENAI_API_KEY`), optimised for `bn-BD` / Banglish accents.
3. **Intent** — `SEARCH_TICKET` · `BOOK_TICKET` · `CHECK_STATUS` · `UNKNOWN`
4. **NER** — 30+ Bangladeshi cities in Bengali + transliteration, with postpositions
   (`ঢাকা থেকে খুলনা`, `খুলনায়`, `dhaka theke ctg`).
5. **Date** — `আজ`, `কাল`, `আগামী শুক্রবার`, `৮ নভেম্বর`, ISO, **Bengali digits ০–৯**.
6. **Budget & priority** — `৫০০ টাকা`, `সবচেয়ে সস্তা` → `CHEAPEST`, `দ্রুত` → `FASTEST`.

Everything is rule-based and offline by default — no external API required to run the platform.

---

## Aggregator & providers

| Mode | Providers | Config prefix |
|---|---|---|
| TRAIN | Rail Sheba / Bangladesh Railway | `providers.railsheba.*` |
| BUS | Shohoz, bdtickets, Green Line, Hanif, Ena | `providers.shohoz.*` etc. |
| LAUNCH | Dhaka–Barisal, Dhaka–Bhola, Dhaka–Patuakhali … | `providers.launch.*` |
| FLIGHT | US-Bangla, Novoair, Air Astra | `providers.usbangla.*` etc. |

Each provider has a `base-url`. **When it is blank the provider runs a deterministic
mock generator** (seeded by route + date) so the whole platform works offline with
realistic BDT fares, times and seat counts. Set a real base URL to switch a provider
to live HTTP; a failing provider is logged and skipped, never fatal.

Results are cached in Redis for 60 s (`aggregator.cache.ttl-seconds`) and every query
is written to `search_logs` in MongoDB for analytics.

---

## Configuration

Every property has an env-var default — nothing needs editing for local use.

| Variable | Default | Used by |
|---|---|---|
| `JWT_SECRET` | dev key (≥32 chars) | all services |
| `DB_URL` / `DB_USER` / `DB_PASSWORD` | per-service `jdbc:postgresql://localhost:5433/...` | user, cost, booking |
| `POSTGRES_HOST_PORT` | `5433` (host port; 5432 was already taken) | compose |
| `SPRING_DATA_MONGODB_URI` | `mongodb://localhost:27017/ticketly` | aggregator, notification |
| `SPRING_DATA_REDIS_HOST/PORT` | `localhost:6379` | aggregator |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:9092` (`localhost:9094` from host) | booking, notification |
| `COST_SERVICE_URL` | `http://localhost:8084` | aggregator, booking |
| `VOICE_STT_PROVIDER` | `mock` (`openai` for Whisper) | voice-nlp |
| `OPENAI_API_KEY` | – | voice-nlp |
| `GATEWAY_RATE_LIMIT_ENABLED` | `true` (`burst 100`, `120/min`) | gateway |
| `GATEWAY_SECURITY_ENABLED` | `true` (set `false` to bypass JWT at the edge) | gateway |

Copy `.env.example` → `.env` to override any of them for `docker compose`.

### Demo offers seeded on first start

| Offer | Value | Cap | Min fare | Applies to |
|---|---|---|---|---|
| bKash | 5% cashback | ৳100 | ৳300 | MFS:bKash |
| Nagad | 4% cashback | ৳75 | ৳300 | MFS:Nagad |
| Rocket | 3% cashback | ৳50 | ৳200 | MFS:Rocket |
| EBL Visa/Mastercard | 10% cashback | ৳200 | ৳1000 | CARD:EBL |
| BRAC Bank | 7% cashback | ৳150 | ৳800 | CARD:BRAC |
| `EIDSALE` | ৳50 off | – | ৳400 | promo code |
| `WELCOME20` | ৳20 off | – | ৳200 | promo code |

---

## Testing

```bash
make test     # unit tests (pricing formula, NLP parser, providers, payments, PNR)
make smoke    # 10-step end-to-end test through the gateway
```

The smoke test registers a user, parses a Bengali query, searches all four transport
modes, checks the offer catalogue, books (mock bKash), lists bookings, waits for the
Kafka-driven notification, and cancels.

The Flutter app has its own checks, both run in CI:

```bash
cd mobile
flutter analyze   # must report no issues
flutter test      # models, pricing, formatting, screen smoke tests
```

---

## Project layout

```
ticketly/
├── pom.xml                     # parent reactor (Java 17, Spring Boot 3.3.5)
├── common/                     # shared DTOs, JWT security, Kafka events, error model
├── services/
│   ├── api-gateway/            # Spring Cloud Gateway (WebFlux)
│   ├── user-service/           # JPA + PostgreSQL
│   ├── voice-nlp-service/      # STT + rule-based Bengali NLU
│   ├── aggregator-service/     # RestClient + Redis + Mongo
│   ├── cost-optimization-service/  # pricing engine + offers (JPA)
│   ├── booking-payment-service/    # JPA + Kafka producer + payment gateway
│   └── notification-service/       # Kafka consumer + Mongo
├── mobile/                     # Flutter app
├── infra/postgres/init.sql     # database bootstrap
├── scripts/                    # dev-up, dev-down, smoke-test
├── Dockerfile                  # one generic image (jar built on the host)
└── docker-compose.yml
```

---

## Roadmap (from the specification)

| Phase | Scope | Status |
|---|---|---|
| 1 (months 1–2) | MVP, core UI, train & bus integration, manual search/filter | ✅ in this repo |
| 2 (months 3–4) | Voice NLP pipeline (Bengali STT + intent parsing) | ✅ offline NLU + Whisper hook |
| 3 (months 5–6) | Cost optimisation engine + MFS payment gateway | ✅ formula + mock MFS/card |
| 4 (month 7+) | Store launch, scaling launch & flight integrations | ⬜ real provider API keys |

**Production notes:** the mock payment gateway, mock STT and mock transport providers
all sit behind interfaces (`PaymentGateway`, `SttProvider`, `TransportProvider`) —
swap them for real bKash/Nagad/Whisper/Rail Sheba integrations without touching the
rest of the system. Put the services behind a private network so `/api/v1/optimize`
is not reachable from the internet, replace the in-memory rate limiter with a shared
store if you run multiple gateway replicas, and enable TLS at the edge.
