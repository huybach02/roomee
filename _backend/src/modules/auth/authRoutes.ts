import { Router } from "express";
import { injectable } from "tsyringe";
import { AuthController } from "./authController.js";
import {
  loginSchema,
  registerSchema,
  resendOtpSchema,
  verifyOtpSchema,
} from "./authSchema.js";
import { validate } from "../../middlewares/validateMiddleware.js";
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
  }
}

export default AuthRoutes;
