import { injectable } from "tsyringe";
import { In, Repository } from "typeorm";
import { PersistRedis } from "../entities/persistRedis.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class PersistRedisRepository extends Repository<PersistRedis> {
  constructor() {
    super(PersistRedis, AppDataSource.manager);
  }

  /**
   * Lưu hoặc cập nhật key-value cùng với TTL vào database.
   * Hỗ trợ options.preserveTtl (tương đương KEEPTTL trong Redis):
   * - Nếu preserveTtl = true: Chỉ cập nhật value, giữ nguyên expiredAt và ttl cũ nếu key đã tồn tại.
   * - Nếu preserveTtl = false / undefined: Cập nhật cả value, ttl và tính lại expiredAt mới.
   */
  public async setKey(
    key: string,
    value: any,
    ttlSeconds?: number,
    options?: { preserveTtl?: boolean },
  ): Promise<void> {
    const expiredAt = ttlSeconds
      ? new Date(Date.now() + ttlSeconds * 1000)
      : null;

    const updateColumns = options?.preserveTtl
      ? ["value"]
      : ["value", "ttl", "expiredAt"];

    await this.createQueryBuilder()
      .insert()
      .into(PersistRedis)
      .values({
        key,
        value: value as any,
        ttl: ttlSeconds ?? null,
        expiredAt,
      } as any)
      .orUpdate(updateColumns, ["key"])
      .execute();
  }

  /**
   * Lấy dữ liệu theo key nếu còn hạn.
   * Nếu đã quá hạn, thực hiện lazy delete và trả về null.
   */
  public async getValidKey(key: string): Promise<PersistRedis | null> {
    const record = await this.findOne({ where: { key } });
    if (!record) return null;

    if (record.expiredAt && record.expiredAt.getTime() <= Date.now()) {
      // Lazy delete chạy ngầm không cần chờ
      this.delete({ key }).catch(() => {});
      return null;
    }

    return record;
  }

  /**
   * Xóa một hoặc nhiều key khỏi database
   */
  public async deleteKeys(keys: string | string[]): Promise<void> {
    const keyList = Array.isArray(keys) ? keys : [keys];
    const filteredKeys = keyList.filter((k) => Boolean(k && k.trim()));
    if (filteredKeys.length === 0) return;

    if (filteredKeys.length === 1) {
      await this.delete({ key: filteredKeys[0] });
    } else {
      await this.delete({ key: In(filteredKeys) });
    }
  }

  /**
   * Xóa tất cả các record đã hết hạn (dùng cho cronjob)
   */
  public async cleanExpiredRecords(): Promise<number> {
    const result = await this.createQueryBuilder()
      .delete()
      .from(PersistRedis)
      .where('"expiredAt" IS NOT NULL AND "expiredAt" <= :now', {
        now: new Date(),
      })
      .execute();

    return result.affected ?? 0;
  }
}
