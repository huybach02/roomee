import { Router } from "express";
import { injectable } from "tsyringe";
import { AuthController } from "./authController.js";
import {
  forgotPasswordSchema,
  loginSchema,
  registerSchema,
  resendOtpSchema,
  resetPasswordSchema,
  verifyOtpSchema,
} from "./authSchema.js";
import { validate } from "../../middlewares/validateMiddleware.js";
import { authMiddleware } from "../../middlewares/authMiddleware.js";
import {
  loginRateLimiter,
  registerRateLimiter,
  resendOtpRateLimiter,
  verifyOtpRateLimiter,
} from "../../middlewares/rateLimitMiddleware.js";

@injectable()
export class AuthRoutes {
  public router: Router;

  constructor(private authController: AuthController) {
    this.router = Router();
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    this.router.post(
      "/login",
      loginRateLimiter,
      validate(loginSchema),
      this.authController.loginUser,
    );
    this.router.post(
      "/register",
      registerRateLimiter,
      validate(registerSchema),
      this.authController.registerUser,
    );
    this.router.post(
      "/resend-otp",
      resendOtpRateLimiter,
      validate(resendOtpSchema),
      this.authController.resendOtp,
    );
    this.router.post(
      "/verify-otp",
      verifyOtpRateLimiter,
      validate(verifyOtpSchema),
      this.authController.verifyOtp,
    );
    this.router.post(
      "/forgot-password",
      resendOtpRateLimiter,
      validate(forgotPasswordSchema),
      this.authController.forgotPassword,
    );
    this.router.post(
      "/verify-reset-otp",
      verifyOtpRateLimiter,
      validate(verifyOtpSchema),
      this.authController.verifyResetOtp,
    );
    this.router.post(
      "/reset-password",
      loginRateLimiter,
      validate(resetPasswordSchema),
      this.authController.resetPassword,
    );
    this.router.post(
      "/logout",
      authMiddleware,
      this.authController.logoutUser,
    );
  }
}

export default AuthRoutes;
