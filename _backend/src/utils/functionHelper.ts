import crypto from "node:crypto";

export class FunctionHelper {
  /**
   * Tạo chuỗi OTP ngẫu nhiên an toàn với độ dài xác định (mặc định 6 chữ số)
   */
  public static generateOtp(length: number = 6): string {
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return crypto.randomInt(min, max + 1).toString();
  }
}
