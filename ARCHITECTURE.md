# Event & Wedding Booking System — Architecture & Design

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Flutter Mobile App│  │ Flutter Web App  │  │ Provider Dash│  │
│  │   (Consumer)      │  │   (Consumer)     │  │  (Web/Admin) │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────┬───────┘  │
└───────────┼──────────────────────┼───────────────────┼─────────┘
            │                      │                   │
            ▼                      ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (Kong/Nginx)                     │
│         Rate Limiting · Auth · Load Balancing · SSL             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Auth Service │  │ Booking Svc  │  │ Provider Svc │
│  (Node.js)    │  │ (Node.js)    │  │ (Node.js)    │
│  JWT + OAuth2 │  │ Core Engine  │  │ Dashboard    │
│  Refresh Tok  │  │ Slot Mgmt    │  │ Availability │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                  │
       ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  User DB     │  │  Booking DB  │  │  Provider DB │
│  (PostgreSQL)│  │ (PostgreSQL) │  │ (PostgreSQL) │
└──────────────┘  └──────────────┘  └──────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │ Redis Cache  │
                  │ + Pub/Sub    │
                  │ (Real-time)  │
                  └──────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  WebSocket   │
                  │  Server      │
                  │  (Socket.io) │
                  └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │  AWS S3     │  │  Stripe    │  │  SendGrid  │  │ Firebase  │ │
│  │  (Images)   │  │ (Payments) │  │  (Email)   │  │ (Push)    │ │
│  └────────────┘  └────────────┘  └────────────┘  └──────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 2. Technology Stack

### Frontend (Consumer)

| Layer       | Technology       | Rationale                                             |
| ----------- | ---------------- | ----------------------------------------------------- |
| Framework   | Flutter 3.x      | Cross-platform (iOS/Android/Web) from single codebase |
| State Mgmt  | Riverpod 2.x     | Compile-safe, testable, scalable                      |
| Navigation  | GoRouter         | Declarative routing, deep link support                |
| HTTP Client | Dio              | Interceptors, retry, timeout handling                 |
| Real-time   | Socket.io Client | Live booking confirmations & availability             |
| Local Cache | Hive             | Fast offline storage for preferences/bookmarks        |
| Maps        | Google Maps SDK  | Venue location display                                |
| Calendar    | table_calendar   | Date/time slot selection                              |
| Payments    | flutter_stripe   | Secure in-app payments                                |

### Frontend (Provider Dashboard)

| Layer     | Technology          | Rationale                        |
| --------- | ------------------- | -------------------------------- |
| Framework | Flutter Web         | Same codebase, responsive layout |
| Charts    | fl_chart            | Booking analytics visualization  |
| Calendar  | syncfusion_calendar | Availability management          |

### Backend

| Layer      | Technology               | Rationale                                           |
| ---------- | ------------------------ | --------------------------------------------------- |
| Runtime    | Node.js 20 LTS           | Non-blocking I/O, real-time capable                 |
| Framework  | Fastify                  | 2x faster than Express, schema validation           |
| Database   | PostgreSQL 16            | ACID compliance, JSONB, full-text search            |
| ORM        | Prisma                   | Type-safe queries, migrations, auto-generated types |
| Cache      | Redis 7                  | Pub/Sub for real-time, slot locking, rate limiting  |
| Real-time  | Socket.io                | Bi-directional, auto-reconnect, rooms               |
| Auth       | JWT + Refresh Tokens     | Stateless auth, secure rotation                     |
| Validation | Zod                      | Runtime type validation                             |
| Payments   | Stripe                   | PCI compliant, supports holds/captures              |
| Storage    | AWS S3                   | Image/document uploads                              |
| Email      | SendGrid                 | Transactional + marketing emails                    |
| Push       | Firebase Cloud Messaging | Mobile push notifications                           |
| Search     | Meilisearch              | Fast fuzzy search for services                      |
| Container  | Docker + Docker Compose  | Consistent deployment                               |
| CI/CD      | GitHub Actions           | Automated testing + deployment                      |

