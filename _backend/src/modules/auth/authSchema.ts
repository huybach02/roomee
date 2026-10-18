import { z } from "zod";
import { ruleValidates } from "../../utils/ruleValidate.js";
import { Gender, UserRole } from "../../utils/constanst.js";

export const registerSchema = z.object({
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule({ min: 6 }),
  fullName: ruleValidates.optionalString("Full name", { max: 100, min: 0 }),
  phoneNumber: ruleValidates.phoneRule("Phone number").optional().nullable(),
  avatarUrl: ruleValidates.optionalString("Avatar URL", { max: 255, min: 0 }),
  bio: ruleValidates.optionalString("Bio", { max: 500, min: 0 }),
  birthday: ruleValidates.dateRule("Birthday").optional().nullable(),
  gender: ruleValidates
    .enumRule("Gender", [Gender.MALE, Gender.FEMALE, Gender.OTHER] as const)
    .optional(),
  role: ruleValidates
    .enumRule("Role", [
      UserRole.LANDLORD,
      UserRole.STAFF,
      UserRole.TENANT,
      UserRole.ADMIN,
    ] as const)
    .optional(),
  isActive: z.boolean().optional(),
  provinceId: ruleValidates
    .numberRule("Province ID", { int: true, min: 1 })
    .optional()
    .nullable(),
  wardId: ruleValidates
    .numberRule("Ward ID", { int: true, min: 1 })
    .optional()
    .nullable(),
});

export const loginSchema = z.object({
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule({ min: 1 }),
  phoneNumber: ruleValidates.phoneRule("Phone number").optional().nullable(),
  rememberMe: z.boolean().optional(),
});

export const updateProfileSchema = z.object({
  fullName: ruleValidates.optionalString("Full name", { max: 100, min: 0 }),
  phoneNumber: ruleValidates.phoneRule("Phone number").optional().nullable(),
  avatarUrl: ruleValidates.optionalString("Avatar URL", { max: 255, min: 0 }),
  bio: ruleValidates.optionalString("Bio", { max: 500, min: 0 }),
  birthday: ruleValidates.dateRule("Birthday").optional().nullable(),
  gender: ruleValidates
    .enumRule("Gender", [Gender.MALE, Gender.FEMALE, Gender.OTHER] as const)
    .optional(),
  provinceId: ruleValidates
    .numberRule("Province ID", { int: true, min: 1 })
    .optional()
    .nullable(),
  wardId: ruleValidates
    .numberRule("Ward ID", { int: true, min: 1 })
    .optional()
    .nullable(),
});

export const forgotPasswordSchema = z.object({
  email: ruleValidates.emailRule,
});

export const resetPasswordSchema = z.object({
  token: ruleValidates.requiredString("Reset token"),
  newPassword: ruleValidates.passwordRule({ min: 6 }),
});

export const changePasswordSchema = z.object({
  currentPassword: ruleValidates.passwordRule({
    min: 1,
    label: "Current password",
  }),
  newPassword: ruleValidates.passwordRule({ min: 6, label: "New password" }),
});

export const verifyOtpSchema = z.object({
  email: ruleValidates.emailRule.optional(),
  phoneNumber: ruleValidates.phoneRule("Phone number").optional().nullable(),
  otp: ruleValidates.requiredString("OTP", { min: 4, max: 8 }),
});

export type RegisterDto = z.infer<typeof registerSchema>;
export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;
export type LoginDto = z.infer<typeof loginSchema>;
export type ForgotPasswordDto = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordDto = z.infer<typeof resetPasswordSchema>;
export type ChangePasswordDto = z.infer<typeof changePasswordSchema>;
export type VerifyOtpDto = z.infer<typeof verifyOtpSchema>;
