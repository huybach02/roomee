import { Router } from "express";
import { injectable } from "tsyringe";
import { AuthController } from "./authController.js";
import { loginSchema, registerSchema } from "./authSchema.js";
import { validate } from "../../middlewares/validateMiddleware.js";

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
      validate(loginSchema),
      this.authController.loginUser,
    );
    this.router.post(
      "/register",
      validate(registerSchema),
      this.authController.registerUser,
    );
  }
}

export default AuthRoutes;
