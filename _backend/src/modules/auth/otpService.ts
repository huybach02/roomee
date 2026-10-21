import { injectable } from "tsyringe";
import { redis } from "../../config/redis.js";
import { FunctionHelper } from "../../utils/functionHelper.js";
import { MAX_OTP_ATTEMPTS, TTL_OTP_SECONDS } from "../../utils/constanst.js";

export type OtpPurpose =
  | "register"
  | "forgot_password"
  | "change_email"
  | "resend";

@injectable()
export class OtpService {
  private readonly defaultTtlSeconds = TTL_OTP_SECONDS; // 10 phút

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
   * Tạo mã OTP ngẫu nhiên và lưu vào Redis kèm TTL
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
      redis.set(key, otp, "EX", ttlSeconds),
      redis.del(attemptsKey),
    ]);

    return otp;
  }

  /**
   * Kiểm tra mã OTP bằng Lua script atomic (chống race condition khi có 2 request đồng thời).
   * Nếu đúng: xóa OTP và attempts ngay trong 1 atomic transaction.
   * Nếu sai: tăng attempts counter; nếu vượt quá MAX_OTP_ATTEMPTS thì xóa luôn OTP.
   */
  public async verifyOtp(
    identifier: string,
    otp: string,
    purpose: OtpPurpose = "register",
  ): Promise<boolean> {
    const key = this.getRedisKey(identifier, purpose);
    const attemptsKey = this.getAttemptsRedisKey(identifier, purpose);

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

    return result === 1;
  }

  /**
   * Lấy mã OTP hiện tại trong Redis (nếu còn hạn)
   */
  public async getStoredOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
  ): Promise<string | null> {
    const key = this.getRedisKey(identifier, purpose);
    return await redis.get(key);
  }

  /**
   * Xóa mã OTP thủ công
   */
  public async deleteOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
  ): Promise<void> {
    const key = this.getRedisKey(identifier, purpose);
    const attemptsKey = this.getAttemptsRedisKey(identifier, purpose);
    await redis.del(key, attemptsKey);
  }
}