### Infrastructure

| Layer       | Technology           | Rationale                        |
| ----------- | -------------------- | -------------------------------- |
| Hosting     | AWS ECS / Railway    | Scalable container orchestration |
| CDN         | CloudFront           | Static asset delivery            |
| SSL         | Let's Encrypt        | Free TLS certificates            |
| Monitoring  | Grafana + Prometheus | Metrics & alerting               |
| Logging     | Loki + Promtail      | Centralized log aggregation      |
| API Gateway | Kong                 | Rate limiting, auth proxy        |

## 3. Database Schema

### Core Entities

```sql
-- ═══════════════════════════════════════════════════════════
-- USERS & AUTHENTICATION
-- ═══════════════════════════════════════════════════════════

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    phone           VARCHAR(20),
    full_name       VARCHAR(255) NOT NULL,
    avatar_url      TEXT,
    role            VARCHAR(20) NOT NULL DEFAULT 'consumer'
                    CHECK (role IN ('consumer', 'provider', 'admin')),
    is_verified     BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    preferences     JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- SERVICE PROVIDERS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE providers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name   VARCHAR(255) NOT NULL,
    description     TEXT,
    logo_url        TEXT,
    cover_url       TEXT,
    service_type    VARCHAR(30) NOT NULL
                    CHECK (service_type IN ('hall', 'car', 'photographer', 'entertainer')),
    rating          DECIMAL(3,2) DEFAULT 0.00,
    review_count    INT DEFAULT 0,
    is_verified     BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    location        POINT,  -- PostGIS for geo queries
    address         TEXT,
    city            VARCHAR(100),
    country         VARCHAR(100),
    contact_phone   VARCHAR(20),
    contact_email   VARCHAR(255),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- SERVICES (Halls, Cars, Photography Packages, Entertainment)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE services (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id     UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    service_type    VARCHAR(30) NOT NULL
                    CHECK (service_type IN ('hall', 'car', 'photographer', 'entertainer')),
    base_price      DECIMAL(12,2) NOT NULL,
    currency        VARCHAR(3) DEFAULT 'USD',
    pricing_model   VARCHAR(20) DEFAULT 'flat'
                    CHECK (pricing_model IN ('flat', 'hourly', 'per_event', 'tiered')),
    images          JSONB DEFAULT '[]',     -- Array of image URLs
    tags            JSONB DEFAULT '[]',     -- Searchable tags
    attributes      JSONB DEFAULT '{}',     -- Type-specific attributes (see below)
    is_available    BOOLEAN DEFAULT TRUE,
    max_capacity    INT,                     -- For halls
    min_duration_hrs DECIMAL(4,2) DEFAULT 1, -- Minimum booking duration
    max_duration_hrs DECIMAL(4,2),           -- Maximum booking duration
    cancellation_policy JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Type-specific attributes stored in `attributes` JSONB:
-- Hall:     { capacity, has_stage, has_parking, has_kitchen, theme, amenities:[] }
-- Car:      { make, model, year, color, car_type, max_passengers, features:[] }
-- Photographer: { portfolio_url, specialties:[], equipment:[], editing_included }
-- Entertainer: { performer_type, genres:[], sample_video_url, group_size }

-- ═══════════════════════════════════════════════════════════
-- AVAILABILITY & TIME SLOTS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE availability_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id      UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    day_of_week     SMALLINT CHECK (day_of_week BETWEEN 0 AND 6),
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    is_available    BOOLEAN DEFAULT TRUE,
    effective_from  DATE,
    effective_to    DATE
);

CREATE TABLE booked_slots (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id      UUID NOT NULL REFERENCES services(id),
    booking_id      UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    status          VARCHAR(20) DEFAULT 'confirmed'
                    CHECK (status IN ('confirmed', 'cancelled', 'completed', 'no_show')),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent double booking with exclusion constraint
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE booked_slots
    ADD CONSTRAINT no_double_booking
    EXCLUDE USING gist (
        service_id WITH =,
        date WITH =,
        tsrange(start_time, end_time) WITH &&
    ) WHERE (status = 'confirmed');

-- ═══════════════════════════════════════════════════════════
-- PRICING RULES (dynamic pricing, surge, discounts)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE pricing_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id      UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    rule_type       VARCHAR(30) NOT NULL
                    CHECK (rule_type IN ('seasonal', 'weekend', 'peak', 'early_bird', 'last_minute', 'bulk_discount')),
    multiplier      DECIMAL(5,2) NOT NULL DEFAULT 1.00,  -- 1.00 = no change
    fixed_adjustment DECIMAL(12,2) DEFAULT 0,
    start_date      DATE,
    end_date        DATE,
    day_of_week     SMALLINT CHECK (day_of_week BETWEEN 0 AND 6),
    min_advance_days INT,          -- For early_bird / last_minute
    min_bookings    INT,           -- For bulk_discount
    priority        INT DEFAULT 0, -- Higher = applied first
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- BOOKINGS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id     UUID NOT NULL REFERENCES users(id),
    event_type      VARCHAR(30) DEFAULT 'wedding'
                    CHECK (event_type IN ('wedding', 'birthday', 'corporate', 'engagement', 'other')),
    event_date      DATE NOT NULL,
    event_name      VARCHAR(255),
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('draft', 'pending', 'confirmed', 'in_progress',
                                     'completed', 'cancelled', 'refunded')),
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency        VARCHAR(3) DEFAULT 'USD',
    deposit_amount  DECIMAL(12,2) DEFAULT 0,
    deposit_paid    BOOLEAN DEFAULT FALSE,
    notes           TEXT,
    special_requests TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE booking_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    service_id      UUID NOT NULL REFERENCES services(id),
    provider_id     UUID NOT NULL REFERENCES providers(id),
    date            DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    duration_hours  DECIMAL(4,2),
    unit_price      DECIMAL(12,2) NOT NULL,
    applied_pricing JSONB DEFAULT '{}',  -- Which pricing rules were applied
    subtotal        DECIMAL(12,2) NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    special_requests TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- PAYMENTS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL REFERENCES bookings(id),
    amount          DECIMAL(12,2) NOT NULL,
    currency        VARCHAR(3) DEFAULT 'USD',
    payment_method  VARCHAR(30) NOT NULL
                    CHECK (payment_method IN ('card', 'bank_transfer', 'wallet', 'cash')),
    stripe_payment_intent_id VARCHAR(255),
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'succeeded',
                                     'failed', 'refunded', 'partially_refunded')),
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- REVIEWS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_item_id UUID NOT NULL REFERENCES booking_items(id),
    consumer_id     UUID NOT NULL REFERENCES users(id),
    provider_id     UUID NOT NULL REFERENCES providers(id),
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    images          JSONB DEFAULT '[]',
    is_anonymous    BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL
                    CHECK (type IN ('booking_confirmed', 'booking_cancelled',
                                     'payment_received', 'reminder', 'review_request',
                                     'provider_message', 'price_drop', 'system')),
    title           VARCHAR(255) NOT NULL,
    body            TEXT,
    data            JSONB DEFAULT '{}',
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- USER PREFERENCES & BOOKMARKS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE user_preferences (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_hall_themes     JSONB DEFAULT '[]',
    preferred_car_types       JSONB DEFAULT '[]',
    preferred_photographer_styles JSONB DEFAULT '[]',
    preferred_entertainer_types    JSONB DEFAULT '[]',
    budget_range             JSONB DEFAULT '{}',  -- { min, max }
    preferred_cities         JSONB DEFAULT '[]',
    notification_settings    JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bookmarks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_id      UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, service_id)
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX idx_services_type ON services(service_type);
CREATE INDEX idx_services_provider ON services(provider_id);
CREATE INDEX idx_bookings_consumer ON bookings(consumer_id);
CREATE INDEX idx_bookings_date ON bookings(event_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_booked_slots_service_date ON booked_slots(service_id, date);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_providers_type ON providers(service_type);
CREATE INDEX idx_providers_location ON providers USING gist(location);
```

