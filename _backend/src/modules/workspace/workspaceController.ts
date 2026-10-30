import { Request, Response, NextFunction } from "express";
import { injectable } from "tsyringe";
import { WorkspaceService } from "./workspaceService.js";
import {
  CreateWorkspaceDto,
  UpdateWorkspaceDto,
  workspaceParamSchema,
  workspaceQuerySchema,
} from "./workspaceSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";
import { AppError } from "../../utils/appError.js";

@injectable()
export class WorkspaceController {
  constructor(private workspaceService: WorkspaceService) {}

  public getWorkspaces = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;

      const query = workspaceQuerySchema.parse(req.query);
      const result = await this.workspaceService.getWorkspaces(
        userId as string,
        req.user?.role ?? "",
        query,
      );
      CustomResponse.success(res, result, t("common.success"));
    } catch (error) {
      next(error);
    }
  };

  public getWorkspaceById = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;

      const { id } = workspaceParamSchema.parse(req.params);
      const workspace = await this.workspaceService.getWorkspaceById(
        id as string,
        userId as string,
        req.user?.role ?? "",
      );
      CustomResponse.success(res, workspace, t("common.success"));
    } catch (error) {
      next(error);
    }
  };

  public createWorkspace = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;

      const dto = req.body as CreateWorkspaceDto;
      const workspace = await this.workspaceService.createWorkspace(
        userId as string,
        dto,
      );
      CustomResponse.success(res, workspace, t("workspace.createSuccess"), 201);
    } catch (error) {
      next(error);
    }
  };

  public updateWorkspace = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;

      const { id } = workspaceParamSchema.parse(req.params);
      const dto = req.body as UpdateWorkspaceDto;
      const workspace = await this.workspaceService.updateWorkspace(
        id as string,
        userId as string,
        req.user?.role ?? "",
        dto,
      );
      CustomResponse.success(res, workspace, t("workspace.updateSuccess"));
    } catch (error) {
      next(error);
    }
  };

  public deleteWorkspace = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const userId = req.user?.sub;

      const { id } = workspaceParamSchema.parse(req.params);
      await this.workspaceService.deleteWorkspace(
        id as string,
        userId as string,
      );
      CustomResponse.success(res, null, t("workspace.deleteSuccess"));
    } catch (error) {
      next(error);
    }
  };
}
