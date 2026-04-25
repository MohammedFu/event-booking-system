const prisma = require("./prisma");

let firebaseAdmin = null;
let firebaseApp = null;

try {
  firebaseAdmin = require("firebase-admin");
} catch (_) {
  firebaseAdmin = null;
}

function getFirebaseApp() {
  if (!firebaseAdmin) {
    return null;
  }

  if (firebaseApp) {
    return firebaseApp;
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    return null;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    firebaseApp =
      firebaseAdmin.apps.length > 0
        ? firebaseAdmin.app()
        : firebaseAdmin.initializeApp({
            credential: firebaseAdmin.credential.cert(serviceAccount),
          });
    return firebaseApp;
  } catch (_) {
    return null;
  }
}

function normalizeData(data = {}) {
  const normalized = {};

  for (const [key, value] of Object.entries(data)) {
    if (value == null) {
      continue;
    }

    normalized[key] = typeof value === "string" ? value : JSON.stringify(value);
  }

  return normalized;
}

async function sendPushNotification({
  userId,
  title,
  body,
  data,
}) {
  if (!userId || !title) {
    return;
  }

  const app = getFirebaseApp();
  if (!app) {
    return;
  }

  const tokens = await prisma.deviceToken.findMany({
    where: {
      userId,
      isActive: true,
    },
    select: {
      id: true,
      token: true,
    },
  });

  if (tokens.length === 0) {
    return;
  }

  const messaging = firebaseAdmin.messaging(app);
  const response = await messaging.sendEachForMulticast({
    tokens: tokens.map((token) => token.token),
    notification: {
      title,
      body: body || "",
    },
    data: normalizeData(data),
    android: {
      notification: {
        channelId: "booking_updates",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });

  const invalidTokenIds = response.responses
    .map((item, index) => ({ item, token: tokens[index] }))
    .filter(
      ({ item }) =>
        !item.success &&
        item.error?.code &&
        [
          "messaging/invalid-registration-token",
          "messaging/registration-token-not-registered",
        ].includes(item.error.code),
    )
    .map(({ token }) => token.id);

  if (invalidTokenIds.length > 0) {
    await prisma.deviceToken.updateMany({
      where: {
        id: { in: invalidTokenIds },
      },
      data: {
        isActive: false,
      },
    });
  }
}

module.exports = {
  sendPushNotification,
};
