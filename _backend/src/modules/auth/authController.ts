import { Request, Response, NextFunction } from "express";
import { injectable } from "tsyringe";
import { AuthService } from "./authService.js";
import {
  ForgotPasswordDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyOtpDto,
} from "./authSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";
import { AppError } from "../../utils/appError.js";

@injectable()
export class AuthController {
  constructor(private authService: AuthService) {}

  public registerUser = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const dtoData = req.body as RegisterDto;

    try {
      const result = await this.authService.register(dtoData);
      CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public loginUser = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { email, password } = req.body as LoginDto;
    const userAgent = req.headers["user-agent"];
    const deviceInfo =
      typeof userAgent === "string" ? userAgent.slice(0, 255) : null;
    const ipAddress = req.ip ? req.ip.slice(0, 45) : null;

    try {
      const result = await this.authService.login(
        email,
        password,
        deviceInfo ?? undefined,
        ipAddress ?? undefined,
      );
      CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public resendOtp = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { email } = req.body as { email: string };

    try {
      const result = await this.authService.resendOtp(email);
      CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public verifyOtp = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { email, otp } = req.body as { email: string; otp: string };

    try {
      const result = await this.authService.verifyOtp(email, otp);
      CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public forgotPassword = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { email } = req.body as ForgotPasswordDto;

    try {
      await this.authService.forgotPassword(email);
      CustomResponse.success(res, null, t("auth.forgotPasswordSent"), 200);
    } catch (error) {
      next(error);
    }
  };

  public verifyResetOtp = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { email, otp } = req.body as VerifyOtpDto;

    try {
      const result = await this.authService.verifyResetOtp(email, otp);
      CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public resetPassword = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { token, newPassword } = req.body as ResetPasswordDto;

    try {
      await this.authService.resetPassword(token, newPassword);
      CustomResponse.success(res, null, t("auth.resetPasswordSuccess"), 200);
    } catch (error) {
      next(error);
    }
  };

  public logoutUser = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const token =
      req.token || req.headers.authorization?.replace(/^Bearer\s+/i, "");

    try {
      if (token) {
        await this.authService.logout(token);
      }
      CustomResponse.success(res, null, t("auth.logoutSuccess"), 200);
    } catch (error) {
      next(error);
    }
  };

  public getMe = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;
      if (!userId) {
        throw AppError.unauthorized(t("common.unauthorized"));
      }
      const user = await this.authService.getProfile(userId);
      CustomResponse.success(res, user, t("common.success"), 200);
    } catch (error) {
      next(error);
    }
  };

  public refreshToken = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const { refreshToken } = req.body as RefreshTokenDto;
    const userAgent = req.headers["user-agent"];
    const deviceInfo =
      typeof userAgent === "string" ? userAgent.slice(0, 255) : null;
    const ipAddress = req.ip ? req.ip.slice(0, 45) : null;

    try {
      const result = await this.authService.refreshToken(
        refreshToken,
        deviceInfo ?? undefined,
        ipAddress ?? undefined,
      );
      CustomResponse.success(
        res,
        result,
        t("auth.refreshTokenSuccess"),
        200,
      );
    } catch (error) {
      next(error);
    }
  };
}
