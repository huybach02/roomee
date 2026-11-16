import { injectable } from "tsyringe";
import { Province } from "../../entities/province.js";
import { Ward } from "../../entities/ward.js";
import { ProvinceRepository } from "../../repositories/provinceRepository.js";
import { WardRepository } from "../../repositories/wardRepository.js";
import { AppDataSource } from "../../config/data-source.js";
import { AppError } from "../../utils/appError.js";
import { UserRole } from "../../utils/constanst.js";
import { t } from "../../utils/i18n.js";
import type { SyncableService } from "../../utils/syncableService.js";
import { SyncRegistry } from "./syncRegistry.js";
import type {
  SyncItemDto,
  SyncModuleResult,
  SyncRejectedMutation,
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
    const rejectedMutations: SyncRejectedMutation[] = [];
    const failedCreateEntityIds = new Set<string>();
    const appliedEntityIds = new Set<string>();

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
            const data = this.parseMutationData(handler, "create", {
              ...(mutation.data || {}),
              id: mutation.entityId,
            });
            await handler.create(userId, data);
            appliedMutationIds.push(mutation.id);
            appliedEntityIds.add(mutation.entityId);
          } else if (mutation.action === "update" && handler.update) {
            const data = this.parseMutationData(
              handler,
              "update",
              mutation.data || {},
            );
            await handler.update(
              mutation.entityId,
              userId,
              userRole || UserRole.LANDLORD,
              data,
            );
            appliedMutationIds.push(mutation.id);
            appliedEntityIds.add(mutation.entityId);
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
            if (err?.code === "23505") {
              appliedEntityIds.add(mutation.entityId);
            }
          } else {
            if (mutation.action === "create") {
              failedCreateEntityIds.add(mutation.entityId);
            }
            const statusCode =
              err?.statusCode || (err instanceof AppError ? err.statusCode : 500);
            rejectedMutations.push({
              id: mutation.id,
              module: mutation.module,
              action: mutation.action,
              entityId: mutation.entityId,
              statusCode: typeof statusCode === "number" ? statusCode : 500,
              reason: err?.message || "Failed to apply mutation",
              details: err?.errors || null,
            });
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
          // Bảo vệ dữ liệu offline: Nếu id này thuộc về một phiếu create vừa bị từ chối ở Pha 1,
          // không đưa vào needDelete để tránh máy khách xóa mất bản ghi cục bộ
          if (failedCreateEntityIds.has(localItem.id)) {
            continue;
          }
          needDelete.push(localItem.id);
        } else {
          // Nếu bản ghi vừa có phiếu create/update được áp dụng thành công ở Pha 1:
          // Luôn trả về bản mới nhất từ database bất kể giờ client gửi lên là bao nhiêu,
          // để máy khách nhận được dữ liệu chuẩn xác của máy chủ (bao gồm updatedAt chuẩn của máy chủ).
          if (appliedEntityIds.has(localItem.id)) {
            needUpdate.push(serverRecord);
            continue;
          }

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
      rejectedMutations,
      entities: entitiesResult,
    };
  }

  /**
   * Validate dữ liệu mutation bằng schema khai báo trên service sync.
   * Fail-closed: service có handler mà thiếu schema thì từ chối phiếu.
   */
  private parseMutationData(
    handler: SyncableService<any>,
    action: "create" | "update",
    data: Record<string, unknown>,
  ): any {
    const schema =
      action === "create" ? handler.createSchema : handler.updateSchema;

    if (!schema) {
      throw AppError.badRequest(
        `Sync module "${handler.syncModuleName}" does not accept ${action} mutations.`,
      );
    }

    const parsed = schema.safeParse(data);
    if (!parsed.success) {
      throw AppError.badRequest(
        t("validation.failed"),
        parsed.error.issues.map((issue) => ({
          field: issue.path.join(".") || "data",
          message: issue.message,
        })),
      );
    }

    return parsed.data;
  }
}


