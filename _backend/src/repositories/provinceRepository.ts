import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import { Province } from "../entities/province.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class ProvinceRepository extends Repository<Province> {
  constructor() {
    super(Province, AppDataSource.manager);
  }
}
