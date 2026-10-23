import "dotenv/config";
import { Redis, type RedisOptions } from "ioredis";

const REDIS_URL = process.env.REDIS_URL;

if (!REDIS_URL) {
  throw new Error("REDIS_URL is not defined in environment variables");
}

export const redis = new Redis(REDIS_URL, {
  lazyConnect: true,
});

redis.on("error", (error) => {
  console.error("Redis connection error:", error);
});

/**
 * Tạo connection Redis độc lập dành riêng cho hàng đợi BullMQ (Queue / Worker).
 * Bắt buộc thiết lập maxRetriesPerRequest = null theo yêu cầu của BullMQ.
 */
export function createRedisConnection(options?: RedisOptions): Redis {
  const conn = new Redis(REDIS_URL!, {
    maxRetriesPerRequest: null,
    lazyConnect: true,
    ...options,
  });

  conn.on("error", (error) => {
    console.error("[Queue Redis Connection Error]:", error);
  });

  return conn;
}

export async function connectRedis(): Promise<void> {
  if (redis.status !== "wait") return;
  await redis.connect();
}

export async function closeRedis(): Promise<void> {
  if (redis.status === "ready") {
    await redis.quit();
    return;
  }
  redis.disconnect();
}
