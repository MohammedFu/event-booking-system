const zod = require('zod');
const prisma = require('../lib/prisma');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const {
  createNotification,
  createNotifications,
} = require('../lib/notifications');

// Validation schemas
const createIntentSchema = zod.object({
  amount: zod.number().positive().optional(),
  currency: zod.string().default('YER'),
  bookingId: zod.string().uuid(),
});

const confirmPaymentSchema = zod.object({
  paymentIntentId: zod.string(),
  paymentMethod: zod.string(),
});

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // POST /create-intent (Create Stripe PaymentIntent)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/create-intent', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Create Stripe PaymentIntent',
      tags: ['Payments'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['amount', 'bookingId'],
        properties: {
          amount: { type: 'number', description: 'Amount in cents' },
          currency: { type: 'string', default: 'YER' },
          bookingId: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = createIntentSchema.parse(request.body);

      // Verify booking exists and belongs to user
      const booking = await prisma.booking.findFirst({
        where: {
          id: validated.bookingId,
          consumerId: userId,
        },
        select: {
          id: true,
          status: true,
          currency: true,
          depositAmount: true,
          depositPaid: true,
        },
      });

      if (!booking) {
        return reply.code(404).send({
          success: false,
          error: 'Not Found',
          message: 'Booking not found',
        });
      }

      if (booking.status === 'CANCELLED') {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Cannot pay for cancelled booking',
        });
      }

      if (booking.depositPaid) {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'Deposit has already been paid',
        });
      }

      const expectedAmount = Math.round(
        (parseFloat(booking.depositAmount || 0) || 0) * 100,
      );

      if (expectedAmount <= 0) {
        return reply.code(400).send({
          success: false,
          error: 'Bad Request',
          message: 'This booking does not have a payable deposit',
        });
      }

      const requestedAmount = validated.amount ? Math.round(validated.amount) : expectedAmount;
      const currency = (validated.currency || booking.currency || 'YER').toUpperCase();

      if (requestedAmount !== expectedAmount) {
        fastify.log.warn(
          {
            bookingId: booking.id,
            userId,
            requestedAmount,
            expectedAmount,
          },
          'Ignoring mismatched payment amount and using server-calculated deposit',
        );
      }

      try {
        // Create PaymentIntent with Stripe
        const paymentIntent = await stripe.paymentIntents.create({
          amount: expectedAmount,
          currency: currency.toLowerCase(),
          automatic_payment_methods: { enabled: true },
          metadata: {
            bookingId: validated.bookingId,
            userId: userId,
          },
        });

        // Create payment record
        await prisma.payment.create({
          data: {
            bookingId: validated.bookingId,
            amount: expectedAmount / 100,
            currency,
            paymentMethod: 'CARD',
            stripePaymentIntentId: paymentIntent.id,
            status: 'PENDING',
            metadata: {
              clientSecret: paymentIntent.client_secret,
            },
          },
        });

        return {
          success: true,
          data: {
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
            amount: expectedAmount,
            currency,
          },
        };
      } catch (error) {
        fastify.log.error('Stripe error:', error);
        return reply.code(500).send({
          success: false,
          error: 'Payment Error',
          message: error.message,
        });
      }
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /confirm (Confirm payment)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/confirm', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Confirm payment after Stripe processing',
      tags: ['Payments'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['paymentIntentId', 'paymentMethod'],
        properties: {
          paymentIntentId: { type: 'string' },
          paymentMethod: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;
      const validated = confirmPaymentSchema.parse(request.body);

      try {
        const paymentRecord = await prisma.payment.findFirst({
          where: {
            stripePaymentIntentId: validated.paymentIntentId,
            booking: {
              consumerId: userId,
            },
          },
          include: {
            booking: {
              select: {
                id: true,
                depositPaid: true,
                items: {
                  select: {
                    providerId: true,
                    serviceId: true,
                  },
                },
              },
            },
          },
        });

        if (!paymentRecord) {
          return reply.code(404).send({
            success: false,
            error: 'Not Found',
            message: 'Payment record not found',
          });
        }

        if (paymentRecord.status === 'SUCCEEDED' && paymentRecord.booking.depositPaid) {
          return {
            success: true,
            data: paymentRecord,
            message: 'Payment already confirmed',
          };
        }

        // Retrieve PaymentIntent from Stripe
        const paymentIntent = await stripe.paymentIntents.retrieve(validated.paymentIntentId);

        if (
          paymentIntent.metadata?.userId !== userId ||
          paymentIntent.metadata?.bookingId !== paymentRecord.bookingId
        ) {
          return reply.code(403).send({
            success: false,
            error: 'Forbidden',
            message: 'You are not allowed to confirm this payment',
          });
        }

        if (paymentIntent.status !== 'succeeded') {
          return reply.code(400).send({
            success: false,
            error: 'Payment Failed',
            message: `Payment status: ${paymentIntent.status}`,
          });
        }

        // Update payment record
        const updatedPayment = await prisma.payment.update({
          where: {
            id: paymentRecord.id,
          },
          data: {
            status: 'SUCCEEDED',
            paymentMethod: validated.paymentMethod.toUpperCase(),
          },
        });

        // Get booking ID from metadata
        const bookingId = paymentRecord.bookingId;

        // Update booking deposit status
        await prisma.booking.update({
          where: { id: bookingId },
          data: { depositPaid: true },
        });

        if (!paymentRecord.booking.depositPaid) {
          const providerIds = [...new Set(paymentRecord.booking.items.map((item) => item.providerId))];
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
              type: 'SYSTEM',
              title: 'Deposit received',
              body: 'Your deposit payment was received successfully.',
              data: {
                bookingId,
                paymentIntentId: validated.paymentIntentId,
                audience: 'consumer',
              },
            }),
            createNotifications(
              paymentRecord.booking.items.map((item) => ({
                userId: providerUserIds.get(item.providerId),
                type: 'PAYMENT_RECEIVED',
                title: 'Payment received',
                body: 'A customer deposit was received for an upcoming booking.',
                data: {
                  bookingId,
                  serviceId: item.serviceId,
                  paymentIntentId: validated.paymentIntentId,
                  serviceTitle: item.service?.title,
                  audience: 'provider',
                },
              })),
            ),
          ]);
        }

        return {
          success: true,
          data: updatedPayment,
          message: 'Payment confirmed successfully',
        };
      } catch (error) {
        fastify.log.error('Payment confirmation error:', error);
        return reply.code(500).send({
          success: false,
          error: 'Payment Error',
          message: error.message,
        });
      }
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /history (Get payment history)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/history', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get user payment history',
      tags: ['Payments'],
      security: [{ bearerAuth: [] }],
    },
    handler: async (request, reply) => {
      const userId = request.user.userId;

      const payments = await prisma.payment.findMany({
        where: {
          booking: {
            consumerId: userId,
          },
        },
        include: {
          booking: {
            select: {
              id: true,
              eventName: true,
              eventDate: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return {
        success: true,
        data: payments,
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /webhook (Stripe webhook handler)
  // ═══════════════════════════════════════════════════════════
  fastify.post('/webhook', {
    // No auth required - Stripe sends webhook
    handler: async (request, reply) => {
      const sig = request.headers['stripe-signature'];
      const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

      let event;

      try {
        event = stripe.webhooks.constructEvent(request.body, sig, endpointSecret);
      } catch (err) {
        fastify.log.error(`Webhook signature verification failed: ${err.message}`);
        return reply.code(400).send(`Webhook Error: ${err.message}`);
      }

      // Handle events
      switch (event.type) {
        case 'payment_intent.succeeded':
          const paymentIntent = event.data.object;
          fastify.log.info(`PaymentIntent succeeded: ${paymentIntent.id}`);
          
          // Update payment status
          await prisma.payment.updateMany({
            where: { stripePaymentIntentId: paymentIntent.id },
            data: { status: 'SUCCEEDED' },
          });
          break;

        case 'payment_intent.payment_failed':
          const failedPayment = event.data.object;
          fastify.log.error(`Payment failed: ${failedPayment.id}`);
          
          await prisma.payment.updateMany({
            where: { stripePaymentIntentId: failedPayment.id },
            data: { status: 'FAILED' },
          });
          break;

        case 'charge.refunded':
          const refund = event.data.object;
          fastify.log.info(`Refund processed: ${refund.payment_intent}`);
          
          await prisma.payment.updateMany({
            where: { stripePaymentIntentId: refund.payment_intent },
            data: { status: refund.refunded ? 'REFUNDED' : 'PARTIALLY_REFUNDED' },
          });
          break;

        default:
          fastify.log.info(`Unhandled event type: ${event.type}`);
      }

      return { received: true };
    },
  });
}

module.exports = routes;
