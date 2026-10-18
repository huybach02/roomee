import { Request, Response } from "express";
import { injectable } from "tsyringe";
import { GeneralService } from "./generalService.js";
import { provinceIdParamSchema } from "./generalSchema.js";
import { CustomResponse } from "../../utils/customResponse.js";

@injectable()
export class GeneralController {
  constructor(private generalService: GeneralService) {}

  public getProvinces = async (req: Request, res: Response): Promise<void> => {
    try {
      const provinces = await this.generalService.getProvinces();
      return CustomResponse.success(
        res,
        provinces,
        t("general.provincesSuccess"),
      );
    } catch (error) {
      console.error("Error fetching provinces:", error);
      return CustomResponse.error(
        res,
        t("common.internalServerError"),
        error instanceof Error ? error.message : error,
      );
    }
  };

  public getWardsByProvince = async (
    req: Request,
    res: Response,
  ): Promise<void> => {
    const parsed = provinceIdParamSchema.safeParse(req.params);

    if (!parsed.success) {
      const errors = parsed.error.issues.map((issue) => ({
        field: issue.path.join(".") || "provinceId",
        message: issue.message,
      }));
      return CustomResponse.error(res, t("validation.failed"), errors, 400);
    }

    try {
      const wards = await this.generalService.getWardsByProvince(
        parsed.data.provinceId,
      );
      return CustomResponse.success(res, wards, t("general.wardsSuccess"));
    } catch (error) {
      console.error("Error fetching wards:", error);
      return CustomResponse.error(
        res,
        t("common.internalServerError"),
        error instanceof Error ? error.message : error,
      );
    }
  };
}
