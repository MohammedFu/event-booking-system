const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

const SEED_PASSWORD = "EventBooker@2026";
const DEFAULT_PHONE = "+967770180062";

const imageUrl = (photoId) =>
  `https://images.unsplash.com/${photoId}?auto=format&fit=crop&w=1200&q=80`;

const providers = [
  {
    email: "Mohammed@eventbooker.com",
    fullName: "محمد فؤاد",
    businessName: "صالة أوركيد",
    serviceType: "HALL",
    description: "صالة أوركيد للمناسبات والأفراح.",
    city: "صنعاء",
    rating: 4.9,
    reviewCount: 38,
    services: [
      {
        title: "قاعة أوركيد الملكية",
        description: "قاعة واسعة مجهزة للأعراس والمناسبات الكبيرة.",
        basePrice: 5000,
        maxCapacity: 300,
        minDurationHours: 4,
        maxDurationHours: 10,
        tags: ["hall", "wedding", "vip"],
        attributes: {
          capacity: 300,
          hasStage: true,
          hasParking: true,
          hasKitchen: true,
          theme: "classic",
          amenities: ["DJ", "Lighting", "Buffet"],
        },
        images: [
          imageUrl("photo-1519167758481-83f29c78654f"),
          imageUrl("photo-1519741497674-611481863552"),
          imageUrl("photo-1469371670807-013ccf25f16a"),
        ],
      },
      {
        title: "صالة أماسي حدة",
        description: "خيار مثالي للحفلات المتوسطة مع إضاءة وكوشة.",
        basePrice: 3500,
        maxCapacity: 150,
        minDurationHours: 4,
        maxDurationHours: 8,
        tags: ["hall", "party", "family"],
        attributes: {
          capacity: 150,
          hasStage: false,
          hasParking: true,
          hasKitchen: false,
          theme: "modern",
          amenities: ["Lighting", "Kosha"],
        },
        images: [
          imageUrl("photo-1519225421980-715cb0215aed"),
          imageUrl("photo-1505236858219-8359eb29e329"),
          imageUrl("photo-1511285560929-80b456fea0bc"),
        ],
      },
    ],
  },
  {
    email: "arhab@eventbooker.com",
    fullName: "أحمد محسن",
    businessName: "أرحب لتأجير السيارات",
    serviceType: "CAR",
    description: "خدمة تأجير سيارات فاخرة وحديثة للمناسبات.",
    city: "صنعاء",
    rating: 4.7,
    reviewCount: 24,
    services: [
      {
        title: "لكزس كروزر",
        description: "سيارة فاخرة للمشاوير الخاصة ومواكب الأعراس.",
        basePrice: 150,
        minDurationHours: 3,
        maxDurationHours: 12,
        tags: ["car", "luxury", "wedding"],
        attributes: {
          make: "Lexus",
          model: "Cruiser",
          year: 2024,
          color: "White",
          carType: "SUV",
          maxPassengers: 10,
          features: ["Leather Seats", "AC", "Premium Audio"],
        },
        images: [
          imageUrl("photo-1503376780353-7e6692767b70"),
          imageUrl("photo-1494976388531-d1058494cdd8"),
          imageUrl("photo-1544636331-e26879cd4d9b"),
        ],
      },
      {
        title: "لكزس فان",
        description: "فان مريح لنقل العائلة والضيوف بأناقة.",
        basePrice: 800,
        minDurationHours: 4,
        maxDurationHours: 14,
        tags: ["car", "family", "transport"],
        attributes: {
          make: "Lexus",
          model: "Van",
          year: 2023,
          color: "Black",
          carType: "Van",
          maxPassengers: 4,
          features: ["Tinted Windows", "AC", "Wide Cabin"],
        },
        images: [
          imageUrl("photo-1489824904134-891ab64532f1"),
          imageUrl("photo-1502161254066-6c74afbf07aa"),
          imageUrl("photo-1511919884226-fd3cad34687c"),
        ],
      },
    ],
  },
  {
    email: "teshreen@eventbooker.com",
    fullName: "أحمد فؤاد",
    businessName: "معامل تشرين للتصوير",
    serviceType: "PHOTOGRAPHER",
    description: "تصوير احترافي للمناسبات مع مونتاج وتسليم سريع.",
    city: "صنعاء",
    rating: 4.8,
    reviewCount: 31,
    services: [
      {
        title: "تغطية يوم كامل",
        description: "تغطية كاملة للحفل من الاستعدادات حتى نهاية المناسبة.",
        basePrice: 2500,
        minDurationHours: 8,
        maxDurationHours: 12,
        tags: ["photo", "full-day", "wedding"],
        attributes: {
          specialties: ["Weddings", "Events"],
          equipment: ["Camera", "Drone", "Gimbal"],
          editingIncluded: true,
          portfolioUrl: "https://example.com/teshreen-portfolio",
        },
        images: [
          imageUrl("photo-1520854221256-17451cc331bf"),
          imageUrl("photo-1516035069371-29a1b244cc32"),
          imageUrl("photo-1492691527719-9d1e07e534b4"),
        ],
      },
      {
        title: "نصف يوم تصوير",
        description: "جلسة تصوير مركزة للمناسبات القصيرة والخطوبات.",
        basePrice: 1500,
        minDurationHours: 4,
        maxDurationHours: 6,
        tags: ["photo", "engagement", "half-day"],
        attributes: {
          specialties: ["Weddings"],
          equipment: ["Camera", "Lighting Kit"],
          editingIncluded: true,
        },
        images: [
          imageUrl("photo-1511285560929-80b456fea0bc"),
          imageUrl("photo-1500530855697-b586d89ba3ee"),
          imageUrl("photo-1460353581641-37baddab0fa2"),
        ],
      },
    ],
  },
  {
    email: "dj@eventbooker.com",
    fullName: "أحمد عادل",
    businessName: "فرقة ميامي",
    serviceType: "ENTERTAINER",
    description: "فرق موسيقية ودي جي لإحياء الحفلات والفعاليات.",
    city: "صنعاء",
    rating: 4.6,
    reviewCount: 19,
    services: [
      {
        title: "دي جي احترافي",
        description: "دي جي مع أنظمة صوت وإضاءة للحفلات الخاصة.",
        basePrice: 800,
        minDurationHours: 4,
        maxDurationHours: 8,
        tags: ["dj", "party", "music"],
        attributes: {
          performerType: "DJ",
          genres: ["Arabic", "International"],
          groupSize: 1,
          sampleVideoUrl: "https://example.com/dj-sample",
        },
        images: [
          imageUrl("photo-1493225457124-a3eb161ffa5f"),
          imageUrl("photo-1501386761578-eac5c94b800a"),
          imageUrl("photo-1514525253161-7a46d19cd819"),
        ],
      },
      {
        title: "فرقة موسيقية حية",
        description: "فرقة حية للمسرح والزفات والفعاليات الكبيرة.",
        basePrice: 2000,
        minDurationHours: 3,
        maxDurationHours: 6,
        tags: ["band", "live", "wedding"],
        attributes: {
          performerType: "Live Band",
          genres: ["Arabic", "International"],
          groupSize: 5,
          sampleVideoUrl: "https://example.com/live-band-sample",
        },
        images: [
          imageUrl("photo-1506157786151-b8491531f063"),
          imageUrl("photo-1521334884684-d80222895322"),
          imageUrl("photo-1499364615650-ec38552f4f34"),
        ],
      },
    ],
  },
];

