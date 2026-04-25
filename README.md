# Event & Wedding Booking System (Munasabati)

A comprehensive event booking platform built with Flutter (frontend) and Node.js (backend). Users can book halls, cars, photographers, and entertainers for their events.

## 🚀 Quick Start Guide

This guide will help you set up and run the entire application on your new laptop.

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your Windows laptop:

### 1. **Node.js** (Required for Backend)

- Download and install Node.js LTS version (v20 or higher)
- Visit: https://nodejs.org/
- During installation, accept all default options
- Verify installation: Open Command Prompt/PowerShell and run:
  ```bash
  node --version
  npm --version
  ```

### 2. **Flutter SDK** (Required for Frontend)

- Download Flutter SDK for Windows
- Visit: https://flutter.dev/docs/get-started/install/windows
- Extract the downloaded zip file to a location (e.g., `C:\flutter`)
- Add Flutter to your PATH:
  - Search for "Edit the system environment variables" in Windows
  - Click "Environment Variables"
  - Under "System variables", find "Path" and click "Edit"
  - Click "New" and add `C:\flutter\bin`
  - Click OK on all dialogs
- Verify installation: Open a NEW Command Prompt/PowerShell and run:
  ```bash
  flutter --version
  flutter doctor
  ```
- Follow any instructions from `flutter doctor` to fix missing dependencies (e.g., Android Studio, Visual Studio, etc.)

### 3. **PostgreSQL** (Required for Database)

