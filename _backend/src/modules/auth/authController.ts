import { Request, Response } from "express";
import { injectable } from "tsyringe";
import { AuthService } from "./authService.js";
import { LoginDto, RegisterDto } from "./authSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";

@injectable()
export class AuthController {
  constructor(private authService: AuthService) {}

  public registerUser = async (req: Request, res: Response): Promise<void> => {
    const dtoData = req.body as RegisterDto;

    try {
      const result = await this.authService.register(dtoData);
      return CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : t("common.internalServerError");
      return CustomResponse.error(res, message, null, 500);
    }
  };

  public loginUser = async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body as LoginDto;

    try {
      const result = await this.authService.login(email, password);
      return CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : t("common.internalServerError");
      return CustomResponse.error(res, message, null, 500);
    }
  };

  public resendOtp = async (req: Request, res: Response): Promise<void> => {
    const { email } = req.body as { email: string };

    try {
      const result = await this.authService.resendOtp(email);
      return CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : t("common.internalServerError");
      return CustomResponse.error(res, message, null, 500);
    }
  };

  public verifyOtp = async (req: Request, res: Response): Promise<void> => {
    const { email, otp } = req.body as { email: string; otp: string };

    try {
      const result = await this.authService.verifyOtp(email, otp);
      return CustomResponse.success(res, result, t("common.success"), 200);
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : t("common.internalServerError");
      return CustomResponse.error(res, message, null, 500);
    }
  };
}
