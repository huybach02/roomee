import { injectable } from "tsyringe";
import { redis } from "../../config/redis.js";
import { FunctionHelper } from "../../utils/functionHelper.js";
import { MAX_OTP_ATTEMPTS, TTL_OTP_SECONDS } from "../../utils/constanst.js";
import { CacheService } from "../../services/cacheService.js";

export type OtpPurpose =
  | "register"
  | "forgot_password"
  | "change_email"
  | "resend";

@injectable()
export class OtpService {
  private readonly defaultTtlSeconds = TTL_OTP_SECONDS; // 10 phút

  constructor(private cacheService: CacheService) {}

  /**
   * Sinh key lưu trong Redis theo mục đích và định danh (email/phone)
   */
  private getRedisKey(identifier: string, purpose: OtpPurpose): string {
    return `otp:${purpose}:${identifier.trim().toLowerCase()}`;
  }

  /**
   * Sinh key đếm số lần nhập sai OTP trong Redis
   */
  private getAttemptsRedisKey(identifier: string, purpose: OtpPurpose): string {
    return `otp:attempts:${purpose}:${identifier.trim().toLowerCase()}`;
  }

  /**
   * Tạo mã OTP ngẫu nhiên và lưu vào Redis + Database kèm TTL
   */
  public async generateAndSaveOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
    ttlSeconds: number = this.defaultTtlSeconds,
  ): Promise<string> {
    const otp = FunctionHelper.generateOtp(6);
    const key = this.getRedisKey(identifier, purpose);
    const attemptsKey = this.getAttemptsRedisKey(identifier, purpose);

    await Promise.all([
      this.cacheService.set(key, otp, ttlSeconds),
      this.cacheService.del(attemptsKey),
    ]);

    return otp;
  }

  /**
   * Kiểm tra mã OTP bằng Lua script atomic (nếu Redis hoạt động).
   * Đồng thời fallback xuống Database nếu Redis mất data hoặc gặp sự cố.
   */
  public async verifyOtp(
    identifier: string,
    otp: string,
    purpose: OtpPurpose = "register",
  ): Promise<boolean> {
    const key = this.getRedisKey(identifier, purpose);
    const attemptsKey = this.getAttemptsRedisKey(identifier, purpose);

    // 1. Thử xác thực nhanh bằng atomic Lua script nếu Redis sẵn sàng
    if (redis.status === "ready") {
      try {
        const luaScript = `
          local stored = redis.call('get', KEYS[1])
          if not stored then
            return 0
          end
          if stored == ARGV[1] then
            redis.call('del', KEYS[1], KEYS[2])
            return 1
          else
            local attempts = redis.call('incr', KEYS[2])
            if attempts == 1 then
              local ttl = redis.call('ttl', KEYS[1])
              if ttl > 0 then
                redis.call('expire', KEYS[2], ttl)
              end
            end
            if attempts >= tonumber(ARGV[2]) then
              redis.call('del', KEYS[1], KEYS[2])
            end
            return -1
          end
        `;

        const result = (await redis.eval(
          luaScript,
          2,
          key,
          attemptsKey,
          otp.trim(),
          MAX_OTP_ATTEMPTS,
        )) as number;

        if (result === 1) {
          // Xóa đồng thời khỏi Database
          await this.cacheService.del(key, attemptsKey);
          return true;
        } else if (result === -1) {
          // Sai OTP: Đồng bộ attempts xuống DB hoặc xóa nếu vượt quá số lần
          const attempts = await redis.get(attemptsKey);
          if (attempts) {
            await this.cacheService.set(
              attemptsKey,
              attempts,
              this.defaultTtlSeconds,
            );
          } else {
            await this.cacheService.del(key, attemptsKey);
          }
          return false;
        }
        // result === 0: Không tìm thấy key trên Redis (có thể do Redis vừa restart)
        // Chuyển xuống bước fallback Database
      } catch (error) {
        console.warn(
          "[OtpService] Redis verify failed, falling back to database:",
          error,
        );
      }
    }

    // 2. Fallback: Kiểm tra dưới database qua CacheService (nếu Redis miss hoặc sập)
    const storedOtp = await this.cacheService.get<string>(key);
    if (!storedOtp) {
      return false;
    }

    if (storedOtp.trim() === otp.trim()) {
      await this.cacheService.del(key, attemptsKey);
      return true;
    }

    // Sai OTP: tăng attempts trong DB & Redis
    const currentAttempts = await this.cacheService.incr(
      attemptsKey,
      this.defaultTtlSeconds,
    );
    if (currentAttempts >= MAX_OTP_ATTEMPTS) {
      await this.cacheService.del(key, attemptsKey);
    }
    return false;
  }

  /**
   * Lấy mã OTP hiện tại (ưu tiên Redis, fallback DB)
   */
  public async getStoredOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
  ): Promise<string | null> {
    const key = this.getRedisKey(identifier, purpose);
    return await this.cacheService.get<string>(key);
  }

  /**
   * Xóa mã OTP thủ công ở cả Redis và DB
   */
  public async deleteOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
  ): Promise<void> {
    const key = this.getRedisKey(identifier, purpose);
    const attemptsKey = this.getAttemptsRedisKey(identifier, purpose);
    await this.cacheService.del(key, attemptsKey);
  }
}
