import rateLimit from "express-rate-limit";
import { Request, Response } from "express";
import { CustomResponse } from "../utils/customResponse.js";
import { t } from "../utils/i18n.js";

interface CreateRateLimiterOptions {
  windowMs?: number;
  max?: number;
  message?: string;
}

export function createRateLimiter(options: CreateRateLimiterOptions = {}) {
  const {
    windowMs = 15 * 60 * 1000,
    max = 100,
    message,
  } = options;

  return rateLimit({
    windowMs,
    limit: max,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      return CustomResponse.error(
        res,
        message || t("common.tooManyRequests"),
        null,
        429,
      );
    },
  });
}

// Rate limiter cho đăng ký tài khoản: tối đa 10 lần / 15 phút
export const registerRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
});

// Rate limiter cho gửi lại OTP: tối đa 3 lần / phút
export const resendOtpRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 3,
});

// Rate limiter cho xác thực OTP: tối đa 10 lần / phút
export const verifyOtpRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 10,
});

// Rate limiter cho đăng nhập: tối đa 10 lần / phút
export const loginRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 10,
});
