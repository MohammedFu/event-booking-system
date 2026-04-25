const zod = require('zod');
const prisma = require('../lib/prisma');
const { normalizeServiceMedia } = require('../lib/public-url');

// Validation schemas
const getServicesSchema = zod.object({
  type: zod.enum(['HALL', 'CAR', 'PHOTOGRAPHER', 'ENTERTAINER']).optional(),
  search: zod.string().optional(),
  minPrice: zod.coerce.number().optional(),
  maxPrice: zod.coerce.number().optional(),
  minRating: zod.coerce.number().min(0).max(5).optional(),
  city: zod.string().optional(),
  sortBy: zod.enum(['rating', 'price_low', 'price_high', 'reviews', 'newest']).default('rating'),
  page: zod.coerce.number().int().positive().default(1),
  limit: zod.coerce.number().int().positive().max(100).default(20),
});

const getAvailabilitySchema = zod.object({
  date: zod.coerce.date(),
});

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // GET / (List services with filters)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/', {
    schema: {
      description: 'List services with filters and pagination',
      tags: ['Services'],
      querystring: {
        type: 'object',
        properties: {
          type: { type: 'string', enum: ['HALL', 'CAR', 'PHOTOGRAPHER', 'ENTERTAINER'] },
          search: { type: 'string' },
          minPrice: { type: 'number' },
          maxPrice: { type: 'number' },
          minRating: { type: 'number' },
          city: { type: 'string' },
          sortBy: { type: 'string', enum: ['rating', 'price_low', 'price_high', 'reviews', 'newest'] },
          page: { type: 'number' },
          limit: { type: 'number' },
        },
      },
    },
    handler: async (request, reply) => {
      const params = getServicesSchema.parse(request.query);

      // Build where clause
      const where = {
        isAvailable: true,
        provider: {
          isActive: true,
        },
      };

      if (params.type) {
        where.serviceType = params.type;
      }

      if (params.search) {
        where.OR = [
          { title: { contains: params.search, mode: 'insensitive' } },
          { description: { contains: params.search, mode: 'insensitive' } },
          { tags: { array_contains: params.search } },
        ];
      }

      if (params.minPrice !== undefined || params.maxPrice !== undefined) {
        where.basePrice = {};
        if (params.minPrice !== undefined) where.basePrice.gte = params.minPrice;
        if (params.maxPrice !== undefined) where.basePrice.lte = params.maxPrice;
      }

      if (params.minRating !== undefined) {
        where.provider = {
          ...where.provider,
          rating: { gte: params.minRating },
        };
      }

      if (params.city) {
        where.provider = {
          ...where.provider,
          city: { contains: params.city, mode: 'insensitive' },
        };
      }

      // Build order by
      let orderBy = {};
      switch (params.sortBy) {
        case 'price_low':
          orderBy = { basePrice: 'asc' };
          break;
        case 'price_high':
          orderBy = { basePrice: 'desc' };
          break;
        case 'rating':
          orderBy = { provider: { rating: 'desc' } };
          break;
        case 'reviews':
          orderBy = { provider: { reviewCount: 'desc' } };
          break;
        case 'newest':
          orderBy = { createdAt: 'desc' };
          break;
        default:
          orderBy = { provider: { rating: 'desc' } };
      }

      // Execute query
      const skip = (params.page - 1) * params.limit;
      
      const [services, total] = await Promise.all([
        prisma.service.findMany({
          where,
          include: {
            provider: {
              select: {
                id: true,
                businessName: true,
                rating: true,
                reviewCount: true,
                city: true,
                logoUrl: true,
              },
            },
            pricingRules: {
              where: { isActive: true },
            },
          },
          orderBy,
          skip,
          take: params.limit,
        }),
        prisma.service.count({ where }),
      ]);

      return {
        success: true,
        data: services.map((service) => normalizeServiceMedia(service, request)),
        meta: {
          page: params.page,
          limit: params.limit,
          total,
          totalPages: Math.ceil(total / params.limit),
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /search (Full-text search)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/search', {
    schema: {
      description: 'Search services',
      tags: ['Services'],
      querystring: {
        type: 'object',
        required: ['q'],
        properties: {
          q: { type: 'string' },
          page: { type: 'number' },
          limit: { type: 'number' },
        },
      },
    },
    handler: async (request, reply) => {
      const { q, page = 1, limit = 20 } = request.query;

      if (!q || q.trim().length === 0) {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Search query is required',
        });
      }

      const where = {
        isAvailable: true,
        provider: { isActive: true },
        OR: [
          { title: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
          { tags: { has: q } },
        ],
      };

      const skip = (page - 1) * limit;

      const [services, total] = await Promise.all([
        prisma.service.findMany({
          where,
          include: {
            provider: {
              select: {
                id: true,
                businessName: true,
                rating: true,
                reviewCount: true,
                city: true,
                logoUrl: true,
              },
            },
          },
          orderBy: { provider: { rating: 'desc' } },
          skip,
          take: limit,
        }),
        prisma.service.count({ where }),
      ]);

      return {
        success: true,
        data: services.map((service) => normalizeServiceMedia(service, request)),
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
  // GET /:id (Get service details)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/:id', {
    schema: {
      description: 'Get service by ID',
      tags: ['Services'],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string', format: 'uuid' },
        },
      },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const service = await prisma.service.findUnique({
        where: { id },
        include: {
          provider: {
            select: {
              id: true,
              businessName: true,
              description: true,
              rating: true,
              reviewCount: true,
              city: true,
              address: true,
              logoUrl: true,
              coverUrl: true,
              contactPhone: true,
              contactEmail: true,
              isVerified: true,
            },
          },
          availabilityTemplates: {
            orderBy: { dayOfWeek: 'asc' },
          },
          pricingRules: {
            where: { isActive: true },
          },
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Service not found',
        });
      }

      return {
        success: true,
        data: normalizeServiceMedia(service, request),
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /:id/availability (Get available time slots)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/:id/availability', {
    schema: {
      description: 'Get available time slots for a service on a specific date',
      tags: ['Services'],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string', format: 'uuid' },
        },
      },
      querystring: {
        type: 'object',
        required: ['date'],
        properties: {
          date: { type: 'string', format: 'date' },
        },
      },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const { date } = request.query;

      const service = await prisma.service.findUnique({
        where: { id },
        include: {
          availabilityTemplates: true,
        },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Service not found',
        });
      }

      const queryDate = new Date(date);
      const dayOfWeek = queryDate.getDay(); // 0 = Sunday, 6 = Saturday

      // Get availability template for this day
      const template = service.availabilityTemplates.find(
        (t) => t.dayOfWeek === dayOfWeek && t.isAvailable
      );

      if (!template) {
        return {
          success: true,
          data: [],
          message: 'No availability for this date',
        };
      }

      // Get booked slots for this date
      const bookedSlots = await prisma.bookedSlot.findMany({
        where: {
          serviceId: id,
          date: queryDate,
          status: 'CONFIRMED',
        },
      });

      // Generate time slots
      const slots = [];
      const startHour = template.startTime.getHours();
      const endHour = template.endTime.getHours();

      for (let hour = startHour; hour < endHour; hour++) {
        const slotStart = `${hour.toString().padStart(2, '0')}:00`;
        const slotEnd = `${(hour + 1).toString().padStart(2, '0')}:00`;

        // Check if this slot is booked
        const isBooked = bookedSlots.some((slot) => {
          const slotStartHour = slot.startTime.getHours();
          const slotEndHour = slot.endTime.getHours();
          return hour >= slotStartHour && hour < slotEndHour;
        });

        slots.push({
          id: `slot-${id}-${date}-${hour}`,
          serviceId: id,
          date: date,
          startTime: slotStart,
          endTime: slotEnd,
          isAvailable: !isBooked,
        });
      }

      return {
        success: true,
        data: slots,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /:id/reviews (Get service reviews)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/:id/reviews', {
    schema: {
      description: 'Get reviews for a service',
      tags: ['Services'],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string', format: 'uuid' },
        },
      },
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'number' },
          limit: { type: 'number' },
        },
      },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const page = parseInt(request.query.page) || 1;
      const limit = parseInt(request.query.limit) || 20;
      const skip = (page - 1) * limit;

      const [reviews, total] = await Promise.all([
        prisma.review.findMany({
          where: {
            bookingItem: {
              serviceId: id,
            },
          },
          include: {
            consumer: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
        }),
        prisma.review.count({
          where: {
            bookingItem: {
              serviceId: id,
            },
          },
        }),
      ]);

      return {
        success: true,
        data: reviews,
        meta: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    },
  });
}

module.exports = routes;
