export const DEFAULT_PORT = 5000;
export const NODE_ENV = process.env.NODE_ENV || "development";
export const API_PREFIX = process.env.API_PREFIX || "/api/v1";
export const TTL_OTP_SECONDS = 600; // 10 phút
export const OTP_EXPIRES_IN_MINUTES = Math.floor(TTL_OTP_SECONDS / 60);
export const MAX_OTP_ATTEMPTS = 5; // Tối đa 5 lần thử sai mã OTP

export enum UserRole {
  LANDLORD = "landlord", // Chủ trọ
  STAFF = "staff", // Nhân viên
  TENANT = "tenant", // Người thuê
  ADMIN = "admin", // Quản trị viên
}

export enum Gender {
  MALE = "male",
  FEMALE = "female",
  OTHER = "other",
}

export const CODE_RESPONSE = {
  NEED_VERIFY_EMAIL: "NEED_VERIFY_EMAIL",
};
