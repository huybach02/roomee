import { Application } from "express";
import { injectable } from "tsyringe";
import AuthRoutes from "./modules/auth/authRoutes.js";

@injectable()
export class Routes {
  constructor(private authRoutes: AuthRoutes) {}

  public register(app: Application): void {
    app.use("/api/v1/auth", this.authRoutes.router);
  }
}
