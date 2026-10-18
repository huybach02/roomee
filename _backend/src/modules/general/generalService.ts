import { injectable } from "tsyringe";
import { Province } from "../../entities/province.js";
import { Ward } from "../../entities/ward.js";
import { ProvinceRepository } from "../../repositories/provinceRepository.js";
import { WardRepository } from "../../repositories/wardRepository.js";

@injectable()
export class GeneralService {
  constructor(
    private provinceRepository: ProvinceRepository,
    private wardRepository: WardRepository,
  ) {}

  public async getProvinces(): Promise<Province[]> {
    return this.provinceRepository.find({
      order: { fullName: "ASC" },
    });
  }

  public async getWardsByProvince(provinceId: number): Promise<Ward[]> {
    return this.wardRepository.find({
      where: { provinceId },
      order: { fullName: "ASC" },
    });
  }
}
