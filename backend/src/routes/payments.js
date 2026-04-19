const zod = require('zod');
const prisma = require('../lib/prisma');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// Validation schemas
const createIntentSchema = zod.object({
  amount: zod.number().positive(),
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

      try {
        // Create PaymentIntent with Stripe
        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(validated.amount), // Amount in cents
          currency: validated.currency.toLowerCase(),
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
            amount: validated.amount / 100, // Store in dollars
            currency: validated.currency.toUpperCase(),
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
            amount: validated.amount,
            currency: validated.currency,
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
        // Retrieve PaymentIntent from Stripe
        const paymentIntent = await stripe.paymentIntents.retrieve(validated.paymentIntentId);

        if (paymentIntent.status !== 'succeeded') {
          return reply.code(400).send({
            success: false,
            error: 'Payment Failed',
            message: `Payment status: ${paymentIntent.status}`,
          });
        }

        // Update payment record
        const payment = await prisma.payment.updateMany({
          where: {
            stripePaymentIntentId: validated.paymentIntentId,
          },
          data: {
            status: 'SUCCEEDED',
            paymentMethod: validated.paymentMethod.toUpperCase(),
          },
        });

        if (payment.count === 0) {
          return reply.code(404).send({
            success: false,
            error: 'Not Found',
            message: 'Payment record not found',
          });
        }

        // Get booking ID from metadata
        const bookingId = paymentIntent.metadata.bookingId;

        // Update booking deposit status
        await prisma.booking.update({
          where: { id: bookingId },
          data: { depositPaid: true },
        });

        // Get updated payment
        const updatedPayment = await prisma.payment.findFirst({
          where: { stripePaymentIntentId: validated.paymentIntentId },
        });

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
