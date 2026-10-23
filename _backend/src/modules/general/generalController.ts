import { Request, Response, NextFunction } from "express";
import { injectable } from "tsyringe";
import { GeneralService } from "./generalService.js";
import { provinceIdParamSchema } from "./generalSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";

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
}
