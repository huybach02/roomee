import type { ObjectLiteral, SelectQueryBuilder, EntityTarget } from "typeorm";
import type { RelationJoin } from "./relationJoin.js";

export { syncable } from "../modules/general/syncRegistry.js";

export interface SyncableService<Entity extends ObjectLiteral>
  extends Partial<RelationJoin<Entity>> {
  /** Tên định danh chuẩn số nhiều của resource khi sync (ví dụ: "workspaces", "users", "rooms") */
  readonly syncModuleName: string;

  /** Entity TypeORM tương ứng */
  readonly syncEntity: EntityTarget<Entity>;

  /** Logic phân quyền/scope dữ liệu (tùy chọn) */
  syncScope?(
    qb: SelectQueryBuilder<Entity>,
    userId: string,
    userRole: string,
  ): void;

  /**
   * Phương thức join quan hệ con để load dữ liệu đầy đủ cho sync.
   * Thừa hưởng từ RelationJoin<Entity> (tùy chọn).
   */
  relationJoin?(
    queryBuilder: SelectQueryBuilder<Entity>,
  ): SelectQueryBuilder<Entity>;
}
