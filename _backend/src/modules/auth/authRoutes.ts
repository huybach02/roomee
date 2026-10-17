import { Router } from "express";
import { injectable } from "tsyringe";
import { AuthController } from "./authController.js";

@injectable()
export class AuthRoutes {
  public router: Router;

  constructor(private authController: AuthController) {
    this.router = Router();
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    this.router.post("/login", this.authController.loginUser);
    this.router.post("/register", this.authController.registerUser);
  }
}

export default AuthRoutes;
