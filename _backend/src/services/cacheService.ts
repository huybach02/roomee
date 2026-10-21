import { injectable } from "tsyringe";
import { redis } from "../config/redis.js";
import { PersistRedisRepository } from "../repositories/persistRedisRepository.js";

@injectable()
export class CacheService {
  constructor(private persistRedisRepository: PersistRedisRepository) {}

  /**
   * Lấy dữ liệu theo key.
   * Ưu tiên đọc từ Redis. Nếu Redis không có hoặc gặp sự cố, fallback xuống database.
   * Nếu tìm thấy trong database còn hạn, tự động nạp ngược (rehydrate) lên Redis.
   */
  public async get<T = any>(key: string): Promise<T | null> {
    if (!key) return null;

    // 1. Thử lấy từ Redis trước
    let redisVal: string | null = null;
    let redisSuccess = false;

    try {
      if (redis.status === "ready") {
        redisVal = await redis.get(key);
        redisSuccess = true;
      }
    } catch (error) {
      console.warn(`[CacheService] Redis get failed for "${key}":`, error);
    }

    // Nếu Redis có dữ liệu: Tự động parse nếu là JSON (Object/Array), giữ nguyên nếu là chuỗi
    if (redisSuccess && redisVal !== null) {
      const trimmed = redisVal.trim();
      if (
        (trimmed.startsWith("{") && trimmed.endsWith("}")) ||
        (trimmed.startsWith("[") && trimmed.endsWith("]"))
      ) {
        try {
          return JSON.parse(trimmed) as T;
        } catch {
          return redisVal as unknown as T;
        }
      }
      return redisVal as unknown as T;
    }

    // 2. Fallback xuống PostgreSQL nếu Redis miss hoặc Redis lỗi
    const dbRecord = await this.persistRedisRepository.getValidKey(key);
    if (!dbRecord) {
      return null;
    }

    // 3. Rehydrate: Nạp ngược lại vào Redis nếu còn hạn và Redis sẵn sàng
    let remainingTtl: number | undefined;
    if (dbRecord.expiredAt) {
      const diffInSeconds = Math.floor(
        (dbRecord.expiredAt.getTime() - Date.now()) / 1000,
      );
      if (diffInSeconds <= 0) {
        return null;
      }
      remainingTtl = diffInSeconds;
    }

    try {
      if (redis.status === "ready") {
        const valStr =
          typeof dbRecord.value === "string"
            ? dbRecord.value
            : JSON.stringify(dbRecord.value);

        if (remainingTtl !== undefined && remainingTtl > 0) {
          await redis.set(key, valStr, "EX", remainingTtl);
        } else if (remainingTtl === undefined) {
          await redis.set(key, valStr);
        }
      }
    } catch (error) {
      console.warn(`[CacheService] Rehydrate failed for "${key}":`, error);
    }

    return dbRecord.value as T;
  }

  /**
   * Ghi dữ liệu đồng thời vào Redis và Database
   */
  public async set(
    key: string,
    value: any,
    ttlSeconds?: number,
  ): Promise<void> {
    if (!key) return;

    // 1. Ghi vào Redis
    const valStr = typeof value === "string" ? value : JSON.stringify(value);
    try {
      if (redis.status === "ready") {
        if (ttlSeconds && ttlSeconds > 0) {
          await redis.set(key, valStr, "EX", ttlSeconds);
        } else {
          await redis.set(key, valStr);
        }
      }
    } catch (error) {
      console.warn(`[CacheService] Redis set failed for "${key}":`, error);
    }

    // 2. Ghi vào PostgreSQL (persist_redis)
    await this.persistRedisRepository.setKey(key, value, ttlSeconds);
  }

  /**
   * Ghi dữ liệu với cờ NX (Not Exists) - Dùng cho cooldown và distributed lock
   */
  public async setNx(
    key: string,
    value: any,
    ttlSeconds: number,
  ): Promise<boolean> {
    if (!key) return false;

    const valStr = typeof value === "string" ? value : JSON.stringify(value);
    let redisAcquired: boolean | null = null;

    try {
      if (redis.status === "ready") {
        const res = await redis.set(key, valStr, "EX", ttlSeconds, "NX");
        redisAcquired = Boolean(res);
      }
    } catch (error) {
      console.warn(`[CacheService] Redis setNx failed for "${key}":`, error);
    }

    // Nếu Redis thành công đưa ra kết luận
    if (redisAcquired !== null) {
      if (redisAcquired) {
        // Đồng bộ xuống DB
        await this.persistRedisRepository.setKey(key, value, ttlSeconds);
        return true;
      }
      return false;
    }

    // Nếu Redis sập, kiểm tra tình trạng trong DB
    const existing = await this.persistRedisRepository.getValidKey(key);
    if (existing) {
      return false;
    }

    await this.persistRedisRepository.setKey(key, value, ttlSeconds);
    return true;
  }

  /**
   * Xóa một hoặc nhiều key khỏi cả Redis và Database
   */
  public async del(...keys: string[]): Promise<void> {
    const validKeys = keys.filter((k) => Boolean(k && k.trim()));
    if (validKeys.length === 0) return;

    // 1. Xóa trên Redis
    try {
      if (redis.status === "ready") {
        await redis.del(...validKeys);
      }
    } catch (error) {
      console.warn(`[CacheService] Redis del failed:`, error);
    }

    // 2. Xóa trên Database
    await this.persistRedisRepository.deleteKeys(validKeys);
  }

  /**
   * Lấy thời gian sống còn lại (TTL) tính theo giây
   */
  public async ttl(key: string): Promise<number> {
    if (!key) return -2;

    try {
      if (redis.status === "ready") {
        const redisTtl = await redis.ttl(key);
        if (redisTtl > 0) return redisTtl;
      }
    } catch (error) {
      console.warn(`[CacheService] Redis ttl failed for "${key}":`, error);
    }

    const dbRecord = await this.persistRedisRepository.getValidKey(key);
    if (!dbRecord || !dbRecord.expiredAt) return -2;

    const diff = Math.floor(
      (dbRecord.expiredAt.getTime() - Date.now()) / 1000,
    );
    return diff > 0 ? diff : -2;
  }

  /**
   * Tăng giá trị số của key và đồng bộ DB
   */
  public async incr(key: string, ttlSeconds?: number): Promise<number> {
    if (!key) return 0;

    let count: number | null = null;

    try {
      if (redis.status === "ready") {
        count = await redis.incr(key);
        if (count === 1 && ttlSeconds && ttlSeconds > 0) {
          await redis.expire(key, ttlSeconds);
        }
      }
    } catch (error) {
      console.warn(`[CacheService] Redis incr failed for "${key}":`, error);
    }

    if (count === null) {
      const dbRecord = await this.persistRedisRepository.getValidKey(key);
      const current = Number(dbRecord?.value) || 0;
      count = current + 1;
    }

    await this.persistRedisRepository.setKey(key, count, ttlSeconds);
    return count;
  }

  /**
   * Đặt thời gian hết hạn cho key
   */
  public async expire(key: string, ttlSeconds: number): Promise<void> {
    if (!key || ttlSeconds <= 0) return;

    try {
      if (redis.status === "ready") {
        await redis.expire(key, ttlSeconds);
      }
    } catch (error) {
      console.warn(`[CacheService] Redis expire failed for "${key}":`, error);
    }

    const dbRecord = await this.persistRedisRepository.getValidKey(key);
    if (dbRecord) {
      await this.persistRedisRepository.setKey(
        key,
        dbRecord.value,
        ttlSeconds,
      );
    }
  }
}
