import { injectable } from "tsyringe";
import { Province } from "../../entities/province.js";
import { Ward } from "../../entities/ward.js";
import { ProvinceRepository } from "../../repositories/provinceRepository.js";
import { WardRepository } from "../../repositories/wardRepository.js";
import { AppDataSource } from "../../config/data-source.js";
import { UserRole } from "../../utils/constanst.js";
import { SyncRegistry } from "./syncRegistry.js";
import type { SyncItemDto, SyncModuleResult } from "./generalSchema.js";

@injectable()
export class GeneralService {
  constructor(
    private provinceRepository: ProvinceRepository,
    private wardRepository: WardRepository,
    private syncRegistry: SyncRegistry,
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

  public async sync(
    entities: Record<string, SyncItemDto[]>,
    userId?: string,
    userRole?: string,
  ): Promise<Record<string, SyncModuleResult>> {
    const result: Record<string, SyncModuleResult> = {};

    for (const [moduleKey, items] of Object.entries(entities)) {
      const handler = this.syncRegistry.get(moduleKey);
      if (!handler || !Array.isArray(items) || items.length === 0) {
        result[moduleKey] = { needUpdate: [], needDelete: [] };
        continue;
      }

      const localIds = items.map((i) => i.id).filter((id) => Boolean(id));
      if (localIds.length === 0) {
        result[moduleKey] = { needUpdate: [], needDelete: [] };
        continue;
      }

      const alias = handler.syncModuleName;
      const repo = AppDataSource.getRepository(handler.syncEntity);
      let qb = repo.createQueryBuilder(alias);

      if (handler.relationJoin) {
        qb = handler.relationJoin(qb);
      }

      if (handler.syncScope && userId) {
        handler.syncScope(qb, userId, userRole || UserRole.LANDLORD);
      }

      qb.andWhere(`${alias}.id IN (:...localIds)`, { localIds });

      const serverRecords = await qb.getMany();

      const serverMap = new Map<string, any>();
      for (const record of serverRecords) {
        if (record && record.id) {
          serverMap.set(record.id.toString(), record);
        }
      }

      const needDelete: string[] = [];
      const needUpdate: any[] = [];

      for (const localItem of items) {
        const serverRecord = serverMap.get(localItem.id);
        if (!serverRecord) {
          needDelete.push(localItem.id);
        } else {
          const serverTime = serverRecord.updatedAt
            ? new Date(serverRecord.updatedAt).getTime()
            : 0;
          const localTime = localItem.updatedAt
            ? new Date(localItem.updatedAt).getTime()
            : 0;

          if (serverTime > localTime) {
            needUpdate.push(serverRecord);
          }
        }
      }

      result[moduleKey] = { needUpdate, needDelete };
    }

    return result;
  }
}


