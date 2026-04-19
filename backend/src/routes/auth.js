const bcrypt = require('bcryptjs');
const zod = require('zod');
const prisma = require('../lib/prisma');
const crypto = require('crypto');

// Validation schemas
const registerSchema = zod.object({
  email: zod.string().email(),
  password: zod.string().min(8),
  fullName: zod.string().min(2),
  phone: zod.string().optional(),
  role: zod.enum(['CONSUMER', 'PROVIDER']).optional(),
});

const loginSchema = zod.object({
  email: zod.string().email(),
  password: zod.string(),
});

const refreshTokenSchema = zod.object({
  refreshToken: zod.string(),
});

// Helper functions
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function generateTokens(user, fastify) {
  const accessToken = fastify.jwt.sign({
    userId: user.id,
    email: user.email,
    role: user.role,
  });

  const refreshToken = crypto.randomBytes(40).toString('hex');
  const refreshTokenHash = hashToken(refreshToken);

  return { accessToken, refreshToken, refreshTokenHash };
}

async function routes(fastify, options) {
  // ═══════════════════════════════════════════════════════════
  // POST /register
  // ═══════════════════════════════════════════════════════════
  fastify.post('/register', {
    schema: {
      description: 'Register a new user',
      tags: ['Auth'],
      body: {
        type: 'object',
        required: ['email', 'password', 'fullName'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 8 },
          fullName: { type: 'string', minLength: 2 },
          phone: { type: 'string' },
          role: { type: 'string', enum: ['CONSUMER', 'PROVIDER'] },
        },
      },
      response: {
        201: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            data: {
              type: 'object',
              properties: {
                accessToken: { type: 'string' },
                refreshToken: { type: 'string' },
                expiresAt: { type: 'string' },
                user: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    email: { type: 'string' },
                    fullName: { type: 'string' },
                    role: { type: 'string' },
                  },
                },
              },
            },
          },
        },
      },
    },
    handler: async (request, reply) => {
      const validated = registerSchema.parse(request.body);

      // Check if user exists
      const existingUser = await prisma.user.findUnique({
        where: { email: validated.email },
      });

      if (existingUser) {
        return reply.code(409).send({
          success: false,
          error: 'Conflict',
          message: 'User with this email already exists',
        });
      }

      // Hash password
      const passwordHash = await bcrypt.hash(validated.password, 12);

      // Create user
      const user = await prisma.user.create({
        data: {
          email: validated.email,
          passwordHash,
          fullName: validated.fullName,
          phone: validated.phone,
          role: validated.role || 'CONSUMER',
        },
        select: {
          id: true,
          email: true,
          fullName: true,
          role: true,
          createdAt: true,
        },
      });

      // Generate tokens
      const { accessToken, refreshToken, refreshTokenHash } = generateTokens(user, fastify);

      // Save refresh token
      await prisma.refreshToken.create({
        data: {
          userId: user.id,
          tokenHash: refreshTokenHash,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        },
      });

      reply.code(201);
      return {
        success: true,
        data: {
          accessToken,
          refreshToken,
          expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 min
          user,
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /login
  // ═══════════════════════════════════════════════════════════
  fastify.post('/login', {
    schema: {
      description: 'Login user',
      tags: ['Auth'],
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const validated = loginSchema.parse(request.body);

      // Find user
      const user = await prisma.user.findUnique({
        where: { email: validated.email },
      });

      if (!user || !user.isActive) {
        return reply.code(401).send({
          success: false,
          error: 'Unauthorized',
          message: 'Invalid credentials',
        });
      }

      // Verify password
      const isValid = await bcrypt.compare(validated.password, user.passwordHash);

      if (!isValid) {
        return reply.code(401).send({
          success: false,
          error: 'Unauthorized',
          message: 'Invalid credentials',
        });
      }

      // Generate tokens
      const { accessToken, refreshToken, refreshTokenHash } = generateTokens(user, fastify);

      // Save refresh token
      await prisma.refreshToken.create({
        data: {
          userId: user.id,
          tokenHash: refreshTokenHash,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        },
      });

      return {
        success: true,
        data: {
          accessToken,
          refreshToken,
          expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
          user: {
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            role: user.role,
            avatarUrl: user.avatarUrl,
          },
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /refresh
  // ═══════════════════════════════════════════════════════════
  fastify.post('/refresh', {
    schema: {
      description: 'Refresh access token',
      tags: ['Auth'],
      body: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const validated = refreshTokenSchema.parse(request.body);
      const tokenHash = hashToken(validated.refreshToken);

      // Find refresh token
      const storedToken = await prisma.refreshToken.findFirst({
        where: {
          tokenHash,
          expiresAt: { gt: new Date() },
        },
        include: { user: true },
      });

      if (!storedToken) {
        return reply.code(401).send({
          success: false,
          error: 'Unauthorized',
          message: 'Invalid or expired refresh token',
        });
      }

      // Delete old token
      await prisma.refreshToken.delete({
        where: { id: storedToken.id },
      });

      // Generate new tokens
      const { accessToken, refreshToken, refreshTokenHash } = generateTokens(storedToken.user, fastify);

      // Save new refresh token
      await prisma.refreshToken.create({
        data: {
          userId: storedToken.user.id,
          tokenHash: refreshTokenHash,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        },
      });

      return {
        success: true,
        data: {
          accessToken,
          refreshToken,
          expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
        },
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /logout
  // ═══════════════════════════════════════════════════════════
  fastify.post('/logout', {
    schema: {
      description: 'Logout user',
      tags: ['Auth'],
      body: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string' },
        },
      },
    },
    handler: async (request, reply) => {
      const validated = refreshTokenSchema.parse(request.body);
      const tokenHash = hashToken(validated.refreshToken);

      // Delete refresh token
      await prisma.refreshToken.deleteMany({
        where: { tokenHash },
      });

      return {
        success: true,
        message: 'Logged out successfully',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // POST /forgot-password
  // ═══════════════════════════════════════════════════════════
  fastify.post('/forgot-password', {
    schema: {
      description: 'Request password reset',
      tags: ['Auth'],
      body: {
        type: 'object',
        required: ['email'],
        properties: {
          email: { type: 'string', format: 'email' },
        },
      },
    },
    handler: async (request, reply) => {
      const { email } = request.body;

      // TODO: Send password reset email
      // For now, just return success to prevent email enumeration

      return {
        success: true,
        message: 'If an account exists with this email, you will receive a password reset link.',
      };
    },
  });

  // ═══════════════════════════════════════════════════════════
  // GET /me (Get current user)
  // ═══════════════════════════════════════════════════════════
  fastify.get('/me', {
    onRequest: [fastify.authenticate],
    schema: {
      description: 'Get current user profile',
      tags: ['Auth'],
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
}

module.exports = routes;
