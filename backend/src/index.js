const fastify = require("fastify")({
  logger: {
    level: process.env.NODE_ENV === "production" ? "info" : "debug",
  },
});
const cors = require("@fastify/cors");
const jwt = require("@fastify/jwt");
const swagger = require("@fastify/swagger");
const swaggerUi = require("@fastify/swagger-ui");
const multipart = require("@fastify/multipart");
const path = require("path");
const fs = require("fs");
const { initializeRealtimeServer } = require("./lib/realtime");
require("dotenv").config();

// Ensure upload directory exists
const uploadDir = process.env.UPLOAD_DIR || "./uploads";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Register plugins
async function registerPlugins() {
  // CORS
  await fastify.register(cors, {
    origin:
      process.env.NODE_ENV === "production"
        ? ["https://yourapp.com"]
        : ["http://localhost:3000", "http://localhost:8080", "*"],
    credentials: true,
  });

  // JWT
  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET || "dev-secret",
    sign: {
      expiresIn: "15m",
    },
  });

  // Multipart for file uploads
  await fastify.register(multipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB max file size
      files: 10, // max 10 files per upload
    },
  });

  // Static file serving for uploads
  await fastify.register(require("@fastify/static"), {
    root: path.join(__dirname, "..", uploadDir),
    prefix: "/uploads/",
  });

  // Swagger documentation
  await fastify.register(swagger, {
    openapi: {
      info: {
        title: "Event Booking API",
        description: "API for Event & Wedding Booking System",
        version: "1.0.0",
      },
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server",
        },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
          },
        },
      },
    },
  });

  await fastify.register(swaggerUi, {
    routePrefix: "/docs",
  });
}

// Decorate Fastify with auth helper
fastify.decorate("authenticate", async function (request, reply) {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.code(401).send({
      success: false,
      error: "Unauthorized",
      message: err.message,
    });
  }
});

// Register routes
async function registerRoutes() {
  // Health check
  fastify.get("/", async () => {
    return {
      status: "ok",
      service: "event-booking-api",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
    };
  });

  fastify.get("/health", async () => {
    return {
      status: "healthy",
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  });

  // API routes
  await fastify.register(require("./routes/auth"), { prefix: "/api/v1/auth" });
  await fastify.register(require("./routes/services"), {
    prefix: "/api/v1/services",
  });
  await fastify.register(require("./routes/bookings"), {
    prefix: "/api/v1/bookings",
  });
  await fastify.register(require("./routes/payments"), {
    prefix: "/api/v1/payments",
  });
  await fastify.register(require("./routes/provider"), {
    prefix: "/api/v1/provider",
  });
  await fastify.register(require("./routes/users"), {
    prefix: "/api/v1/users",
  });
}

// Error handler
fastify.setErrorHandler((error, request, reply) => {
  fastify.log.error(error);

  if (error.validation) {
    return reply.code(400).send({
      success: false,
      error: "Validation Error",
      message: error.message,
      details: error.validation,
    });
  }

  const statusCode = error.statusCode || 500;
  reply.code(statusCode).send({
    success: false,
    error: error.name || "Internal Server Error",
    message:
      process.env.NODE_ENV === "production"
        ? "An unexpected error occurred"
        : error.message,
  });
});

// Not found handler
fastify.setNotFoundHandler((request, reply) => {
  reply.code(404).send({
    success: false,
    error: "Not Found",
    message: `Route ${request.method} ${request.url} not found`,
  });
});

// Start server
async function start() {
  try {
    await registerPlugins();
    await registerRoutes();
    initializeRealtimeServer(fastify);

    const port = process.env.PORT || 3000;
    const host = process.env.HOST || "0.0.0.0";

    await fastify.listen({ port, host });
    fastify.log.info(`Server running at http://${host}:${port}`);
    fastify.log.info(`API docs available at http://${host}:${port}/docs`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on("SIGINT", async () => {
  fastify.log.info("SIGINT received, shutting down gracefully");
  await fastify.close();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  fastify.log.info("SIGTERM received, shutting down gracefully");
  await fastify.close();
  process.exit(0);
});

start();
