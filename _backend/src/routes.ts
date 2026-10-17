import { Application, Router } from "express";
import { injectable } from "tsyringe";
import AuthRoutes from "./modules/auth/authRoutes.js";
import { API_PREFIX } from "./utils/constanst.js";

@injectable()
export class Routes {
  constructor(private authRoutes: AuthRoutes) {}

  public register(app: Application): void {
    const apiRouter = Router();
    app.use(API_PREFIX, apiRouter);

    apiRouter.use("/auth", this.authRoutes.router);
  }
}
