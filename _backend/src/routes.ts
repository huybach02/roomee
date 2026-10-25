import { Application, Router } from "express";
import { injectable } from "tsyringe";
import AuthRoutes from "./modules/auth/authRoutes.js";
import GeneralRoutes from "./modules/general/generalRoutes.js";
import WorkspaceRoutes from "./modules/workspace/workspaceRoutes.js";
import { API_PREFIX } from "./utils/constanst.js";

@injectable()
export class Routes {
  constructor(
    private authRoutes: AuthRoutes,
    private generalRoutes: GeneralRoutes,
    private workspaceRoutes: WorkspaceRoutes,
  ) {}

  public register(app: Application): void {
    const apiRouter = Router();
    app.use(API_PREFIX, apiRouter);

    apiRouter.use("/auth", this.authRoutes.router);
    apiRouter.use("/general", this.generalRoutes.router);
    apiRouter.use("/workspaces", this.workspaceRoutes.router);
  }
}
