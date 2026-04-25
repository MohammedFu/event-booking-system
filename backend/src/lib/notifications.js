const prisma = require("./prisma");
const { emitToUser } = require("./realtime");
const { sendPushNotification } = require("./push_notifications");

async function createNotification({ userId, type, title, body, data }) {
  if (!userId || !type || !title) {
    return null;
  }

  try {
    const notification = await prisma.notification.create({
      data: {
        userId,
        type,
        title,
        body: body || "",
        data: data || {},
      },
    });

    try {
      await sendPushNotification({
        userId,
        title: notification.title,
        body: notification.body,
        data: {
          notificationId: notification.id,
          userId: notification.userId,
          type: notification.type,
          createdAt: notification.createdAt.toISOString(),
          ...(notification.data || {}),
        },
      });
    } catch (_) {
      // Keep the in-app notification even if push delivery fails.
    }

    const payload = {
      ...notification,
      createdAt: notification.createdAt?.toISOString?.() ?? notification.createdAt,
      updatedAt: notification.updatedAt?.toISOString?.() ?? notification.updatedAt,
    };

    emitToUser(notification.userId, "notification:new", payload);

    const realtimeEvent = {
      PROVIDER_MESSAGE: "booking:created",
      BOOKING_CONFIRMED: "booking:confirmed",
      BOOKING_CANCELLED: "booking:cancelled",
      PAYMENT_RECEIVED: "payment:received",
    }[notification.type];

    if (realtimeEvent) {
      emitToUser(notification.userId, realtimeEvent, payload);
    }

    return notification;
  } catch (_) {
    return null;
  }
}

async function createNotifications(notifications) {
  const validNotifications = (notifications || []).filter(
    (notification) =>
      notification?.userId && notification?.type && notification?.title,
  );

  await Promise.allSettled(
    validNotifications.map((notification) => createNotification(notification)),
  );
}

module.exports = {
  createNotification,
  createNotifications,
};