## 4. User Flow Diagrams

### 4.1 Consumer Booking Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Sign Up  │───▶│  Login   │───▶│   Home   │───▶│ Explore  │
│ / Sign In │    │  (JWT)   │    │  Screen  │    │ Services │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                    │
                    ┌───────────────────────────────┘
                    ▼
         ┌─────────────────────┐
         │  Service Categories │
         │  ┌───────┐ ┌──────┐│
         │  │ Halls │ │ Cars ││
         │  └───┬───┘ └──┬───┘│
         │  ┌───────┐ ┌──────┐│
         │  │Photos │ │Enter.││
         │  └───┬───┘ └──┬───┘│
         └──────┼─────────┼────┘
                │         │
                ▼         ▼
         ┌─────────────────────┐
         │   Service Listing   │
         │  (Filter/Sort/Search)│
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Service Details    │
         │  · Gallery          │
         │  · Pricing          │
         │  · Reviews          │
         │  · Availability Cal │
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Select Date & Time  │
         │  · Check Availability│
         │  · Choose Slot       │
         │  · Apply Preferences │
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Add to Booking Cart │◀──── Repeat for each service
         │  · Hall + Car +      │     (hall, car, photographer,
         │    Photo + Entertainer│      entertainer)
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Review Booking      │
         │  · All services      │
         │  · Total pricing     │
         │  · Conflicts check   │
         │  · Special requests  │
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Payment             │
         │  · Deposit / Full    │
         │  · Stripe secure     │
         │  · Hold on card      │
         └─────────┬───────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  ✅ Booking Confirmed│
         │  · Real-time notify  │
         │  · Email receipt     │
         │  · Push notification │
         │  · Calendar sync     │
         └─────────────────────┘