async function upsertUser({
  email,
  passwordHash,
  fullName,
  phone = DEFAULT_PHONE,
  role,
}) {
  return prisma.user.upsert({
    where: { email },
    update: {
      passwordHash,
      fullName,
      phone,
      role,
      isVerified: true,
      isActive: true,
    },
    create: {
      email,
      passwordHash,
      fullName,
      phone,
      role,
      isVerified: true,
      isActive: true,
    },
  });
}

async function upsertProviderProfile(userId, providerData) {
  return prisma.provider.upsert({
    where: { userId },
    update: {
      businessName: providerData.businessName,
      description: providerData.description,
      serviceType: providerData.serviceType,
      city: providerData.city,
      rating: providerData.rating,
      reviewCount: providerData.reviewCount,
      isVerified: true,
      isActive: true,
    },
    create: {
      userId,
      businessName: providerData.businessName,
      description: providerData.description,
      serviceType: providerData.serviceType,
      city: providerData.city,
      rating: providerData.rating,
      reviewCount: providerData.reviewCount,
      isVerified: true,
      isActive: true,
    },
  });
}

async function upsertService(providerId, providerData, serviceData) {
  const existingService = await prisma.service.findFirst({
    where: {
      providerId,
      title: serviceData.title,
    },
  });

  const servicePayload = {
    title: serviceData.title,
    description:
      serviceData.description ||
      `Featured ${providerData.serviceType.toLowerCase()} service`,
    serviceType: providerData.serviceType,
    basePrice: serviceData.basePrice,
    currency: serviceData.currency || "YER",
    pricingModel: serviceData.pricingModel || "FLAT",
    maxCapacity: serviceData.maxCapacity ?? null,
    minDurationHours: serviceData.minDurationHours ?? null,
    maxDurationHours: serviceData.maxDurationHours ?? null,
    attributes: serviceData.attributes || {},
    tags:
      serviceData.tags ||
      [providerData.serviceType.toLowerCase(), "featured", "events"],
    images:
      serviceData.images || [imageUrl("photo-1511795409834-ef04bbd61622")],
    isAvailable: true,
  };

  if (existingService) {
    return prisma.service.update({
      where: { id: existingService.id },
      data: servicePayload,
    });
  }

  return prisma.service.create({
    data: {
      providerId,
      ...servicePayload,
    },
  });
}

async function ensureAvailabilityTemplates(serviceId) {
  const existingTemplates = await prisma.availabilityTemplate.count({
    where: { serviceId },
  });

  if (existingTemplates > 0) {
    return;
  }

  for (let day = 0; day < 7; day++) {
    const isWeekend = day === 0 || day === 6;
    await prisma.availabilityTemplate.create({
      data: {
        serviceId,
        dayOfWeek: day,
        startTime: isWeekend
          ? new Date("1970-01-01T10:00")
          : new Date("1970-01-01T09:00"),
        endTime: new Date("1970-01-01T22:00"),
        isAvailable: true,
      },
    });
  }
}

