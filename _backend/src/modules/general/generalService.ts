import { injectable } from "tsyringe";
import { Province } from "../../entities/province.js";
import { Ward } from "../../entities/ward.js";
import { ProvinceRepository } from "../../repositories/provinceRepository.js";
import { WardRepository } from "../../repositories/wardRepository.js";
import { AppDataSource } from "../../config/data-source.js";
import { UserRole } from "../../utils/constanst.js";
import { SyncRegistry } from "./syncRegistry.js";
import type {
  SyncItemDto,
  SyncModuleResult,
  SyncRequestDto,
  SyncResponseData,
} from "./generalSchema.js";

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
    request: SyncRequestDto,
    userId?: string,
    userRole?: string,
  ): Promise<SyncResponseData> {
    const appliedMutationIds: string[] = [];

    // 1. Áp dụng các mutations đẩy từ Mobile lên (Push phase)
    if (
      userId &&
      Array.isArray(request.mutations) &&
      request.mutations.length > 0
    ) {
      for (const mutation of request.mutations) {
        const handler = this.syncRegistry.get(mutation.module);
        if (!handler) {
          continue;
        }

        try {
          if (mutation.action === "create" && handler.create) {
            await handler.create(userId, {
              ...(mutation.data || {}),
              id: mutation.entityId,
            });
            appliedMutationIds.push(mutation.id);
          } else if (mutation.action === "update" && handler.update) {
            await handler.update(
              mutation.entityId,
              userId,
              userRole || UserRole.LANDLORD,
              mutation.data || {},
            );
            appliedMutationIds.push(mutation.id);
          } else if (mutation.action === "delete" && handler.delete) {
            await handler.delete(mutation.entityId, userId);
            appliedMutationIds.push(mutation.id);
          }
        } catch (err: any) {
          // Nếu tạo mới bị trùng ID (do client retry mutation đã thành công ở lần trước)
          // hoặc record update/delete đã không còn tồn tại:
          // Vẫn ghi nhận appliedMutationIds để dọn dẹp hàng đợi phía client
          if (err?.code === "23505" || err?.statusCode === 404) {
            appliedMutationIds.push(mutation.id);
          } else {
            console.error(
              `[GeneralService.sync] Failed to apply mutation ${mutation.id} (${mutation.module}.${mutation.action}):`,
              err?.message || err,
            );
          }
        }
      }
    }

    // 2. Đối soát dữ liệu (Pull / Reconcile phase)
    const entitiesResult: Record<string, SyncModuleResult> = {};
    const entities = request.entities || {};

    for (const [moduleKey, items] of Object.entries(entities)) {
      const handler = this.syncRegistry.get(moduleKey);
      if (!handler || !Array.isArray(items) || items.length === 0) {
        entitiesResult[moduleKey] = { needUpdate: [], needDelete: [] };
        continue;
      }

      const localIds = items.map((i) => i.id).filter((id) => Boolean(id));
      if (localIds.length === 0) {
        entitiesResult[moduleKey] = { needUpdate: [], needDelete: [] };
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

      entitiesResult[moduleKey] = { needUpdate, needDelete };
    }

    return {
      appliedMutationIds,
      entities: entitiesResult,
    };
  }
}