```

### 4.2 Provider Dashboard Flow

```
┌──────────┐    ┌──────────┐    ┌──────────────────┐
│  Login    │───▶│ Dashboard│───▶│  Booking Calendar │
│ (Provider)│    │ Overview │    │  · View slots     │
└──────────┘    └──────────┘    │  · Accept/Reject  │
                                └────────┬─────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                    ▼                    ▼
          ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
          │ Availability │   │  Services    │   │  Analytics   │
          │ Management   │   │  Management  │   │  · Revenue   │
          │ · Set hours  │   │  · Add/Edit  │   │  · Bookings  │
          │ · Block dates│   │  · Pricing   │   │  · Ratings   │
          │ · Seasonal   │   │  · Images    │   │  · Trends    │
          └──────────────┘   └──────────────┘   └──────────────┘
```

### 4.3 Real-Time Booking Confirmation Flow

```
Consumer selects slot
        │
        ▼
┌──────────────────┐
│  Redis: Acquire  │──── Slot locked (TTL 10 min)
│  Slot Lock       │     Prevents double booking
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Validate Slot   │──── Check against booked_slots
│  (PostgreSQL)    │     Exclusion constraint
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Calculate Price │──── Apply pricing_rules
│  (Dynamic)       │     Seasonal/weekend/early_bird
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Create Booking  │──── Insert booking + items
│  (Transaction)   │     Atomic operation
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Process Payment │──── Stripe PaymentIntent
│  (Hold/Capture)  │     Deposit or full amount
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Success │ Failure
    ▼         ▼
┌────────┐  ┌────────┐
│Confirm │  │Release │
│Booking │  │Lock    │
│+Notify │  │+Notify │
└────────┘  └────────┘
     │
     ▼
