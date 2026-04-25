const { Server } = require("socket.io");

let io = null;

function initializeRealtimeServer(fastify) {
  if (io) {
    return io;
  }

  io = new Server(fastify.server, {
    cors: {
      origin:
        process.env.NODE_ENV === "production"
          ? ["https://yourapp.com"]
          : ["http://localhost:3000", "http://localhost:8080", "*"],
      credentials: true,
    },
  });

  io.use(async (socket, next) => {
    try {
      const authHeader = socket.handshake.headers.authorization;
      const tokenFromHeader = authHeader?.startsWith("Bearer ")
        ? authHeader.slice("Bearer ".length)
        : authHeader;
      const token = socket.handshake.auth?.token || tokenFromHeader;

      if (!token) {
        return next(new Error("Unauthorized"));
      }

      const payload = await fastify.jwt.verify(token);
      socket.user = payload;
      next();
    } catch (_) {
      next(new Error("Unauthorized"));
    }
  });

  io.on("connection", (socket) => {
    const userId = socket.user?.userId;
    if (!userId) {
      socket.disconnect(true);
      return;
    }

    socket.join(`user:${userId}`);
    socket.emit("socket:ready", {
      userId,
      connectedAt: new Date().toISOString(),
    });
  });

  fastify.addHook("onClose", async () => {
    await io.close();
    io = null;
  });

  return io;
}

function emitToUser(userId, event, payload) {
  if (!io || !userId) {
    return;
  }

  io.to(`user:${userId}`).emit(event, payload);
}

module.exports = {
  initializeRealtimeServer,
  emitToUser,
};
