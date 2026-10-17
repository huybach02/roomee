import { Request, Response } from "express";
import { injectable } from "tsyringe";
import { AuthService } from "./authService.js";
import { CustomResponse } from "../../utils/customResponse.js";

@injectable()
export class AuthController {
  constructor(private authService: AuthService) {}

  public registerUser = async (req: Request, res: Response): Promise<void> => {
    const { username, email, password } = req.body;

    try {
      const result = await this.authService.register(username, email, password);
      return CustomResponse.success(
        res,
        result,
        "User registered successfully.",
        201,
      );
    } catch (error) {
      console.error("Error registering user:", error);
      return CustomResponse.error(res, "Error registering user", error, 500);
    }
  };

  public loginUser = async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body;

    try {
      const result = await this.authService.login(email, password);
      return CustomResponse.success(
        res,
        result,
        "User logged in successfully",
        200,
      );
    } catch (error) {
      console.error("Error logging in user:", error);
      return CustomResponse.error(res, "Error logging in user", error, 500);
    }
  };
}