┌──────────────────┐
│  WebSocket Emit  │──── Provider gets instant notification
│  · Provider room │     Consumer gets confirmation
│  · Consumer room │     Slot marked as booked
└──────────────────┘
```

## 5. API Design

### Authentication

| Method | Endpoint                       | Description                        |
| ------ | ------------------------------ | ---------------------------------- |
| POST   | `/api/v1/auth/register`        | Register new user                  |
| POST   | `/api/v1/auth/login`           | Login, returns JWT + refresh token |
| POST   | `/api/v1/auth/refresh`         | Refresh access token               |
| POST   | `/api/v1/auth/logout`          | Invalidate refresh token           |
| POST   | `/api/v1/auth/forgot-password` | Request password reset             |
| POST   | `/api/v1/auth/reset-password`  | Reset with token                   |

### Services (Consumer)

| Method | Endpoint                            | Description                            |
| ------ | ----------------------------------- | -------------------------------------- |
| GET    | `/api/v1/services`                  | List services (filter, sort, paginate) |
| GET    | `/api/v1/services/:id`              | Service details                        |
| GET    | `/api/v1/services/:id/availability` | Get available slots for date range     |
| GET    | `/api/v1/services/:id/reviews`      | Service reviews                        |
| GET    | `/api/v1/services/search`           | Full-text search                       |

### Bookings (Consumer)

| Method | Endpoint                       | Description               |
| ------ | ------------------------------ | ------------------------- |
| POST   | `/api/v1/bookings`             | Create booking with items |
| GET    | `/api/v1/bookings`             | List user's bookings      |
| GET    | `/api/v1/bookings/:id`         | Booking details           |
| PATCH  | `/api/v1/bookings/:id`         | Update booking            |
| POST   | `/api/v1/bookings/:id/cancel`  | Cancel booking            |
| POST   | `/api/v1/bookings/:id/confirm` | Confirm pending booking   |

### Payments

| Method | Endpoint                         | Description                 |
| ------ | -------------------------------- | --------------------------- |
| POST   | `/api/v1/payments/create-intent` | Create Stripe PaymentIntent |
| POST   | `/api/v1/payments/confirm`       | Confirm payment             |
| POST   | `/api/v1/payments/webhook`       | Stripe webhook handler      |
| GET    | `/api/v1/payments/history`       | Payment history             |

### Provider Dashboard

| Method | Endpoint                               | Description           |
| ------ | -------------------------------------- | --------------------- |
| GET    | `/api/v1/provider/dashboard`           | Dashboard stats       |
| GET    | `/api/v1/provider/bookings`            | Incoming bookings     |
| PATCH  | `/api/v1/provider/bookings/:id/status` | Accept/reject booking |
| CRUD   | `/api/v1/provider/services`            | Manage services       |
| CRUD   | `/api/v1/provider/availability`        | Manage availability   |
| CRUD   | `/api/v1/provider/pricing-rules`       | Manage pricing        |
| GET    | `/api/v1/provider/analytics`           | Booking analytics     |

### WebSocket Events

| Event               | Direction         | Description             |
| ------------------- | ----------------- | ----------------------- |
| `booking:created`   | Server → Provider | New booking request     |
| `booking:confirmed` | Server → Consumer | Booking confirmed       |
| `booking:cancelled` | Server → Both     | Booking cancelled       |
| `slot:locked`       | Server → All      | Slot temporarily locked |
| `slot:released`     | Server → All      | Slot lock released      |
| `payment:received`  | Server → Provider | Payment confirmed       |

## 6. Step-by-Step Implementation Plan

### Phase 1: Foundation (Weeks 1-2)

1. Set up Flutter project structure (reusing existing e-commerce UI)
2. Configure Riverpod state management
3. Create data models (Dart classes mirroring DB schema)
4. Set up GoRouter navigation
5. Create API service layer (Dio + interceptors)
6. Build authentication screens (login, signup, OTP)
7. Implement JWT storage and refresh token rotation

### Phase 2: Core Consumer Experience (Weeks 3-5)

8. Build home screen with service categories
9. Implement service listing with filters (type, price, rating, location)
10. Build service detail screen (gallery, pricing, reviews, availability)
11. Create date/time slot picker with real-time availability
12. Implement booking cart (add/remove services, conflict detection)
13. Build booking review & summary screen
14. Integrate Stripe payment flow
15. Build booking confirmation screen with real-time updates

### Phase 3: Provider Dashboard (Weeks 6-7)

16. Build provider dashboard overview (stats, charts)
17. Implement booking calendar (accept/reject/manage)
18. Build service management (CRUD, images, pricing)
19. Implement availability management (templates, block dates)
20. Build pricing rules editor (seasonal, weekend, bulk)

### Phase 4: Backend Development (Weeks 3-8, parallel)

21. Set up Node.js + Fastify project structure
22. Configure Prisma with PostgreSQL schema
23. Implement auth service (register, login, JWT, refresh)
24. Build booking engine (slot locking, conflict detection, transactions)
25. Implement dynamic pricing engine
26. Set up Redis for slot locking and caching
27. Build WebSocket server for real-time events
28. Integrate Stripe (PaymentIntent, webhooks, refunds)
29. Set up Meilisearch for service search
30. Implement notification service (email, push, in-app)

### Phase 5: Polish & Production (Weeks 9-10)

31. Implement user preferences & personalization
32. Build review system
33. Add bookmark/favorite functionality
34. Implement offline mode with Hive caching
35. Add error handling & retry logic
36. Performance optimization (lazy loading, pagination)
37. Security audit (input validation, rate limiting, CORS)
38. Write integration tests
39. Dockerize backend services
40. Set up CI/CD pipeline
41. Deploy to staging → production

## 7. Security Considerations

- **Authentication**: JWT with short-lived access tokens (15 min) + long-lived refresh tokens (7 days)
- **Authorization**: Role-based access control (RBAC) with middleware guards
- **Input Validation**: Zod schemas on all API endpoints
- **SQL Injection**: Prisma parameterized queries
- **XSS**: Content-Security-Policy headers, output encoding
- **CSRF**: Same-site cookies + CSRF tokens for web
- **Rate Limiting**: Redis-backed rate limiter (100 req/min per user)
- **Data Encryption**: TLS in transit, AES-256 at rest for PII
- **Payment Security**: Stripe handles PCI compliance, no card data stored
- **Slot Locking**: Redis distributed lock with TTL prevents race conditions
- **PII Handling**: GDPR-compliant data retention and deletion APIs

## 8. Scalability Strategy

- **Horizontal Scaling**: Stateless services behind load balancer
- **Database**: Read replicas for queries, connection pooling via PgBouncer
- **Caching**: Redis for hot data (availability, pricing), CDN for images
- **Queue**: Bull/BullMQ for async jobs (email, notifications, analytics)
- **Search**: Meilisearch separate from primary DB
- **WebSocket**: Redis adapter for multi-instance Socket.io
- **Monitoring**: Prometheus metrics, Grafana dashboards, PagerDuty alerts

## 9. Flutter Frontend Implementation Status

### ✅ Completed (Phase 1 - Core UI & Models)

| Component            | File                                                   | Status      |
| -------------------- | ------------------------------------------------------ | ----------- |
| Data Models          | `lib/models/booking_models.dart`                       | ✅ Complete |
| Demo Data            | `lib/models/demo_booking_data.dart`                    | ✅ Complete |
| Booking Home         | `lib/screens/booking/booking_home_screen.dart`         | ✅ Complete |
| Service Listing      | `lib/screens/booking/service_listing_screen.dart`      | ✅ Complete |
| Service Detail       | `lib/screens/booking/service_detail_screen.dart`       | ✅ Complete |
| Date/Time Picker     | `lib/screens/booking/date_time_picker_screen.dart`     | ✅ Complete |
| Booking Cart         | `lib/screens/booking/booking_cart_screen.dart`         | ✅ Complete |
| Booking Confirmation | `lib/screens/booking/booking_confirmation_screen.dart` | ✅ Complete |
| Booking Success      | `lib/screens/booking/booking_success_screen.dart`      | ✅ Complete |
| My Bookings          | `lib/screens/booking/my_bookings_screen.dart`          | ✅ Complete |
| Booking Detail       | `lib/screens/booking/booking_detail_screen.dart`       | ✅ Complete |
| Provider Dashboard   | `lib/screens/booking/provider_dashboard_screen.dart`   | ✅ Complete |
| State Management     | `lib/services/booking_provider.dart`                   | ✅ Complete |

### ✅ Completed (Phase 2 - Enhanced Architecture)

| Component                  | File                                                          | Status             |
| -------------------------- | ------------------------------------------------------------- | ------------------ |
| API Service Layer          | `lib/services/api_service.dart`                               | ✅ Complete (mock) |
| Auth Provider              | `lib/services/auth_provider.dart`                             | ✅ Complete        |
| Auth Screen (Login/Signup) | `lib/screens/booking/auth_screen.dart`                        | ✅ Complete        |
| Search Screen              | `lib/screens/booking/booking_search_screen.dart`              | ✅ Complete        |
| Notifications Screen       | `lib/screens/booking/booking_notifications_screen.dart`       | ✅ Complete        |
| Reviews Screen             | `lib/screens/booking/booking_reviews_screen.dart`             | ✅ Complete        |
| Bookmarks Screen           | `lib/screens/booking/booking_bookmarks_screen.dart`           | ✅ Complete        |
| Provider Availability      | `lib/screens/booking/provider_availability_screen.dart`       | ✅ Complete        |
| Provider Service Mgmt      | `lib/screens/booking/provider_service_management_screen.dart` | ✅ Complete        |
| Provider Pricing Rules     | `lib/screens/booking/provider_pricing_rules_screen.dart`      | ✅ Complete        |
| User Preferences           | `lib/screens/booking/user_preferences_screen.dart`            | ✅ Complete        |
| Pricing Rules Model        | `PricingRuleModel` in booking_models.dart                     | ✅ Complete        |
| Availability Templates     | `AvailabilityTemplateModel` in booking_models.dart            | ✅ Complete        |
| Cancellation Policy        | `CancellationPolicy` in booking_models.dart                   | ✅ Complete        |
| Auth Tokens                | `AuthTokens` in booking_models.dart                           | ✅ Complete        |
| API Response Wrapper       | `ApiResponse<T>` in booking_models.dart                       | ✅ Complete        |
| Dashboard Stats            | `ProviderDashboardStats` in booking_models.dart               | ✅ Complete        |
| Dynamic Pricing            | `ServiceModel.getEffectivePrice()`                            | ✅ Complete        |
| Booking Model copyWith     | `BookingModel.copyWith()`                                     | ✅ Complete        |
| Route Constants            | 10 new routes added                                           | ✅ Complete        |
| Localization (EN/AR)       | 55+ new keys added                                            | ✅ Complete        |

### 🔲 Pending (Phase 3 - Backend Integration)

| Component                                   | Status                              |
| ------------------------------------------- | ----------------------------------- |
| Dio HTTP Client + Interceptors              | 🔲 Replace mock with real Dio calls |
| JWT Secure Storage (flutter_secure_storage) | 🔲 Implement                        |
| WebSocket Client (Socket.io)                | 🔲 Real-time booking updates        |
| Stripe Payment SDK                          | 🔲 Payment flow integration         |
| Push Notifications (Firebase)               | 🔲 FCM integration                  |
| Image Upload (Provider)                     | 🔲 Service photo management         |
| Deep Linking                                | 🔲 Share service/booking links      |
| Offline Mode (Hive/Isar)                    | 🔲 Cache for offline access         |
| Analytics (Mixpanel/Firebase)               | 🔲 Event tracking                   |
| CI/CD Pipeline                              | 🔲 GitHub Actions + Fastlane        |
