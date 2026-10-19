import { injectable } from "tsyringe";
import { redis } from "../../config/redis.js";
import { FunctionHelper } from "../../utils/functionHelper.js";
import { TTL_OTP_SECONDS } from "../../utils/constanst.js";

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
   * Tạo mã OTP ngẫu nhiên và lưu vào Redis kèm TTL
   */
  public async generateAndSaveOtp(
    identifier: string,
    purpose: OtpPurpose = "register",
    ttlSeconds: number = this.defaultTtlSeconds,
  ): Promise<string> {
    const otp = FunctionHelper.generateOtp(6);
    const key = this.getRedisKey(identifier, purpose);

    await redis.set(key, otp, "EX", ttlSeconds);
    return otp;
  }

  /**
   * Kiểm tra mã OTP. Nếu đúng, xóa mã trong Redis
   */
  public async verifyOtp(
    identifier: string,
    otp: string,
    purpose: OtpPurpose = "register",
  ): Promise<boolean> {
    const key = this.getRedisKey(identifier, purpose);
    const storedOtp = await redis.get(key);

    if (!storedOtp || storedOtp !== otp.trim()) {
      return false;
    }

    // Xóa OTP ngay khi xác thực thành công
    await redis.del(key);
    return true;
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
    await redis.del(key);
  }
}