- Download and install PostgreSQL
- Visit: https://www.postgresql.org/download/windows/
- During installation:
  - Set a password (remember it, you'll need it later)
  - Accept default port (5432)
- Verify installation: Open SQL Shell (psql) from Start Menu and login with your password

### 4. **Redis** (Required for Caching & Slot Locking)

- Download Redis for Windows
- Visit: https://github.com/microsoftarchive/redis/releases
- Download the .msi installer and run it
- Accept default options
- Redis will run as a Windows service

### 5. **Git** (Optional but Recommended)

- Download and install Git
- Visit: https://git-scm.com/download/win
- Accept default options during installation

---

## 🛠️ Backend Setup

### Step 1: Navigate to Backend Folder

Open Command Prompt/PowerShell and navigate to the backend directory:

```bash
cd d:\event-booking-system\backend
```

### Step 2: Install Node.js Dependencies

```bash
npm install
```

This will install all required packages listed in `package.json`.

### Step 3: Set Up Environment Variables

```bash
copy .env.example .env
```

Now edit the `.env` file with a text editor (Notepad, VS Code, etc.):

```bash
notepad .env
```

Update the following values in `.env`:

```env
# Database Connection
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/event_booking?schema=public"

# JWT Secrets (change these in production!)
JWT_SECRET="your-super-secret-jwt-key-change-this"
JWT_REFRESH_SECRET="your-refresh-secret-key-change-this"

# Redis Connection
REDIS_HOST="localhost"
REDIS_PORT=6379

# Stripe (optional - for payments)
STRIPE_SECRET_KEY="sk_test_your_stripe_key"
STRIPE_WEBHOOK_SECRET="whsec_your_webhook_secret"

# Server Port
PORT=3000
NODE_ENV=development
```

**Important:** Replace `YOUR_PASSWORD` with the PostgreSQL password you set during installation.

### Step 4: Set Up Database

```bash
# Run database migrations
npx prisma migrate dev --name init

# Generate Prisma client
npx prisma generate

# Seed database with sample data
node prisma/seed.js
```

### Step 5: Start Backend Server

```bash
npm run dev
```

The backend server will start on `http://localhost:3000`
You should see: `Server listening on http://[::]:3000`

**Keep this terminal open!** The backend needs to keep running.

---

## 📱 Flutter App Setup

### Step 1: Navigate to Project Root

Open a NEW Command Prompt/PowerShell terminal:

```bash
cd d:\event-booking-system
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Verify Flutter Setup

```bash
flutter doctor
```

Ensure all required items have checkmarks. If Android Studio or Visual Studio is missing, install them as suggested.

### Step 4: Configure API Base URL (if needed)

The app should already be configured to connect to `http://localhost:3000`. If you need to change it:

Edit `lib/services/dio_client.dart` (if it exists):

```dart
static const String _baseUrl = 'http://localhost:3000';
```

**Note for Android Emulator:** Use `http://10.0.2.2:3000` instead of `localhost`

**Note for Physical Device:** Use your computer's IP address (e.g., `http://192.168.1.5:3000`)

### Step 5: Run the Flutter App

#### Option A: Run on Android Emulator

1. Open Android Studio
2. Go to Tools → Device Manager
3. Create a new Virtual Device (Pixel 5 or similar)
4. Start the emulator
5. In your terminal:
   ```bash
   flutter run
   ```

#### Option B: Run on Physical Android Device

1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect phone via USB
4. In your terminal:
   ```bash
   flutter devices
   flutter run
   ```

#### Option C: Run on iOS Simulator (Mac only)

```bash
open -a Simulator
flutter run
```

#### Option D: Run on Web

```bash
flutter run -d chrome
```

---

## 🔑 Test Credentials

After seeding the database, you can use these credentials to log in:

| Role             | Email                    | Password         |
| ---------------- | ------------------------ | ---------------- |
| Consumer         | consumer@eventbooker.com | EventBooker@2026 |
| Provider (Hall)  | Mohammed@eventbooker.com | EventBooker@2026 |
| Provider (Car)   | arhab@eventbooker.com    | EventBooker@2026 |
| Provider (Photo) | teshreen@eventbooker.com | EventBooker@2026 |
| Provider (DJ)    | dj@eventbooker.com       | EventBooker@2026 |
| Admin            | admin@eventbooker.com    | EventBooker@2026 |

---

## 🐛 Troubleshooting

### Backend Issues

**"Cannot connect to database"**

- Ensure PostgreSQL is running (check Windows Services)
- Verify password in `.env` matches your PostgreSQL password
- Try: `psql -U postgres -d event_booking` to test connection

**"Redis connection failed"**

- Ensure Redis service is running (check Windows Services)
- Open Task Manager and look for redis-server.exe

**"Port 3000 already in use"**

- Kill the process using port 3000:
  ```bash
  netstat -ano | findstr :3000
  taskkill /PID <PID> /F
  ```

### Flutter Issues

**"No connected devices"**

- Ensure Android emulator is running or physical device is connected
- Run `flutter devices` to see available devices
- Run `flutter doctor` to check for issues

**"Flutter command not found"**

- Close and reopen your terminal (PATH changes need new terminal)
- Verify Flutter is in your PATH: `echo %PATH%`

**"Gradle build failed"**

- Run: `flutter clean`
- Then: `flutter pub get`
- Then: `flutter run` again

**"Cannot connect to backend from app"**

- For Android emulator: Change API URL to `http://10.0.2.2:3000`
- For physical device: Use your computer's IP address (find it with `ipconfig`)
- Ensure backend server is running
- Check Windows Firewall isn't blocking port 3000

---

## 📁 Project Structure

```
event-booking-system/
├── backend/              # Node.js backend
│   ├── src/             # Source code
│   ├── prisma/          # Database schema & migrations
│   └── uploads/         # Uploaded files
├── lib/                 # Flutter app source
│   ├── components/      # Reusable UI components
│   ├── screens/         # App screens
│   ├── services/        # API services
│   └── models/          # Data models
├── android/             # Android-specific files
├── ios/                 # iOS-specific files
└── assets/              # Images, fonts, locales
```

---

## 🌐 API Endpoints

Once the backend is running, you can access:

- **API Base URL:** `http://localhost:3000`
- **Health Check:** `http://localhost:3000/`
- **API Documentation:** `http://localhost:3000/docs` (Swagger UI)

### Main Endpoints:

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/services` - List services
- `POST /api/v1/bookings` - Create booking
- `GET /api/v1/bookings` - Get user bookings

---

## 🚀 Running with Docker (Alternative)

If you have Docker installed, you can run everything with Docker Compose:

```bash
# From project root
docker-compose up -d
```

This will start PostgreSQL, Redis, and the backend server automatically.

---

## 📝 Additional Documentation

- **Architecture Details:** See `ARCHITECTURE.md`
- **Backend Setup:** See `BACKEND_SETUP.md`

---

## 🤝 Support

If you encounter any issues not covered here:

1. Check the troubleshooting section above
2. Review `ARCHITECTURE.md` for technical details
3. Review `BACKEND_SETUP.md` for backend-specific issues

---

## ✨ Features

- **User Authentication:** JWT-based secure authentication
- **Service Booking:** Book halls, cars, photographers, entertainers
- **Provider Dashboard:** Manage services, availability, and bookings
- **Real-time Updates:** WebSocket integration for live updates
- **Payment Integration:** Stripe payment processing
- **Multi-language:** Support for Arabic and English
- **Dark/Light Theme:** Beautiful UI with theme support

---

Happy coding! 🎉
