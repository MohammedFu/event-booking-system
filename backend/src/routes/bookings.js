const zod = require('zod');
const prisma = require('../lib/prisma');
const redis = require('../lib/redis');
const {
  createNotification,
  createNotifications,
} = require('../lib/notifications');

// Validation schemas
const createBookingSchema = zod.object({
  eventType: zod.enum(['WEDDING', 'BIRTHDAY', 'CORPORATE', 'ENGAGEMENT', 'OTHER']),
  eventDate: zod.coerce.date(),
  eventName: zod.string().optional(),
  items: zod.array(zod.object({
    serviceId: zod.string().uuid(),
    date: zod.coerce.date(),
    startTime: zod.string(), // HH:mm format
    endTime: zod.string(),
    durationHours: zod.number().optional(),
    specialRequests: zod.string().optional(),
  })).min(1),
  specialRequests: zod.string().optional(),
});

const bookingIdSchema = zod.object({
  id: zod.string().uuid(),
});

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // GET / (List user's bookings)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get current user bookings',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
      querystring: {
        type: 'object',
        properties: {
          status: { type: 'string', enum: ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'] },
          page: { type: 'number' },
          limit: { type: 'number' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { status, page = 1, limit = 20 } = request.query;
      const skip = (page - 1) * limit;

      const where = { consumerId: userId };
      if (status) where.status = status;

      const [bookings, total] = await Promise.all([
        prisma.booking.findMany({
          where,
          include: {
            items: {
              include: {
                service: {
                  select: {
                    id: true,
                    providerId: true,
                    title: true,
                    images: true,
                    serviceType: true,
                    provider: {
                      select: {
                        id: true,
                        userId: true,
                        businessName: true,
                        logoUrl: true,
                        serviceType: true,
                        rating: true,
                        reviewCount: true,
                        city: true,
                        isVerified: true,
                      },
                    },
                  },
                },
              },
            },
            payments: {
              where: { status: { in: ['SUCCEEDED', 'REFUNDED', 'PARTIALLY_REFUNDED'] } },
            },
          },
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
        }),
        prisma.booking.count({ where }),
      ]);

      return {
        success: true,
        data: bookings,
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
  // POST / (Create booking)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Create a new booking',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['eventType', 'eventDate', 'items'],
        properties: {
          eventType: { type: 'string' },
          eventDate: { type: 'string', format: 'date' },
          eventName: { type: 'string' },
          items: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                serviceId: { type: 'string' },
                date: { type: 'string' },
                startTime: { type: 'string' },
                endTime: { type: 'string' },
                specialRequests: { type: 'string' },
              },
            },
          },
          specialRequests: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = createBookingSchema.parse(request.body);

      // Start transaction
      const result = await prisma.$transaction(async (tx) => {
        // Validate all services exist and are available
        const serviceIds = validated.items.map((item) => item.serviceId);
        const services = await tx.service.findMany({
          where: {
            id: { in: serviceIds },
            isAvailable: true,
            provider: { isActive: true },
          },
          include: { provider: true, pricingRules: true },
        });

        if (services.length !== serviceIds.length) {
          throw new Error('One or more services are not available');
        }

        // Check for conflicts (double booking)
        for (const item of validated.items) {
          const existingBooking = await tx.bookedSlot.findFirst({
            where: {
              serviceId: item.serviceId,
              date: item.date,
              status: 'CONFIRMED',
              OR: [
                {
                  startTime: { lte: new Date(`1970-01-01T${item.startTime}`) },
                  endTime: { gt: new Date(`1970-01-01T${item.startTime}`) },
                },
                {
                  startTime: { lt: new Date(`1970-01-01T${item.endTime}`) },
                  endTime: { gte: new Date(`1970-01-01T${item.endTime}`) },
                },
              ],
            },
          });

          if (existingBooking) {
            throw new Error(`Time slot conflict for service ${item.serviceId}`);
          }
        }

        // Calculate pricing
        let totalAmount = 0;
        const bookingItems = [];

        for (const item of validated.items) {
          const service = services.find((s) => s.id === item.serviceId);
          
          // Calculate duration
          const startHour = parseInt(item.startTime.split(':')[0]);
          const endHour = parseInt(item.endTime.split(':')[0]);
          const durationHours = item.durationHours || (endHour - startHour);

          // Base price calculation
          let unitPrice = parseFloat(service.basePrice);
          
          // Apply pricing rules
          const itemDate = new Date(item.date);
          const dayOfWeek = itemDate.getDay();
          let appliedPricing = {};

          for (const rule of service.pricingRules.filter((r) => r.isActive)) {
            let shouldApply = false;

            // Weekend rule
            if (rule.ruleType === 'WEEKEND' && (dayOfWeek === 0 || dayOfWeek === 6)) {
              shouldApply = true;
            }

            // Seasonal rule
            if (rule.ruleType === 'SEASONAL' && rule.startDate && rule.endDate) {
              if (itemDate >= rule.startDate && itemDate <= rule.endDate) {
                shouldApply = true;
              }
            }

            // Early bird
            if (rule.ruleType === 'EARLY_BIRD' && rule.minAdvanceDays) {
              const daysInAdvance = Math.ceil((itemDate - new Date()) / (1000 * 60 * 60 * 24));
              if (daysInAdvance >= rule.minAdvanceDays) {
                shouldApply = true;
              }
            }

            if (shouldApply) {
              unitPrice = unitPrice * parseFloat(rule.multiplier);
              if (rule.fixedAdjustment) {
                unitPrice += parseFloat(rule.fixedAdjustment);
              }
              appliedPricing[rule.ruleType] = {
                multiplier: parseFloat(rule.multiplier),
                fixedAdjustment: rule.fixedAdjustment ? parseFloat(rule.fixedAdjustment) : null,
              };
            }
          }

          const subtotal = unitPrice * durationHours;
          totalAmount += subtotal;

          bookingItems.push({
            serviceId: item.serviceId,
            providerId: service.providerId,
            date: item.date,
            startTime: new Date(`1970-01-01T${item.startTime}`),
            endTime: new Date(`1970-01-01T${item.endTime}`),
            durationHours,
            unitPrice,
            appliedPricing,
            subtotal,
            specialRequests: item.specialRequests,
          });
        }

        // Create booking
        const booking = await tx.booking.create({
          data: {
            consumerId: userId,
            eventType: validated.eventType,
            eventDate: validated.eventDate,
            eventName: validated.eventName,
            status: 'PENDING',
            totalAmount,
            depositAmount: totalAmount * 0.25,
            depositPaid: false,
            specialRequests: validated.specialRequests,
            items: {
              create: bookingItems,
            },
          },
          include: {
            items: {
              include: {
                service: {
                  select: {
                    id: true,
                    providerId: true,
                    title: true,
                    images: true,
                    serviceType: true,
                    provider: {
                      select: {
                        id: true,
                        userId: true,
                        businessName: true,
                        logoUrl: true,
                        serviceType: true,
                        rating: true,
                        reviewCount: true,
                        city: true,
                        isVerified: true,
                      },
                    },
                  },
                },
              },
            },
          },
        });

        const providerNotifications = validated.items.map((item) => {
          const service = services.find((candidate) => candidate.id === item.serviceId);
          return {
            userId: service?.provider?.userId,
            type: 'PROVIDER_MESSAGE',
            title: 'New booking request',
            body: `A new booking request was submitted for ${service?.title || 'your service'}.`,
            data: {
              bookingId: booking.id,
              serviceId: item.serviceId,
              serviceTitle: service?.title,
              audience: 'provider',
            },
          };
        });

        return { booking, providerNotifications };
      }, {
        maxWait: 5000,
        timeout: 10000,
      });

      await Promise.all([
        createNotification({
          userId,
          type: 'SYSTEM',
          title: 'Booking request sent',
          body: `Your booking request for ${result.booking.eventName || 'your event'} has been submitted.`,
          data: {
            bookingId: result.booking.id,
            eventName: result.booking.eventName,
            audience: 'consumer',
          },
        }),
        createNotifications(result.providerNotifications),
      ]);

      reply.code(201);
      return {
        success: true,
        data: result.booking,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /:id (Get booking details)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/:id', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get booking by ID',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = bookingIdSchema.parse(request.params);

      const booking = await prisma.booking.findFirst({
        where: {
          id,
          consumerId: userId,
        },
        include: {
          items: {
            include: {
              service: {
                select: {
                  id: true,
                  providerId: true,
                  title: true,
                  images: true,
                  serviceType: true,
                  provider: {
                    select: {
                      id: true,
                      userId: true,
                      businessName: true,
                      logoUrl: true,
                      serviceType: true,
                      rating: true,
                      reviewCount: true,
                      city: true,
                      isVerified: true,
                      contactPhone: true,
                      contactEmail: true,
                    },
                  },
                },
              },
            },
          },
          payments: true,
        },
      });

      if (!booking) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking not found',
        });
      }

      return {
        success: true,
        data: booking,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PATCH /:id (Update booking)
  // ═══════════════════════════════════════════════════════════
  fastify.patch('/:id', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Update booking',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = bookingIdSchema.parse(request.params);
      const { eventName, specialRequests } = request.body;

      const booking = await prisma.booking.findFirst({
        where: { id, consumerId: userId },
      });

      if (!booking) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking not found',
        });
      }

      // Only allow updates for pending/draft bookings
      if (!['PENDING', 'DRAFT'].includes(booking.status)) {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Cannot update confirmed or completed bookings',
        });
      }

      const updated = await prisma.booking.update({
        where: { id },
        data: {
          eventName: eventName || booking.eventName,
          specialRequests: specialRequests !== undefined ? specialRequests : booking.specialRequests,
        },
        include: {
          items: {
            include: {
              service: {
                select: { id: true, title: true, images: true },
              },
            },
          },
        },
      });

      return {
        success: true,
        data: updated,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /:id/cancel (Cancel booking)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/:id/cancel', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Cancel booking',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          reason: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = bookingIdSchema.parse(request.params);
      const { reason } = request.body;

      const booking = await prisma.booking.findFirst({
        where: { id, consumerId: userId },
        include: {
          items: {
            include: {
              service: {
                select: {
                  title: true,
                },
              },
            },
          },
        },
      });

      if (!booking) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking not found',
        });
      }

      if (['CANCELLED', 'REFUNDED'].includes(booking.status)) {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Booking is already cancelled',
        });
      }

      // Start transaction to cancel booking and release slots
      await prisma.$transaction(async (tx) => {
        // Update booking status
        await tx.booking.update({
          where: { id },
          data: {
            status: 'CANCELLED',
            notes: reason ? `Cancellation reason: ${reason}` : undefined,
          },
        });

        // Update booking items
        await tx.bookingItem.updateMany({
          where: { bookingId: id },
          data: { status: 'CANCELLED' },
        });

        // Cancel booked slots
        await tx.bookedSlot.updateMany({
          where: { bookingId: id },
          data: { status: 'CANCELLED' },
        });
      });

      const providerIds = [...new Set(booking.items.map((item) => item.providerId))];
      const providers = await prisma.provider.findMany({
        where: {
          id: { in: providerIds },
        },
        select: {
          id: true,
          userId: true,
        },
      });

      const providerUserIds = new Map(
        providers.map((provider) => [provider.id, provider.userId]),
      );

      await Promise.all([
        createNotification({
          userId,
          type: 'BOOKING_CANCELLED',
          title: 'Booking cancelled',
          body: `${booking.eventName || 'Your booking'} was cancelled successfully.`,
          data: {
            bookingId: id,
            eventName: booking.eventName,
            audience: 'consumer',
          },
        }),
        createNotifications(
          booking.items.map((item) => ({
            userId: providerUserIds.get(item.providerId),
            type: 'BOOKING_CANCELLED',
            title: 'Booking cancelled',
            body: `A customer cancelled ${item.service?.title || 'a booking'}.`,
            data: {
              bookingId: id,
              serviceId: item.serviceId,
              serviceTitle: item.service?.title,
              audience: 'provider',
            },
          })),
        ),
      ]);

      return {
        success: true,
        message: 'Booking cancelled successfully',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /:id/confirm (Confirm booking - provider action)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/:id/confirm', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Confirm pending booking',
      tags: ['Bookings'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = bookingIdSchema.parse(request.params);

      const booking = await prisma.booking.findFirst({
        where: { id },
        include: {
          items: {
            include: { service: true },
          },
        },
      });

      if (!booking) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking not found',
        });
      }

      // Check if user is the provider for any item
      const providerIds = booking.items.map((item) => item.providerId);
      const userProvider = await prisma.provider.findFirst({
        where: { userId, id: { in: providerIds } },
      });

      if (!userProvider && request.user.role !== 'ADMIN') {
        return reply.code(403).send({
          success: false,
          error: 'Forbidden',
          message: 'You do not have permission to confirm this booking',
        });
      }

      if (booking.status !== 'PENDING') {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Only pending bookings can be confirmed',
        });
      }

      // Start transaction
      const updated = await prisma.$transaction(async (tx) => {
        // Update booking status
        const updatedBooking = await tx.booking.update({
          where: { id },
          data: { status: 'CONFIRMED' },
        });

        // Update booking items
        await tx.bookingItem.updateMany({
          where: { bookingId: id },
          data: { status: 'CONFIRMED' },
        });

        // Create booked slots
        for (const item of booking.items) {
          await tx.bookedSlot.create({
            data: {
              serviceId: item.serviceId,
              bookingId: id,
              date: item.date,
              startTime: item.startTime,
              endTime: item.endTime,
              status: 'CONFIRMED',
            },
          });
        }

        return updatedBooking;
      });

      await createNotification({
        userId: booking.consumerId,
        type: 'BOOKING_CONFIRMED',
        title: 'Booking confirmed',
        body: `${booking.eventName || 'Your booking'} has been confirmed.`,
        data: {
          bookingId: id,
          eventName: booking.eventName,
          audience: 'consumer',
        },
      });

      return {
        success: true,
        data: updated,
        message: 'Booking confirmed successfully',
      };
    },
  });
}

module.exports = routes;
