import { Request, Response, NextFunction } from "express";
import { injectable } from "tsyringe";
import { GeneralService } from "./generalService.js";
import { provinceIdParamSchema, type SyncRequestDto } from "./generalSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";
import { t } from "../../utils/i18n.js";

@injectable()
export class GeneralController {
  constructor(private generalService: GeneralService) {}

  public getProvinces = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const provinces = await this.generalService.getProvinces();
      CustomResponse.success(res, provinces, t("common.success"));
    } catch (error) {
      next(error);
    }
  };

  public getWardsByProvince = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const parsed = provinceIdParamSchema.safeParse(req.params);

    if (!parsed.success) {
      const errors = parsed.error.issues.map((issue) => ({
        field: issue.path.join(".") || "provinceId",
        message: issue.message,
      }));
      CustomResponse.error(res, t("validation.failed"), errors, 400);
      return;
    }

    try {
      const wards = await this.generalService.getWardsByProvince(
        parsed.data.provinceId,
      );
      CustomResponse.success(res, wards, t("common.success"));
    } catch (error) {
      next(error);
    }
  };

  public sync = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const syncRequest = req.body as SyncRequestDto;
      const userId = req.user?.sub;
      const userRole = req.user?.role;
      const result = await this.generalService.sync(
        syncRequest,
        userId,
        userRole,
      );
      CustomResponse.success(res, result, t("common.success"));
    } catch (error) {
      next(error);
    }
  };
}

