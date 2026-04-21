const zod = require("zod");
const prisma = require("../lib/prisma");
const fs = require("fs");
const path = require("path");

// Validation schemas
const updateAvailabilitySchema = zod.object({
  templates: zod.array(
    zod.object({
      dayOfWeek: zod.number().int().min(0).max(6),
      startTime: zod.string(), // HH:mm
      endTime: zod.string(),
      isAvailable: zod.boolean().default(true),
    }),
  ),
});

const createServiceSchema = zod.object({
  title: zod.string().min(1).max(200),
  description: zod.string().optional(),
  serviceType: zod.enum(["HALL", "CAR", "PHOTOGRAPHER", "ENTERTAINER"]),
  basePrice: zod.number().positive(),
  currency: zod.string().default("YER"),
  pricingModel: zod
    .enum(["FLAT", "HOURLY", "PER_EVENT", "TIERED"])
    .default("FLAT"),
  images: zod.array(zod.string().url()).default([]),
  tags: zod.array(zod.string()).default([]),
  maxCapacity: zod.number().int().positive().optional(),
  minDurationHours: zod.number().positive().optional(),
  maxDurationHours: zod.number().positive().optional(),
  isAvailable: zod.boolean().default(true),
  attributes: zod.object({}).passthrough().optional(),
  cancellationPolicy: zod
    .object({
      freeCancellationHours: zod.number().int().default(72),
      partialRefundPercentage: zod.number().default(50),
      depositRefundable: zod.boolean().default(false),
      description: zod.string().optional(),
    })
    .optional(),
});

const updateServiceSchema = zod.object({
  title: zod.string().min(1).max(200).optional(),
  description: zod.string().optional(),
  basePrice: zod.number().positive().optional(),
  currency: zod.string().optional(),
  pricingModel: zod.enum(["FLAT", "HOURLY", "PER_EVENT", "TIERED"]).optional(),
  images: zod.array(zod.string().url()).optional(),
  tags: zod.array(zod.string()).optional(),
  maxCapacity: zod.number().int().positive().optional(),
  minDurationHours: zod.number().positive().optional(),
  maxDurationHours: zod.number().positive().optional(),
  isAvailable: zod.boolean().optional(),
  attributes: zod.object({}).passthrough().optional(),
  cancellationPolicy: zod
    .object({
      freeCancellationHours: zod.number().int().optional(),
      partialRefundPercentage: zod.number().optional(),
      depositRefundable: zod.boolean().optional(),
      description: zod.string().optional(),
    })
    .optional(),
});

