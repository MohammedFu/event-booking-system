const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Hash password
  const passwordHash = await bcrypt.hash("password123", 12);

  // Create admin user
  const admin = await prisma.user.create({
    data: {
      email: "admin@eventbooker.com",
      passwordHash,
      fullName: "علي عبده",
      phone: "+967770180062",
      role: "ADMIN",
      isVerified: true,
    },
  });
  console.log("Created admin user:", admin.email);

  // Create consumer user
  const consumer = await prisma.user.create({
    data: {
      email: "consumer@eventbooker.com",
      passwordHash,
      fullName: "فيصل علي",
      phone: "+967770180062",
      role: "CONSUMER",
      isVerified: true,
    },
  });
  console.log("Created consumer user:", consumer.email);

  // Create provider users and their profiles
  const providers = [
    {
      email: "Mohammed@eventbooker.com",
      fullName: "محمد فؤاد",
      businessName: "صالة اوركيد",
      serviceType: "HALL",
      description: "صالة اوركيد للمناسبات",
      city: "صنعاء",
      services: [
        {
          title: "فرقة واما",
          basePrice: 5000,
          maxCapacity: 300,
          attributes: {
            capacity: 300,
            hasStage: true,
            hasParking: true,
            amenities: ["دي جي", "إضاءة", "وجبات"],
          },
        },
        {
          title: "صالة اماسي حدة",
          basePrice: 3500,
          maxCapacity: 150,
          attributes: {
            capacity: 150,
            hasStage: false,
            hasParking: true,
            amenities: ["إضاءة", "كوش"],
          },
        },
      ],
    },
    {
      email: "arhab@eventbooker.com",
      fullName: "أحمد محسن",
      businessName: "ارحب لتأجير السيارات",
      serviceType: "CAR",
      description: "ارحب لتأجير السيارات الفاخرة والحديثة",
      city: "صنعاء",
      services: [
        {
          title: "ليكسز كروز",
          basePrice: 150,
          minDurationHours: 3,
          attributes: {
            make: "lexus",
            model: "cruiser",
            year: 2024,
            maxPassengers: 10,
          },
        },
        {
          title: "لكسز فان",
          basePrice: 800,
          minDurationHours: 4,
          attributes: {
            make: "lexus",
            model: "van",
            year: 2023,
            maxPassengers: 4,
          },
        },
      ],
    },
    {
      email: "teshreen@eventbooker.com",
      fullName: "أحمد فؤاد",
      businessName: "معامل تشيرين للتصوير",
      serviceType: "PHOTOGRAPHER",
      description: "تصوير المناسبات المختلفة",
      city: "صنعاء",
      services: [
        {
          title: "تغطية يوم كامل",
          basePrice: 2500,
          minDurationHours: 8,
          attributes: {
            specialties: ["اعراس", "حفلات"],
            equipment: ["كاميرا", "درون"],
            editingIncluded: true,
          },
        },
        {
          title: "نصف يوم",
          basePrice: 1500,
          minDurationHours: 4,
          attributes: {
            specialties: ["اعراس"],
            equipment: ["كاميرا"],
            editingIncluded: true,
          },
        },
      ],
    },
    {
      email: "dj@eventbooker.com",
      fullName: "أحمد عادل",
      businessName: "فرقة ميامي",
      serviceType: "ENTERTAINER",
      description: "متعهد حفلات وفعاليات",
      city: "صنعاء",
      services: [
        {
          title: "فرقة موسيقية محترفة وفاخرة",
          basePrice: 800,
          minDurationHours: 4,
          attributes: {
            performerType: "دي جي",
            genres: ["الموسيقى العربية", "الموسيقى الغربية"],
            groupSize: 1,
          },
        },
        {
          title: "فرقة موسيقية حية",
          basePrice: 2000,
          minDurationHours: 3,
          attributes: {
            performerType: "فرقة موسيقية حية",
            genres: ["الموسيقى العربية", "الموسيقى الغربية"],
            groupSize: 5,
          },
        },
      ],
    },
  ];

  for (const providerData of providers) {
    // Create user
    const user = await prisma.user.create({
      data: {
        email: providerData.email,
        passwordHash,
        fullName: providerData.fullName,
        phone: "+967770180062",
        role: "PROVIDER",
        isVerified: true,
      },
    });

    // Create provider profile
    const provider = await prisma.provider.create({
      data: {
        userId: user.id,
        businessName: providerData.businessName,
        description: providerData.description,
        serviceType: providerData.serviceType,
        city: providerData.city,
        rating: 4.5 + Math.random() * 0.5,
        reviewCount: Math.floor(Math.random() * 50) + 10,
        isVerified: true,
        isActive: true,
      },
    });

    console.log("Created provider:", provider.businessName);

    // Create services for provider
    for (const serviceData of providerData.services) {
      const service = await prisma.service.create({
        data: {
          providerId: provider.id,
          title: serviceData.title,
          description: `خدمة ${providerData.serviceType.toLowerCase()} مميزة`,
          serviceType: providerData.serviceType,
          basePrice: serviceData.basePrice,
          maxCapacity: serviceData.maxCapacity || null,
          minDurationHours: serviceData.minDurationHours || null,
          attributes: serviceData.attributes,
          tags: [providerData.serviceType.toLowerCase(), "مميز", "حفلات"],
          images: ["https://placehold.co/600x400"],
          isAvailable: true,
        },
      });

      console.log("  Created service:", service.title);

      // Create availability templates (Monday-Sunday)
      for (let day = 0; day < 7; day++) {
        const isWeekend = day === 0 || day === 6;
        await prisma.availabilityTemplate.create({
          data: {
            serviceId: service.id,
            dayOfWeek: day,
            startTime: isWeekend
              ? new Date("1970-01-01T10:00")
              : new Date("1970-01-01T09:00"),
            endTime: new Date("1970-01-01T22:00"),
            isAvailable: true,
          },
        });
      }

      // Create pricing rules
      await prisma.pricingRule.create({
        data: {
          serviceId: service.id,
          ruleType: "WEEKEND",
          multiplier: 1.2,
          priority: 1,
        },
      });
    }
  }

  // Create sample bookings
  const allServices = await prisma.service.findMany({
    include: { provider: true },
  });

  for (let i = 0; i < 5; i++) {
    const service = allServices[i % allServices.length];
    const eventDate = new Date();
    eventDate.setDate(eventDate.getDate() + 30 + i * 7);

    const booking = await prisma.booking.create({
      data: {
        consumerId: consumer.id,
        eventType: "WEDDING",
        eventDate,
        eventName: `حفل زفاف ${i + 1}`,
        status: i < 3 ? "CONFIRMED" : "PENDING",
        totalAmount: parseFloat(service.basePrice),
        depositAmount: parseFloat(service.basePrice) * 0.25,
        depositPaid: i < 3,
        items: {
          create: {
            serviceId: service.id,
            providerId: service.providerId,
            date: eventDate,
            startTime: new Date("1970-01-01T16:00"),
            endTime: new Date("1970-01-01T23:00"),
            durationHours: 7,
            unitPrice: parseFloat(service.basePrice),
            subtotal: parseFloat(service.basePrice) * 7,
            status: i < 3 ? "CONFIRMED" : "PENDING",
          },
        },
      },
      include: { items: true },
    });

    // Create booked slots for confirmed bookings
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

  // Create notifications
  await prisma.notification.createMany({
    data: [
      {
        userId: consumer.id,
        type: "BOOKING_CONFIRMED",
        title: "تم تأكيد الحجز",
        body: "تم تأكيد حجزك!",
      },
      {
        userId: consumer.id,
        type: "PAYMENT_RECEIVED",
        title: "تم استلام الدفعة",
        body: "تم استلام دفعتك!",
      },
      {
        userId: consumer.id,
        type: "REMINDER",
        title: "الحدث القادم",
        body: "الحدث الخاص بك قادم قريبا!",
        isRead: true,
      },
    ],
  });

  console.log("\ اكتمل زرع البيانات بنجاح!");
  console.log("\nبيانات الدخول للتجربة:");
  console.log("  Admin: admin@eventbooker.com / password123");
  console.log("  Consumer: consumer@eventbooker.com / password123");
  console.log(
    "  Providers: Mohammed@eventbooker.com, arhab@eventbooker.com, teshreen@eventbooker.com, dj@eventbooker.com / password123",
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
