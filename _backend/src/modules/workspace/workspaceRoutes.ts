import { Router } from "express";
import { injectable } from "tsyringe";
import { WorkspaceController } from "./workspaceController.js";
import { authMiddleware } from "../../middlewares/authMiddleware.js";
import { validate } from "../../middlewares/validateMiddleware.js";
import {
  createWorkspaceSchema,
  updateWorkspaceSchema,
} from "./workspaceSchema.js";

@injectable()
export class WorkspaceRoutes {
  public router: Router;

  constructor(private workspaceController: WorkspaceController) {
    this.router = Router();
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    this.router.use(authMiddleware);

    this.router.get("/", this.workspaceController.getWorkspaces);
    this.router.get("/:id", this.workspaceController.getWorkspaceById);
    this.router.post(
      "/",
      validate(createWorkspaceSchema),
      this.workspaceController.createWorkspace,
    );
    this.router.put(
      "/:id",
      validate(updateWorkspaceSchema),
      this.workspaceController.updateWorkspace,
    );
    this.router.delete("/:id", this.workspaceController.deleteWorkspace);
  }
}

export default WorkspaceRoutes;
