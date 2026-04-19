# Event Booking API

Node.js + Fastify backend for the Event & Wedding Booking System.

## Features

- **Authentication**: JWT with refresh token rotation
- **Booking Engine**: Slot locking, conflict detection, transactions
- **Dynamic Pricing**: Seasonal, weekend, early-bird, and bulk discount rules
- **Payments**: Stripe integration (PaymentIntent, webhooks)
- **Provider Dashboard**: Analytics, availability management, pricing rules
- **Real-time**: Redis for caching and slot locking (WebSocket ready)

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Fastify 4.x
- **Database**: PostgreSQL 16 + Prisma ORM
- **Cache**: Redis 7
- **Payments**: Stripe
- **Validation**: Zod

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Set Up Environment Variables

```bash
cp .env.example .env
# Edit .env with your database and Stripe credentials
```

### 3. Set Up Database

```bash
# Run migrations
npm run db:migrate

# Generate Prisma client
npm run db:generate

# Seed with sample data
npm run db:seed
```

### 4. Start Development Server

```bash
npm run dev
```

Server will start at `http://localhost:3000`

API docs available at `http://localhost:3000/docs`

## Database Schema

See `prisma/schema.prisma` for full schema.

Key entities:
- **Users**: Consumers, providers, admins
- **Providers**: Business profiles with ratings
- **Services**: Halls, cars, photographers, entertainers
- **Bookings**: Events with multiple service items
- **Booked Slots**: Time slot reservations with conflict prevention
- **Pricing Rules**: Dynamic pricing engine

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/me` - Get current user

### Services
- `GET /api/v1/services` - List services (filter, sort, paginate)
- `GET /api/v1/services/search` - Full-text search
- `GET /api/v1/services/:id` - Service details
- `GET /api/v1/services/:id/availability` - Available time slots
- `GET /api/v1/services/:id/reviews` - Service reviews

### Bookings
- `GET /api/v1/bookings` - List user bookings
- `POST /api/v1/bookings` - Create booking
- `GET /api/v1/bookings/:id` - Booking details
- `PATCH /api/v1/bookings/:id` - Update booking
- `POST /api/v1/bookings/:id/cancel` - Cancel booking
- `POST /api/v1/bookings/:id/confirm` - Confirm booking (provider)

### Payments
- `POST /api/v1/payments/create-intent` - Create Stripe PaymentIntent
- `POST /api/v1/payments/confirm` - Confirm payment
- `GET /api/v1/payments/history` - Payment history
- `POST /api/v1/payments/webhook` - Stripe webhook

### Users
- `GET /api/v1/users/profile` - Get profile
- `PATCH /api/v1/users/profile` - Update profile
- `GET /api/v1/users/preferences` - Get preferences
- `PUT /api/v1/users/preferences` - Update preferences
- `GET /api/v1/users/bookmarks` - Get bookmarks
- `POST /api/v1/users/bookmarks` - Add bookmark
- `DELETE /api/v1/users/bookmarks/:id` - Remove bookmark
- `GET /api/v1/users/notifications` - Get notifications

### Provider Dashboard
- `GET /api/v1/provider/dashboard` - Dashboard stats
- `GET /api/v1/provider/bookings` - Provider bookings
- `PATCH /api/v1/provider/bookings/:id/status` - Update booking status
- `GET /api/v1/provider/services` - Manage services
- `GET /api/v1/provider/availability/:serviceId` - Get availability
- `POST /api/v1/provider/availability/:serviceId` - Update availability
- `GET /api/v1/provider/pricing-rules/:serviceId` - Get pricing rules
- `POST /api/v1/provider/pricing-rules` - Create pricing rule

## Test Credentials (After Seeding)

```
Admin: admin@eventbooker.com / password123
Consumer: consumer@example.com / password123
Providers:
  - Mohammed@eventbooker.com / password123 (Hall provider)
  - arhab@eventbooker.com / password123 (Car provider)
  - teshreen@eventbooker.com / password123 (Photographer)
  - dj@eventbooker.com / password123 (Entertainer)
```

## Scripts

```bash
npm run dev          # Start development server with hot reload
npm start            # Start production server
npm run db:migrate   # Run database migrations
npm run db:generate  # Generate Prisma client
npm run db:seed      # Seed database with sample data
npm run db:studio    # Open Prisma Studio
npm test             # Run tests
```

## Environment Variables

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/event_booking"

# JWT
JWT_SECRET="your-super-secret-key"
JWT_REFRESH_SECRET="your-refresh-secret"

# Redis
REDIS_URL="redis://localhost:6379"

# Stripe
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."

# Server
PORT=3000
NODE_ENV=development
```

## License

MIT
