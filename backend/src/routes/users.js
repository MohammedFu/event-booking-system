const zod = require('zod');
const prisma = require('../lib/prisma');
const { normalizeServiceMedia } = require('../lib/public-url');

// Validation schemas
const updateProfileSchema = zod.object({
  fullName: zod.string().min(2).optional(),
  phone: zod.string().optional(),
  avatarUrl: zod.string().url().optional(),
});

const updatePreferencesSchema = zod.object({
  preferredHallThemes: zod.array(zod.string()).optional(),
  preferredCarTypes: zod.array(zod.string()).optional(),
  preferredPhotographerStyles: zod.array(zod.string()).optional(),
  preferredEntertainerTypes: zod.array(zod.string()).optional(),
  budgetRange: zod
    .object({
      min: zod.number(),
      max: zod.number().nullable(),
    })
    .optional(),
  preferredCities: zod.array(zod.string()).optional(),
});

const registerDeviceTokenSchema = zod.object({
  token: zod.string().min(10),
  platform: zod.enum(["ANDROID", "IOS", "WEB"]),
});

const unregisterDeviceTokenSchema = zod.object({
  token: zod.string().min(10),
});

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // GET /profile (Get user profile)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/profile', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get current user profile',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          fullName: true,
          phone: true,
          avatarUrl: true,
          role: true,
          isVerified: true,
          createdAt: true,
          provider: true,
          userPreferences: true,
        },
      });

      if (!user) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'User not found',
        });
      }

      return {
        success: true,
        data: user,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PATCH /profile (Update user profile)
  // ═══════════════════════════════════════════════════════════
  fastify.patch('/profile', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Update user profile',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = updateProfileSchema.parse(request.body);

      const updated = await prisma.user.update({
        where: { id: userId },
        data: validated,
        select: {
          id: true,
          email: true,
          fullName: true,
          phone: true,
          avatarUrl: true,
          role: true,
        },
      });

      return {
        success: true,
        data: updated,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /preferences (Get user preferences)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/preferences', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get user preferences',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const preferences = await prisma.userPreferences.findUnique({
        where: { userId },
      });

      if (!preferences) {
        return {
          success: true,
          data: null,
        };
      }

      return {
        success: true,
        data: preferences,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PUT /preferences (Update user preferences)
  // ═══════════════════════════════════════════════════════════
  fastify.put('/preferences', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Update user preferences',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = updatePreferencesSchema.parse(request.body);

      const preferences = await prisma.userPreferences.upsert({
        where: { userId },
        create: {
          userId,
          ...validated,
        },
        update: validated,
      });

      return {
        success: true,
        data: preferences,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /bookmarks (Get user bookmarks)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/bookmarks', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get user bookmarked services',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const bookmarks = await prisma.bookmark.findMany({
        where: { userId },
        include: {
          service: {
            include: {
              provider: {
                select: {
                  id: true,
                  businessName: true,
                  rating: true,
                  city: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const services = bookmarks.map((b) =>
        normalizeServiceMedia(b.service, request)
      );

      return {
        success: true,
        data: services,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /bookmarks (Add bookmark)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/bookmarks', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Add service to bookmarks',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['serviceId'],
        properties: {
          serviceId: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { serviceId } = request.body;

      // Verify service exists
      const service = await prisma.service.findUnique({
        where: { id: serviceId },
      });

      if (!service) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Service not found',
        });
      }

      try {
        const bookmark = await prisma.bookmark.create({
          data: {
            userId,
            serviceId,
          },
        });

        reply.code(201);
        return {
          success: true,
          data: bookmark,
        };
      } catch (error) {
        // Unique constraint violation - already bookmarked
        if (error.code === 'P2002') {
          return reply.code(409).send({
            success: false,
            error: 'Conflict',
            message: 'Service is already bookmarked',
          });
        }
        throw error;
      }
    },
  });

  // ═══════════════════════════════════════════════════════════
  // DELETE /bookmarks/:serviceId (Remove bookmark)
  // ═══════════════════════════════════════════════════════════
  fastify.delete('/bookmarks/:serviceId', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Remove service from bookmarks',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { serviceId } = request.params;

      await prisma.bookmark.deleteMany({
        where: {
          userId,
          serviceId,
        },
      });

      return {
        success: true,
        message: 'Bookmark removed successfully',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /notifications (Get user notifications)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/notifications', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get user notifications',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
      querystring: {
        type: 'object',
        properties: {
          unreadOnly: { type: 'boolean' },
          page: { type: 'number' },
          limit: { type: 'number' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { unreadOnly, page = 1, limit = 20 } = request.query;

      const where = { userId };
      if (unreadOnly === 'true') {
        where.isRead = false;
      }

      const skip = (page - 1) * limit;

      const [notifications, total, unreadCount] = await Promise.all([
        prisma.notification.findMany({
          where,
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
        }),
        prisma.notification.count({ where }),
        prisma.notification.count({
          where: { userId, isRead: false },
        }),
      ]);

      return {
        success: true,
        data: notifications,
        meta: {
          page,
          limit,
          total,
          unreadCount,
          totalPages: Math.ceil(total / limit),
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // PATCH /notifications/:id/read (Mark notification as read)
  // ═══════════════════════════════════════════════════════════
  fastify.patch('/notifications/:id/read', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Mark notification as read',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { id } = request.params;

      const notification = await prisma.notification.findFirst({
        where: { id, userId },
      });

      if (!notification) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Notification not found',
        });
      }

      const updated = await prisma.notification.update({
        where: { id },
        data: { isRead: true },
      });

      return {
        success: true,
        data: updated,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /notifications/read-all (Mark all notifications as read)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/notifications/read-all', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Mark all notifications as read',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      await prisma.notification.updateMany({
        where: { userId, isRead: false },
        data: { isRead: true },
      });

      return {
        success: true,
        message: 'All notifications marked as read',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // POST /device-tokens (Register or refresh a mobile device token)
  // ═══════════════════════════════════════════════════════════════════════════
  fastify.post('/device-tokens', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Register a device token for push notifications',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['token', 'platform'],
        properties: {
          token: { type: 'string' },
          platform: {
            type: 'string',
            enum: ['ANDROID', 'IOS', 'WEB'],
          },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = registerDeviceTokenSchema.parse(request.body);

      const deviceToken = await prisma.deviceToken.upsert({
        where: { token: validated.token },
        create: {
          userId,
          token: validated.token,
          platform: validated.platform,
          isActive: true,
        },
        update: {
          userId,
          platform: validated.platform,
          isActive: true,
          lastUsedAt: new Date(),
        },
      });

      return {
        success: true,
        data: deviceToken,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE /device-tokens (Unregister current device token)
  // ═══════════════════════════════════════════════════════════════════════════
  fastify.delete('/device-tokens', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Unregister a device token',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['token'],
        properties: {
          token: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = unregisterDeviceTokenSchema.parse(request.body);

      await prisma.deviceToken.updateMany({
        where: {
          userId,
          token: validated.token,
        },
        data: {
          isActive: false,
          lastUsedAt: new Date(),
        },
      });

      return {
        success: true,
        message: 'Device token removed successfully',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /reviews (Get user's reviews)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/reviews', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get reviews written by user',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const reviews = await prisma.review.findMany({
        where: { consumerId: userId },
        include: {
          bookingItem: {
            include: {
              service: {
                select: {
                  id: true,
                  title: true,
                  images: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return {
        success: true,
        data: reviews,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /reviews (Submit a review)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/reviews', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Submit a review for a completed booking',
      tags: ['Users'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['bookingItemId', 'rating'],
        properties: {
          bookingItemId: { type: 'string' },
          rating: { type: 'number', minimum: 1, maximum: 5 },
          comment: { type: 'string' },
          images: { type: 'array', items: { type: 'string' } },
          isAnonymous: { type: 'boolean' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const { bookingItemId, rating, comment, images, isAnonymous } = request.body;

      // Verify booking item exists and belongs to user
      const bookingItem = await prisma.bookingItem.findFirst({
        where: {
          id: bookingItemId,
          booking: { consumerId: userId },
          status: 'COMPLETED',
        },
        include: { provider: true },
      });

      if (!bookingItem) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking item not found or not eligible for review',
        });
      }

      // Check if already reviewed
      const existingReview = await prisma.review.findUnique({
        where: { bookingItemId },
      });

      if (existingReview) {
        return reply.code(409).send({
          success: false,
          error: 'Conflict',
          message: 'This booking has already been reviewed',
        });
      }

      const review = await prisma.$transaction(async (tx) => {
        // Create review
        const review = await tx.review.create({
          data: {
            bookingItemId,
            consumerId: userId,
            providerId: bookingItem.providerId,
            rating,
            comment,
            images: images || [],
            isAnonymous: isAnonymous || false,
          },
        });

        // Update provider rating
        const allReviews = await tx.review.findMany({
          where: { providerId: bookingItem.providerId },
        });

        const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

        await tx.provider.update({
          where: { id: bookingItem.providerId },
          data: {
            rating: avgRating,
            reviewCount: allReviews.length,
          },
        });

        return review;
      });

      reply.code(201);
      return {
        success: true,
        data: review,
      };
    },
  });
}

module.exports = routes;
