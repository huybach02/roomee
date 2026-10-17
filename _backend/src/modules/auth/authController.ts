import { Request, Response } from "express";
import { injectable } from "tsyringe";
import { AuthService } from "./authService.js";
import { LoginDto, RegisterDto } from "./authSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";

@injectable()
export class AuthController {
  constructor(private authService: AuthService) {}

  public registerUser = async (req: Request, res: Response): Promise<void> => {
    const { username, email, password, language } = req.body as RegisterDto;
    const userLanguage = language || req.locale;

    try {
      const result = await this.authService.register(
        username,
        email,
        password,
        userLanguage,
      );
      // Gọi trực tiếp hàm global t()
      return CustomResponse.success(
        res,
        result,
        t("auth.registerSuccess"),
        201,
      );
    } catch (error) {
      console.error("Error registering user:", error);
      return CustomResponse.error(
        res,
        t("auth.registerError"),
        error instanceof Error ? error.message : error,
        500,
      );
    }
  };

  public loginUser = async (req: Request, res: Response): Promise<void> => {
    const { email, password, language } = req.body as LoginDto;
    const userLanguage = language || req.locale;

    try {
      const result = await this.authService.login(email, password, userLanguage);
      // Gọi trực tiếp hàm global t()
      return CustomResponse.success(
        res,
        result,
        t("auth.loginSuccess"),
        200,
      );
    } catch (error) {
      console.error("Error logging in user:", error);
      return CustomResponse.error(
        res,
        t("auth.loginError"),
        error instanceof Error ? error.message : error,
        500,
      );
    }
  };
}
