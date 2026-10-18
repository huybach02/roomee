import { Router } from "express";
import { injectable } from "tsyringe";
import { GeneralController } from "./generalController.js";

@injectable()
export class GeneralRoutes {
  public router: Router;

  constructor(private generalController: GeneralController) {
    this.router = Router();
    this.initializeRoutes();
  }

  private initializeRoutes(): void {
    this.router.get("/provinces", this.generalController.getProvinces);
    this.router.get(
      "/provinces/:provinceId/wards",
      this.generalController.getWardsByProvince,
    );
  }
}

export default GeneralRoutes;
