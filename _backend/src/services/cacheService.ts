import { injectable } from "tsyringe";
import { redis } from "../config/redis.js";
import { PersistRedisRepository } from "../repositories/persistRedisRepository.js";

@injectable()
export class CacheService {
  constructor(private persistRedisRepository: PersistRedisRepository) {}

  /**
   * Lấy dữ liệu theo key.
   * Ưu tiên đọc từ Redis.
   * - Nếu Redis sẵn sàng: Trả về dữ liệu (hoặc null nếu cache miss). Tuyệt đối không fallback xuống DB khi cache miss.
   * - Chỉ fallback xuống PostgreSQL khi Redis gặp sự cố / không sẵn sàng.
   * - Nếu tìm thấy trong database còn hạn khi Redis phục hồi, tự động nạp ngược (rehydrate) lên Redis.
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

    // Nếu Redis hoạt động bình thường:
    // Trả về dữ liệu nếu có, hoặc trả về null nếu cache miss (KHÔNG fallback xuống DB khi Redis online)
    if (redisSuccess) {
      if (redisVal === null) {
        return null;
      }
      return this.parseValue<T>(redisVal);
    }

    // 2. Chỉ fallback xuống PostgreSQL nếu Redis lỗi hoặc mất kết nối
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
   * Helper parse chuỗi trả về từ Redis (tự động parse JSON nếu là Object/Array)
   */
  private parseValue<T>(val: string): T {
    const trimmed = val.trim();
    if (
      (trimmed.startsWith("{") && trimmed.endsWith("}")) ||
      (trimmed.startsWith("[") && trimmed.endsWith("]"))
    ) {
      try {
        return JSON.parse(trimmed) as T;
      } catch {
        return val as unknown as T;
      }
    }
    return val as unknown as T;
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
    try {
      await this.persistRedisRepository.setKey(key, value, ttlSeconds);
    } catch (error) {
      console.warn(
        `[CacheService] DB persist setKey failed for "${key}":`,
        error,
      );
    }
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
    try {
      await this.persistRedisRepository.deleteKeys(validKeys);
    } catch (error) {
      console.warn(`[CacheService] DB persist deleteKeys failed:`, error);
    }
  }

  /**
   * Lấy thời gian sống còn lại (TTL) tính theo giây
   */
  public async ttl(key: string): Promise<number> {
    if (!key) return -2;

    let redisSuccess = false;
    let redisTtl: number | null = null;

    try {
      if (redis.status === "ready") {
        redisTtl = await redis.ttl(key);
        redisSuccess = true;
      }
    } catch (error) {
      console.warn(`[CacheService] Redis ttl failed for "${key}":`, error);
    }

    // Nếu Redis hoạt động bình thường, trả về kết quả trực tiếp (-2, -1, hoặc > 0)
    if (redisSuccess && redisTtl !== null) {
      return redisTtl;
    }

    // Chỉ kiểm tra DB nếu Redis sập hoặc không kết nối được
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

    try {
      await this.persistRedisRepository.setKey(key, count, ttlSeconds, {
        preserveTtl: true,
      });
    } catch (error) {
      console.warn(
        `[CacheService] DB persist setKey failed for "${key}":`,
        error,
      );
    }
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
