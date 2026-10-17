export const DEFAULT_PORT = 5000;
export const NODE_ENV = process.env.NODE_ENV || "development";
export const API_PREFIX = process.env.API_PREFIX || "/api/v1";

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
