-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('CONSUMER', 'PROVIDER', 'ADMIN');

-- CreateEnum
CREATE TYPE "service_type" AS ENUM ('HALL', 'CAR', 'PHOTOGRAPHER', 'ENTERTAINER');

-- CreateEnum
CREATE TYPE "pricing_model" AS ENUM ('FLAT', 'HOURLY', 'PER_EVENT', 'TIERED');

-- CreateEnum
CREATE TYPE "slot_status" AS ENUM ('CONFIRMED', 'CANCELLED', 'COMPLETED', 'NO_SHOW');

-- CreateEnum
CREATE TYPE "pricing_rule_type" AS ENUM ('SEASONAL', 'WEEKEND', 'PEAK', 'EARLY_BIRD', 'LAST_MINUTE', 'BULK_DISCOUNT');

-- CreateEnum
CREATE TYPE "event_type" AS ENUM ('WEDDING', 'BIRTHDAY', 'CORPORATE', 'ENGAGEMENT', 'OTHER');

-- CreateEnum
CREATE TYPE "booking_status" AS ENUM ('DRAFT', 'PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "booking_item_status" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "payment_method" AS ENUM ('CARD', 'BANK_TRANSFER', 'WALLET', 'CASH');

-- CreateEnum
CREATE TYPE "payment_status" AS ENUM ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'REFUNDED', 'PARTIALLY_REFUNDED');

-- CreateEnum
CREATE TYPE "notification_type" AS ENUM ('BOOKING_CONFIRMED', 'BOOKING_CANCELLED', 'PAYMENT_RECEIVED', 'REMINDER', 'REVIEW_REQUEST', 'PROVIDER_MESSAGE', 'PRICE_DROP', 'SYSTEM');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "phone" TEXT,
    "full_name" TEXT NOT NULL,
    "avatar_url" TEXT,
    "role" "user_role" NOT NULL DEFAULT 'CONSUMER',
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "preferences" JSONB DEFAULT '{}',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "providers" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "business_name" TEXT NOT NULL,
    "description" TEXT,
    "logo_url" TEXT,
    "cover_url" TEXT,
    "service_type" "service_type" NOT NULL,
    "rating" DECIMAL(3,2) NOT NULL DEFAULT 0,
    "review_count" INTEGER NOT NULL DEFAULT 0,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "location" point,
    "address" TEXT,
    "city" TEXT,
    "country" TEXT,
    "contact_phone" TEXT,
    "contact_email" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "providers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "services" (
    "id" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "service_type" "service_type" NOT NULL,
    "base_price" DECIMAL(12,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'YER',
    "pricing_model" "pricing_model" NOT NULL DEFAULT 'FLAT',
    "images" JSONB DEFAULT '[]',
    "tags" JSONB DEFAULT '[]',
    "attributes" JSONB DEFAULT '{}',
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "max_capacity" INTEGER,
    "min_duration_hrs" DECIMAL(4,2),
    "max_duration_hrs" DECIMAL(4,2),
    "cancellation_policy" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "availability_templates" (
    "id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "day_of_week" INTEGER NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "effective_from" TIMESTAMP(3),
    "effective_to" TIMESTAMP(3),

    CONSTRAINT "availability_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booked_slots" (
    "id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "booking_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "status" "slot_status" NOT NULL DEFAULT 'CONFIRMED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booked_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pricing_rules" (
    "id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "rule_type" "pricing_rule_type" NOT NULL,
    "multiplier" DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    "fixed_adjustment" DECIMAL(12,2),
    "start_date" TIMESTAMP(3),
    "end_date" TIMESTAMP(3),
    "day_of_week" INTEGER,
    "min_advance_days" INTEGER,
    "min_bookings" INTEGER,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pricing_rules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bookings" (
    "id" TEXT NOT NULL,
    "consumer_id" TEXT NOT NULL,
    "event_type" "event_type" NOT NULL DEFAULT 'WEDDING',
    "event_date" DATE NOT NULL,
    "event_name" TEXT,
    "status" "booking_status" NOT NULL DEFAULT 'PENDING',
    "total_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'YER',
    "deposit_amount" DECIMAL(12,2),
    "deposit_paid" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "special_requests" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking_items" (
    "id" TEXT NOT NULL,
    "booking_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "start_time" TIME NOT NULL,
    "end_time" TIME NOT NULL,
    "duration_hours" DECIMAL(4,2),
    "unit_price" DECIMAL(12,2) NOT NULL,
    "applied_pricing" JSONB,
    "subtotal" DECIMAL(12,2) NOT NULL,
    "status" "booking_item_status" NOT NULL DEFAULT 'PENDING',
    "special_requests" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "booking_id" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'YER',
    "payment_method" "payment_method" NOT NULL,
    "stripe_payment_intent_id" TEXT,
    "status" "payment_status" NOT NULL DEFAULT 'PENDING',
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reviews" (
    "id" TEXT NOT NULL,
    "booking_item_id" TEXT NOT NULL,
    "consumer_id" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "images" JSONB DEFAULT '[]',
    "is_anonymous" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "notification_type" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_preferences" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "preferred_hall_themes" JSONB DEFAULT '[]',
    "preferred_car_types" JSONB DEFAULT '[]',
    "preferred_photographer_styles" JSONB DEFAULT '[]',
    "preferred_entertainer_types" JSONB DEFAULT '[]',
    "budget_range" JSONB,
    "preferred_cities" JSONB DEFAULT '[]',
    "notification_settings" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bookmarks" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bookmarks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "providers_user_id_key" ON "providers"("user_id");

-- CreateIndex
CREATE INDEX "providers_service_type_idx" ON "providers"("service_type");

-- CreateIndex
CREATE INDEX "services_service_type_idx" ON "services"("service_type");

-- CreateIndex
CREATE INDEX "services_provider_id_idx" ON "services"("provider_id");

-- CreateIndex
CREATE INDEX "booked_slots_service_id_date_idx" ON "booked_slots"("service_id", "date");

-- CreateIndex
CREATE INDEX "bookings_consumer_id_idx" ON "bookings"("consumer_id");

-- CreateIndex
CREATE INDEX "bookings_event_date_idx" ON "bookings"("event_date");

-- CreateIndex
CREATE INDEX "bookings_status_idx" ON "bookings"("status");

-- CreateIndex
CREATE INDEX "notifications_user_id_is_read_idx" ON "notifications"("user_id", "is_read");

-- CreateIndex
CREATE UNIQUE INDEX "user_preferences_user_id_key" ON "user_preferences"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "bookmarks_user_id_service_id_key" ON "bookmarks"("user_id", "service_id");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "providers" ADD CONSTRAINT "providers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "services" ADD CONSTRAINT "services_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "availability_templates" ADD CONSTRAINT "availability_templates_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booked_slots" ADD CONSTRAINT "booked_slots_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booked_slots" ADD CONSTRAINT "booked_slots_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pricing_rules" ADD CONSTRAINT "pricing_rules_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_consumer_id_fkey" FOREIGN KEY ("consumer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_items" ADD CONSTRAINT "booking_items_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_items" ADD CONSTRAINT "booking_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_booking_item_id_fkey" FOREIGN KEY ("booking_item_id") REFERENCES "booking_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_consumer_id_fkey" FOREIGN KEY ("consumer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookmarks" ADD CONSTRAINT "bookmarks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookmarks" ADD CONSTRAINT "bookmarks_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE CASCADE ON UPDATE CASCADE;
