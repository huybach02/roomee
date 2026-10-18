import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import { Ward } from "../entities/ward.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class WardRepository extends Repository<Ward> {
  constructor() {
    super(Ward, AppDataSource.manager);
  }
}