async function ensureWeekendPricingRule(serviceId) {
  const existingRule = await prisma.pricingRule.findFirst({
    where: {
      serviceId,
      ruleType: "WEEKEND",
    },
  });

  if (existingRule) {
    return;
  }

  await prisma.pricingRule.create({
    data: {
      serviceId,
      ruleType: "WEEKEND",
      multiplier: 1.2,
      priority: 1,
    },
  });
}

async function ensureSampleBookings(consumerId) {
  const existingBookings = await prisma.booking.count({
    where: { consumerId },
  });

  if (existingBookings > 0) {
    return;
  }

  const allServices = await prisma.service.findMany({
    include: { provider: true },
  });

  const bookingCount = Math.min(5, allServices.length);

  for (let i = 0; i < bookingCount; i++) {
    const service = allServices[i];
    const eventDate = new Date();
    eventDate.setDate(eventDate.getDate() + 30 + i * 7);

    const basePrice = Number(service.basePrice);
    const booking = await prisma.booking.create({
      data: {
        consumerId,
        eventType: "WEDDING",
        eventDate,
        eventName: `حفل زفاف ${i + 1}`,
        status: i < 3 ? "CONFIRMED" : "PENDING",
        totalAmount: basePrice,
        depositAmount: basePrice * 0.25,
        depositPaid: i < 3,
        items: {
          create: {
            serviceId: service.id,
            providerId: service.providerId,
            date: eventDate,
            startTime: new Date("1970-01-01T16:00"),
            endTime: new Date("1970-01-01T23:00"),
            durationHours: 7,
            unitPrice: basePrice,
            subtotal: basePrice * 7,
            status: i < 3 ? "CONFIRMED" : "PENDING",
          },
        },
      },
      include: { items: true },
    });

    if (i < 3) {
      await prisma.bookedSlot.create({
        data: {
          serviceId: service.id,
          bookingId: booking.id,
          date: eventDate,
          startTime: new Date("1970-01-01T16:00"),
          endTime: new Date("1970-01-01T23:00"),
          status: "CONFIRMED",
        },
      });
    }
  }
}

async function ensureNotifications(consumerId) {
  const notificationCount = await prisma.notification.count({
    where: { userId: consumerId },
  });

  if (notificationCount > 0) {
    return;
  }

  await prisma.notification.createMany({
    data: [
      {
        userId: consumerId,
        type: "BOOKING_CONFIRMED",
        title: "تم تأكيد الحجز",
        body: "تم تأكيد حجزك بنجاح.",
      },
      {
        userId: consumerId,
        type: "PAYMENT_RECEIVED",
        title: "تم استلام الدفعة",
        body: "تم تسجيل الدفعة الخاصة بك بنجاح.",
      },
      {
        userId: consumerId,
        type: "REMINDER",
        title: "تذكير بموعد الحفل",
        body: "موعد حفلك يقترب، تأكد من مراجعة تفاصيل الحجز.",
        isRead: true,
      },
    ],
  });
}

async function main() {
  console.log("Seeding database...");

  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 12);

  const admin = await upsertUser({
    email: "admin@eventbooker.com",
    passwordHash,
    fullName: "علي عبده",
    role: "ADMIN",
  });
  console.log("Upserted admin user:", admin.email);

  const consumer = await upsertUser({
    email: "consumer@eventbooker.com",
    passwordHash,
    fullName: "فيصل علي",
    role: "CONSUMER",
  });
  console.log("Upserted consumer user:", consumer.email);

  const seededUserIds = [admin.id, consumer.id];

  for (const providerData of providers) {
    const user = await upsertUser({
      email: providerData.email,
      passwordHash,
      fullName: providerData.fullName,
      role: "PROVIDER",
    });
    seededUserIds.push(user.id);

    const provider = await upsertProviderProfile(user.id, providerData);
    console.log("Upserted provider:", provider.businessName);

    for (const serviceData of providerData.services) {
      const service = await upsertService(provider.id, providerData, serviceData);
      console.log("  Upserted service:", service.title);

      await ensureAvailabilityTemplates(service.id);
      await ensureWeekendPricingRule(service.id);
    }
  }

  await prisma.refreshToken.deleteMany({
    where: {
      userId: {
        in: seededUserIds,
      },
    },
  });

  await ensureSampleBookings(consumer.id);
  await ensureNotifications(consumer.id);

  console.log("\nSeed completed successfully!");
  console.log(`\nShared password for all seeded users: ${SEED_PASSWORD}`);
  console.log("  Admin: admin@eventbooker.com");
  console.log("  Consumer: consumer@eventbooker.com");
  console.log(
    "  Providers: Mohammed@eventbooker.com, arhab@eventbooker.com, teshreen@eventbooker.com, dj@eventbooker.com",
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
