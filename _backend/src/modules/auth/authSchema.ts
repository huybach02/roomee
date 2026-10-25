import { z } from "zod";
import { ruleValidates } from "../../utils/ruleValidate.js";
import { Gender, UserRole } from "../../utils/constanst.js";

export const registerSchema = z.object({
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule({ min: 8 }),
  fullName: ruleValidates.optionalString({ max: 100 }),
  phoneNumber: ruleValidates.phoneRule().optional().nullable(),
  avatarUrl: ruleValidates.optionalString({ max: 255 }),
  bio: ruleValidates.optionalString({ max: 500 }),
  birthday: ruleValidates.dateRule().optional().nullable(),
  gender: ruleValidates
    .enumRule([Gender.MALE, Gender.FEMALE, Gender.OTHER] as const)
    .optional(),
  role: ruleValidates
    .enumRule([UserRole.LANDLORD, UserRole.TENANT] as const)
    .optional(),
  provinceId: ruleValidates.idRule().optional().nullable(),
  wardId: ruleValidates.idRule().optional().nullable(),
});

export const loginSchema = z.object({
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule({ min: 1 }),
  phoneNumber: ruleValidates.phoneRule().optional().nullable(),
  rememberMe: z.boolean().optional(),
});

export const updateProfileSchema = z.object({
  fullName: ruleValidates.optionalString({ max: 100 }),
  phoneNumber: ruleValidates.phoneRule().optional().nullable(),
  avatarUrl: ruleValidates.optionalString({ max: 255 }),
  bio: ruleValidates.optionalString({ max: 500 }),
  birthday: ruleValidates.dateRule().optional().nullable(),
  gender: ruleValidates
    .enumRule([Gender.MALE, Gender.FEMALE, Gender.OTHER] as const)
    .optional(),
  provinceId: ruleValidates.idRule().optional().nullable(),
  wardId: ruleValidates.idRule().optional().nullable(),
});

export const forgotPasswordSchema = z.object({
  email: ruleValidates.emailRule,
});

export const resetPasswordSchema = z.object({
  token: ruleValidates.requiredString(),
  newPassword: ruleValidates.passwordRule({ min: 8 }),
});

export const changePasswordSchema = z.object({
  currentPassword: ruleValidates.passwordRule({ min: 1 }),
  newPassword: ruleValidates.passwordRule({ min: 8 }),
});

export const resendOtpSchema = z.object({
  email: ruleValidates.emailRule,
});

export const verifyOtpSchema = z.object({
  email: ruleValidates.emailRule,
  otp: ruleValidates.otpRule(),
});

export const refreshTokenSchema = z.object({
  refreshToken: ruleValidates.requiredString(),
});

export type RegisterDto = z.infer<typeof registerSchema>;
export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;
export type LoginDto = z.infer<typeof loginSchema>;
export type ForgotPasswordDto = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordDto = z.infer<typeof resetPasswordSchema>;
export type ChangePasswordDto = z.infer<typeof changePasswordSchema>;
export type ResendOtpDto = z.infer<typeof resendOtpSchema>;
export type VerifyOtpDto = z.infer<typeof verifyOtpSchema>;
export type RefreshTokenDto = z.infer<typeof refreshTokenSchema>;
