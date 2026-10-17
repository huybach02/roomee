import "dotenv/config";
import { Redis } from "ioredis";

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
