# Backend Integration Setup Guide

## What Was Implemented

### 1. Node.js Backend (`/backend` folder)
- **Fastify server** with JWT authentication
- **PostgreSQL database** with Prisma ORM
- **Redis** for slot locking and caching
- **Stripe** payment integration
- **Complete REST API** matching ARCHITECTURE.md specs

### 2. Backend Structure
```
backend/
├── src/
│   ├── index.js              # Server entry point
│   ├── lib/
│   │   ├── prisma.js         # Database client
│   │   └── redis.js          # Redis helpers
│   └── routes/
│       ├── auth.js           # Login, register, JWT
│       ├── services.js       # Service listings, search, availability
│       ├── bookings.js       # Booking engine with conflict detection
│       ├── payments.js       # Stripe integration
│       ├── provider.js       # Provider dashboard APIs
│       └── users.js          # User profile, bookmarks, notifications
├── prisma/
│   ├── schema.prisma         # Database schema
│   └── seed.js               # Sample data
└── package.json
```

### 3. Flutter Updates
- **Dio HTTP client** (`lib/services/dio_client.dart`)
  - JWT token auto-refresh
  - Secure token storage
  - Error handling
- **Real API service** (`lib/services/api_service_real.dart`)
  - Replaces mock data with HTTP calls
  - Full CRUD for all entities

### 4. Dependencies Added to pubspec.yaml
```yaml
dio: ^5.4.3+1
flutter_secure_storage: ^9.2.2
pretty_dio_logger: ^1.3.1
```

---

## Next Steps to Run

### 1. Set Up Backend

```bash
# Navigate to backend folder
cd backend

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env - add your database URL and Stripe keys

# Run database migrations
npx prisma migrate dev --name init

# Generate Prisma client
npx prisma generate

# Seed with sample data
node prisma/seed.js

# Start development server
npm run dev
```

### 2. Update Flutter API Base URL

Edit `lib/services/dio_client.dart`:
```dart
// Change this to your backend URL
static const String _baseUrl = 'http://localhost:3000';
// For Android emulator: 'http://10.0.2.2:3000'
// For production: 'https://your-api.com'
```

### 3. Switch from Mock to Real API

Replace the import in your providers/screens:
```dart
// OLD (mock)
import 'package:munasabati/services/api_service.dart';

// NEW (real HTTP)
import 'package:munasabati/services/api_service_real.dart' as api;
```

Or rename `api_service_real.dart` to `api_service.dart` to replace the mock.

### 4. Initialize Dio on App Startup

Add to `main.dart`:
```dart
import 'package:munasabati/services/dio_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  dioClient.initialize();  // Initialize Dio
  runApp(MyApp());
}
```

### 5. Run Flutter App

```bash
flutter pub get
flutter run
```

---

## Test Credentials (After Seeding)

| Role | Email | Password |
|------|-------|----------|
| Consumer | consumer@eventbooker.com | EventBooker@2026 |
| Provider (Hall) | Mohammed@eventbooker.com | EventBooker@2026 |
| Provider (Car) | arhab@eventbooker.com | EventBooker@2026 |
| Provider (Photo) | teshreen@eventbooker.com | EventBooker@2026 |
| Provider (DJ) | dj@eventbooker.com | EventBooker@2026 |
| Admin | admin@eventbooker.com | EventBooker@2026 |

---

## API Endpoints Available

### Public
- `GET /` - Health check
- `GET /docs` - API documentation (Swagger UI)
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

### Authenticated
- `GET /api/v1/auth/me` - Current user
- `GET /api/v1/services` - List services
- `POST /api/v1/bookings` - Create booking
- `GET /api/v1/bookings` - My bookings
- `GET /api/v1/users/bookmarks` - My bookmarks
- `GET /api/v1/users/notifications` - Notifications
- `GET /api/v1/provider/dashboard` - Provider stats

---

## Key Features Implemented

✅ **Authentication**
- JWT access tokens (15 min expiry)
- Refresh token rotation (7 days)
- Secure token storage in Flutter
- Auto token refresh on 401 errors

✅ **Booking Engine**
- Slot locking with Redis (prevents double booking)
- Conflict detection
- Transaction safety
- Dynamic pricing (weekend, seasonal, early-bird)

✅ **Payments**
- Stripe PaymentIntent
- Webhook handling
- Deposit/full payment support

✅ **Provider Dashboard**
- Analytics (revenue, bookings by type)
- Availability management
- Pricing rules editor
- Booking acceptance/rejection

✅ **Search & Discovery**
- Full-text search
- Filters (price, rating, city, type)
- Sorting options

---

## Production Checklist

Before deploying to production:

- [ ] Change JWT secrets in `.env`
- [ ] Set up production PostgreSQL database
- [ ] Configure production Redis
- [ ] Set up Stripe live keys
- [ ] Enable CORS for your domain only
- [ ] Set up SSL/TLS
- [ ] Configure rate limiting
- [ ] Add error monitoring (Sentry)
- [ ] Set up logging (Grafana/Loki)
- [ ] Dockerize backend
- [ ] Set up CI/CD pipeline

---

## Troubleshooting

**Flutter can't connect to backend:**
- Android emulator: Use `10.0.2.2` instead of `localhost`
- iOS simulator: Use `localhost`
- Physical device: Use your computer's IP address

**Database connection errors:**
- Ensure PostgreSQL is running
- Check DATABASE_URL in `.env`
- Run `npx prisma migrate dev`

**Token errors:**
- Clear app data to remove old tokens
- Check JWT_SECRET is set correctly

---

## Files Created/Modified

### New Files:
- `backend/` - Complete Node.js backend
- `lib/services/dio_client.dart` - HTTP client
- `lib/services/api_service_real.dart` - Real API calls
- `BACKEND_SETUP.md` - This file

### Modified:
- `pubspec.yaml` - Added Dio and secure storage dependencies