const createPricingRuleSchema = zod.object({
  serviceId: zod.string().uuid(),
  ruleType: zod.enum([
    "SEASONAL",
    "WEEKEND",
    "PEAK",
    "EARLY_BIRD",
    "LAST_MINUTE",
    "BULK_DISCOUNT",
  ]),
  multiplier: zod.number().default(1.0),
  fixedAdjustment: zod.number().optional(),
  startDate: zod.coerce.date().optional(),
  endDate: zod.coerce.date().optional(),
  dayOfWeek: zod.number().int().min(0).max(6).optional(),
  minAdvanceDays: zod.number().int().optional(),
  minBookings: zod.number().int().optional(),
  priority: zod.number().int().default(0),
});

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // GET /dashboard (Provider dashboard stats)
  // ═══════════════════════════════════════════════════════════
  fastify.get("/dashboard", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Get provider dashboard statistics",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      // Get provider profile
      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Get stats
      const [
        totalBookings,
        pendingBookings,
        completedBookings,
        cancelledBookings,
        totalRevenue,
        recentBookings,
      ] = await Promise.all([
        // Total bookings
        prisma.bookingItem.count({
          where: { providerId: provider.id },
        }),
        // Pending bookings
        prisma.bookingItem.count({
          where: { providerId: provider.id, status: "PENDING" },
        }),
        // Completed bookings
        prisma.bookingItem.count({
          where: { providerId: provider.id, status: "COMPLETED" },
        }),
        // Cancelled bookings
        prisma.bookingItem.count({
          where: { providerId: provider.id, status: "CANCELLED" },
        }),
        // Total revenue
        prisma.bookingItem.aggregate({
          where: {
            providerId: provider.id,
            status: { in: ["CONFIRMED", "COMPLETED"] },
          },
          _sum: { subtotal: true },
        }),
        // Recent bookings
        prisma.bookingItem.findMany({
          where: { providerId: provider.id },
          include: {
            booking: {
              select: {
                id: true,
                eventName: true,
                eventDate: true,
                status: true,
              },
            },
            service: {
              select: {
                id: true,
                title: true,
              },
            },
          },
          orderBy: { createdAt: "desc" },
          take: 10,
        }),
      ]);

      // Get bookings by service type
      const bookingsByType = await prisma.bookingItem.groupBy({
        by: ["serviceId"],
        where: { providerId: provider.id },
        _count: { id: true },
      });

      return {
        success: true,
        data: {
          totalBookings,
          pendingBookings,
          completedBookings,
          cancelledBookings,
          averageRating: provider.rating,
          totalRevenue: totalRevenue._sum.subtotal || 0,
          recentBookings,
          bookingsByType,
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /bookings (List provider bookings)
  // ═══════════════════════════════════════════════════════════
  fastify.get("/bookings", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Get provider bookings",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      querystring: {
        type: "object",
        properties: {
          status: { type: "string" },
          page: { type: "number" },
          limit: { type: "number" },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { status, page = 1, limit = 20 } = request.query;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      const skip = (page - 1) * limit;
      const where = { providerId: provider.id };
      if (status) where.status = status;

      const [items, total] = await Promise.all([
        prisma.bookingItem.findMany({
          where,
          include: {
            booking: {
              include: {
                consumer: {
                  select: {
                    id: true,
                    fullName: true,
                    phone: true,
                  },
                },
              },
            },
            service: {
              select: {
                id: true,
                title: true,
              },
            },
          },
          orderBy: { createdAt: "desc" },
          skip,
          take: limit,
        }),
        prisma.bookingItem.count({ where }),
      ]);

      return {
        success: true,
        data: items,
        meta: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PATCH /bookings/:id/status (Accept/reject booking)
  // ═══════════════════════════════════════════════════════════
  fastify.patch("/bookings/:id/status", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Update booking item status",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      params: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string" },
        },
      },
      body: {
        type: "object",
        required: ["status"],
        properties: {
          status: {
            type: "string",
            enum: ["PENDING", "CONFIRMED", "CANCELLED", "COMPLETED"],
          },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;
      const { status } = request.body;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      const bookingItem = await prisma.bookingItem.findFirst({
        where: {
          id,
          providerId: provider.id,
        },
        include: { booking: true },
      });

      if (!bookingItem) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Booking not found",
        });
      }

      // Update booking item
      const updated = await prisma.bookingItem.update({
        where: { id },
        data: { status },
      });

      // If confirmed, create booked slot
      if (status === "CONFIRMED") {
        await prisma.bookedSlot.create({
          data: {
            serviceId: bookingItem.serviceId,
            bookingId: bookingItem.bookingId,
            date: bookingItem.date,
            startTime: bookingItem.startTime,
            endTime: bookingItem.endTime,
            status: "CONFIRMED",
          },
        });
      }

      // Update main booking status if all items are confirmed/cancelled
      const allItems = await prisma.bookingItem.findMany({
        where: { bookingId: bookingItem.bookingId },
      });

      const allConfirmed = allItems.every((item) =>
        ["CONFIRMED", "COMPLETED"].includes(item.status),
      );
      const allCancelled = allItems.every(
        (item) => item.status === "CANCELLED",
      );

      if (allConfirmed) {
        await prisma.booking.update({
          where: { id: bookingItem.bookingId },
          data: { status: "CONFIRMED" },
        });
      } else if (allCancelled) {
        await prisma.booking.update({
          where: { id: bookingItem.bookingId },
          data: { status: "CANCELLED" },
        });
      }

      return {
        success: true,
        data: updated,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // CRUD /services (Manage services)
  // ═══════════════════════════════════════════════════════════
  fastify.get("/services", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Get provider services",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const provider = await prisma.provider.findUnique({
        where: { userId },
        include: {
          services: {
            include: {
              availabilityTemplates: true,
              pricingRules: {
                where: { isActive: true },
              },
            },
          },
        },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      return {
        success: true,
        data: provider.services,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /services (Create new service with images)
  // ═══════════════════════════════════════════════════════════
  fastify.post("/services", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Create a new service with images",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      body: {
        type: "object",
        required: ["title", "serviceType", "basePrice"],
        properties: {
          title: { type: "string", minLength: 1, maxLength: 200 },
          description: { type: "string" },
          serviceType: {
            type: "string",
            enum: ["HALL", "CAR", "PHOTOGRAPHER", "ENTERTAINER"],
          },
          basePrice: { type: "number", minimum: 0 },
          currency: { type: "string", default: "YER" },
          pricingModel: {
            type: "string",
            enum: ["FLAT", "HOURLY", "PER_EVENT", "TIERED"],
          },
          images: { type: "array", items: { type: "string", format: "uri" } },
          tags: { type: "array", items: { type: "string" } },
          maxCapacity: { type: "integer", minimum: 1 },
          minDurationHours: { type: "number", minimum: 0.5 },
          maxDurationHours: { type: "number", minimum: 0.5 },
          isAvailable: { type: "boolean", default: true },
          attributes: { type: "object" },
          cancellationPolicy: { type: "object" },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = createServiceSchema.parse(request.body);

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      const service = await prisma.service.create({
        data: {
          providerId: provider.id,
          title: validated.title,
          description: validated.description,
          serviceType: validated.serviceType,
          basePrice: validated.basePrice,
          currency: validated.currency,
          pricingModel: validated.pricingModel,
          images: validated.images,
          tags: validated.tags,
          maxCapacity: validated.maxCapacity,
          minDurationHours: validated.minDurationHours,
          maxDurationHours: validated.maxDurationHours,
          isAvailable: validated.isAvailable,
          attributes: validated.attributes,
          cancellationPolicy: validated.cancellationPolicy,
        },
        include: {
          availabilityTemplates: true,
          pricingRules: {
            where: { isActive: true },
          },
        },
      });

      reply.code(201);
      return {
        success: true,
        data: service,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PUT /services/:id (Update service with images)
  // ═══════════════════════════════════════════════════════════
  fastify.put("/services/:id", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Update service including images",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      params: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string", format: "uuid" },
        },
      },
      body: {
        type: "object",
        properties: {
          title: { type: "string", minLength: 1, maxLength: 200 },
          description: { type: "string" },
          basePrice: { type: "number", minimum: 0 },
          currency: { type: "string" },
          pricingModel: {
            type: "string",
            enum: ["FLAT", "HOURLY", "PER_EVENT", "TIERED"],
          },
          images: { type: "array", items: { type: "string", format: "uri" } },
          tags: { type: "array", items: { type: "string" } },
          maxCapacity: { type: "integer", minimum: 1 },
          minDurationHours: { type: "number", minimum: 0.5 },
          maxDurationHours: { type: "number", minimum: 0.5 },
          isAvailable: { type: "boolean" },
          attributes: { type: "object" },
          cancellationPolicy: { type: "object" },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;
      const validated = updateServiceSchema.parse(request.body);

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const existingService = await prisma.service.findFirst({
        where: {
          id,
          providerId: provider.id,
        },
      });

      if (!existingService) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      // Build update data - only include fields that were provided
      const updateData = {};
      if (validated.title !== undefined) updateData.title = validated.title;
      if (validated.description !== undefined)
        updateData.description = validated.description;
      if (validated.basePrice !== undefined)
        updateData.basePrice = validated.basePrice;
      if (validated.currency !== undefined)
        updateData.currency = validated.currency;
      if (validated.pricingModel !== undefined)
        updateData.pricingModel = validated.pricingModel;
      if (validated.images !== undefined) updateData.images = validated.images;
      if (validated.tags !== undefined) updateData.tags = validated.tags;
      if (validated.maxCapacity !== undefined)
        updateData.maxCapacity = validated.maxCapacity;
      if (validated.minDurationHours !== undefined)
        updateData.minDurationHours = validated.minDurationHours;
      if (validated.maxDurationHours !== undefined)
        updateData.maxDurationHours = validated.maxDurationHours;
      if (validated.isAvailable !== undefined)
        updateData.isAvailable = validated.isAvailable;
      if (validated.attributes !== undefined)
        updateData.attributes = validated.attributes;
      if (validated.cancellationPolicy !== undefined)
        updateData.cancellationPolicy = validated.cancellationPolicy;

      const service = await prisma.service.update({
        where: { id },
        data: updateData,
        include: {
          availabilityTemplates: true,
          pricingRules: {
            where: { isActive: true },
          },
        },
      });

      return {
        success: true,
        data: service,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // DELETE /services/:id (Delete service)
  // ═══════════════════════════════════════════════════════════
  fastify.delete("/services/:id", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Delete a service",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      params: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string", format: "uuid" },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id,
          providerId: provider.id,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      // Check for active bookings
      const activeBookings = await prisma.bookingItem.count({
        where: {
          serviceId: id,
          status: { in: ["PENDING", "CONFIRMED"] },
        },
      });

      if (activeBookings > 0) {
        // Soft delete - mark as unavailable instead
        await prisma.service.update({
          where: { id },
          data: { isAvailable: false },
        });

        return {
          success: true,
          message: "Service has active bookings. Marked as unavailable.",
        };
      }

      await prisma.service.delete({
        where: { id },
      });

      return {
        success: true,
        message: "Service deleted successfully",
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /availability/:serviceId (Get availability templates)
  // ═══════════════════════════════════════════════════════════
  fastify.get("/availability/:serviceId", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Get availability templates for a service",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { serviceId } = request.params;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id: serviceId,
          providerId: provider.id,
        },
        include: {
          availabilityTemplates: {
            orderBy: { dayOfWeek: "asc" },
          },
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      return {
        success: true,
        data: service.availabilityTemplates,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /availability/:serviceId (Update availability)
  // ═══════════════════════════════════════════════════════════
  fastify.post("/availability/:serviceId", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Update availability templates",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { serviceId } = request.params;
      const validated = updateAvailabilitySchema.parse(request.body);

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id: serviceId,
          providerId: provider.id,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      // Delete existing templates
      await prisma.availabilityTemplate.deleteMany({
        where: { serviceId },
      });

      // Create new templates
      const templates = await prisma.$transaction(
        validated.templates.map((t) =>
          prisma.availabilityTemplate.create({
            data: {
              serviceId,
              dayOfWeek: t.dayOfWeek,
              startTime: new Date(`1970-01-01T${t.startTime}`),
              endTime: new Date(`1970-01-01T${t.endTime}`),
              isAvailable: t.isAvailable,
            },
          }),
        ),
      );

      return {
        success: true,
        data: templates,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /pricing-rules/:serviceId (Get pricing rules)
  // ═══════════════════════════════════════════════════════════
  fastify.get("/pricing-rules/:serviceId", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Get pricing rules for a service",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { serviceId } = request.params;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      const service = await prisma.service.findFirst({
        where: {
          id: serviceId,
          providerId: provider.id,
        },
        include: {
          pricingRules: {
            where: { isActive: true },
            orderBy: { priority: "desc" },
          },
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      return {
        success: true,
        data: service.pricingRules,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /pricing-rules (Create pricing rule)
  // ═══════════════════════════════════════════════════════════
  fastify.post("/pricing-rules", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Create pricing rule",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = createPricingRuleSchema.parse(request.body);

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id: validated.serviceId,
          providerId: provider.id,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      const rule = await prisma.pricingRule.create({
        data: {
          serviceId: validated.serviceId,
          ruleType: validated.ruleType,
          multiplier: validated.multiplier,
          fixedAdjustment: validated.fixedAdjustment,
          startDate: validated.startDate,
          endDate: validated.endDate,
          dayOfWeek: validated.dayOfWeek,
          minAdvanceDays: validated.minAdvanceDays,
          minBookings: validated.minBookings,
          priority: validated.priority,
        },
      });

      reply.code(201);
      return {
        success: true,
        data: rule,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // DELETE /pricing-rules/:id (Delete pricing rule)
  // ═══════════════════════════════════════════════════════════
  fastify.delete("/pricing-rules/:id", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Delete pricing rule",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify rule belongs to provider's service
      const rule = await prisma.pricingRule.findFirst({
        where: {
          id,
          service: {
            providerId: provider.id,
          },
        },
      });

      if (!rule) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Pricing rule not found",
        });
      }

      await prisma.pricingRule.delete({
        where: { id },
      });

      return {
        success: true,
        message: "Pricing rule deleted successfully",
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /upload-images (Upload service images)
  // ═══════════════════════════════════════════════════════════
  fastify.post("/upload-images", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Upload service images",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      consumes: ["multipart/form-data"],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      const parts = request.parts();
      const uploadedUrls = [];
      const uploadDir = process.env.UPLOAD_DIR || "./uploads";

      for await (const part of parts) {
        if (part.type === "file") {
          // Generate unique filename
          const timestamp = Date.now();
          const random = Math.round(Math.random() * 1e9);
          const ext = part.filename.split(".").pop() || "jpg";
          const filename = `${timestamp}-${random}.${ext}`;
          const filepath = path.join(uploadDir, filename);

          // Save file
          await part.file.pipe(fs.createWriteStream(filepath));

          // Generate URL (assuming server serves /uploads statically)
          const baseUrl =
            process.env.BASE_URL || `${request.protocol}://${request.hostname}`;
          const fileUrl = `${baseUrl}/uploads/${filename}`;
          uploadedUrls.push(fileUrl);
        }
      }

      return {
        success: true,
        data: {
          urls: uploadedUrls,
          count: uploadedUrls.length,
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /services/:id/images (Add images to existing service)
  // ═══════════════════════════════════════════════════════════
  fastify.post("/services/:id/images", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Add images to an existing service",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      consumes: ["multipart/form-data"],
      params: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string", format: "uuid" },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id,
          providerId: provider.id,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      // Get existing images
      const existingImages = service.images || [];

      // Process uploaded files
      const parts = request.parts();
      const newUrls = [];
      const uploadDir = process.env.UPLOAD_DIR || "./uploads";

      for await (const part of parts) {
        if (part.type === "file") {
          const timestamp = Date.now();
          const random = Math.round(Math.random() * 1e9);
          const ext = part.filename.split(".").pop() || "jpg";
          const filename = `${timestamp}-${random}.${ext}`;
          const filepath = path.join(uploadDir, filename);

          await part.file.pipe(fs.createWriteStream(filepath));

          const baseUrl =
            process.env.BASE_URL || `${request.protocol}://${request.hostname}`;
          const fileUrl = `${baseUrl}/uploads/${filename}`;
          newUrls.push(fileUrl);
        }
      }

      // Combine and update
      const updatedImages = [...existingImages, ...newUrls];

      await prisma.service.update({
        where: { id },
        data: { images: updatedImages },
      });

      return {
        success: true,
        data: {
          serviceId: id,
          images: updatedImages,
          added: newUrls.length,
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // DELETE /services/:id/images (Remove image from service)
  // ═══════════════════════════════════════════════════════════
  fastify.delete("/services/:id/images", {
    onRequest: [fastify.authenticate],
    schema: {
      description: "Remove images from a service",
      tags: ["Provider"],
      security: [{ bearerAuth: [] }],
      params: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string", format: "uuid" },
        },
      },
      body: {
        type: "object",
        required: ["imageUrls"],
        properties: {
          imageUrls: { type: "array", items: { type: "string" } },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;
      const { imageUrls } = request.body;

      const provider = await prisma.provider.findUnique({
        where: { userId },
      });

      if (!provider) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Provider profile not found",
        });
      }

      // Verify service belongs to provider
      const service = await prisma.service.findFirst({
        where: {
          id,
          providerId: provider.id,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: "Not Found",
          message: "Service not found",
        });
      }

      // Remove specified images
      const existingImages = service.images || [];
      const updatedImages = existingImages.filter(
        (url) => !imageUrls.includes(url),
      );

      await prisma.service.update({
        where: { id },
        data: { images: updatedImages },
      });

      return {
        success: true,
        data: {
          serviceId: id,
          images: updatedImages,
          removed: existingImages.length - updatedImages.length,
        },
      };
    },
  });
}

module.exports = routes;
