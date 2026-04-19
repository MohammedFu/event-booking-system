const redis = require('redis');

let client = null;

async function getRedisClient() {
  if (client) return client;

  client = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  });

  client.on('error', (err) => {
    console.error('Redis Client Error:', err);
  });

  client.on('connect', () => {
    console.log('Redis Client Connected');
  });

  await client.connect();
  return client;
}

// Slot locking helpers
async function lockSlot(serviceId, date, startTime, endTime, ttlSeconds = 600) {
  const redisClient = await getRedisClient();
  const lockKey = `slot:lock:${serviceId}:${date}:${startTime}-${endTime}`;
  
  // Try to set with NX (only if not exists)
  const result = await redisClient.set(lockKey, 'locked', {
    NX: true,
    EX: ttlSeconds,
  });
  
  return result === 'OK';
}

async function releaseSlot(serviceId, date, startTime, endTime) {
  const redisClient = await getRedisClient();
  const lockKey = `slot:lock:${serviceId}:${date}:${startTime}-${endTime}`;
  
  await redisClient.del(lockKey);
}

async function isSlotLocked(serviceId, date, startTime, endTime) {
  const redisClient = await getRedisClient();
  const lockKey = `slot:lock:${serviceId}:${date}:${startTime}-${endTime}`;
  
  const exists = await redisClient.exists(lockKey);
  return exists === 1;
}

module.exports = {
  getRedisClient,
  lockSlot,
  releaseSlot,
  isSlotLocked,
};
