import "reflect-metadata";
import "dotenv/config";
import { AppDataSource } from "../config/data-source.js";
import { PersistRedisRepository } from "../repositories/persistRedisRepository.js";

async function main(): Promise<void> {
  const startTime = Date.now();
  console.log("🧹 [CleanExpiredRedis] Đang kết nối database...");

  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }
  console.log("✅ Kết nối database thành công!");

  try {
    const repository = new PersistRedisRepository();
    const affected = await repository.cleanExpiredRecords();

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(
      `✨ [CleanExpiredRedis] Đã dọn dẹp thành công ${affected} record hết hạn trong ${duration}s.`,
    );
  } catch (error) {
    console.error("❌ [CleanExpiredRedis] Lỗi khi dọn dẹp cache hết hạn:", error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

main().catch((err) => {
  console.error("Unhandled error:", err);
  process.exit(1);
});
