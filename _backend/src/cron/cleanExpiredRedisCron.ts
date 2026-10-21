import cron, { type ScheduledTask } from "node-cron";
import { container } from "tsyringe";
import { PersistRedisRepository } from "../repositories/persistRedisRepository.js";

/**
 * Lịch chạy cronjob dọn dẹp các record hết hạn trong persist_redis.
 * Mặc định: Mỗi ngày 1 lần vào lúc 00:00 ("0 0 * * *").
 * Có thể tùy chỉnh qua biến môi trường CLEAN_PERSIST_REDIS_CRON.
 */
const CRON_SCHEDULE = process.env.CLEAN_PERSIST_REDIS_CRON || "0 0 * * *";

let task: ScheduledTask | null = null;

export function initCleanExpiredRedisCron(): ScheduledTask {
  if (task) return task;

  task = cron.schedule(
    CRON_SCHEDULE,
    async () => {
      const startTime = Date.now();
      console.log("⏰ [Cron:CleanExpiredRedis] Bắt đầu quét và xóa cache hết hạn...");

      try {
        const repository = container.resolve(PersistRedisRepository);
        const deletedCount = await repository.cleanExpiredRecords();
        const duration = ((Date.now() - startTime) / 1000).toFixed(2);

        console.log(
          `✅ [Cron:CleanExpiredRedis] Đã xóa ${deletedCount} record hết hạn (${duration}s).`,
        );
      } catch (error) {
        console.error("❌ [Cron:CleanExpiredRedis] Lỗi khi thực thi:", error);
      }
    },
    {
      name: "clean-expired-redis",
      noOverlap: true,
    },
  );

  console.log(
    `🕒 [Cron] Đã đăng ký cronjob CleanExpiredRedis với lịch trình: "${CRON_SCHEDULE}"`,
  );

  return task;
}

export function stopCleanExpiredRedisCron(): void {
  if (task) {
    task.stop();
    task = null;
    console.log("🛑 [Cron] Đã dừng cronjob CleanExpiredRedis.");
  }
}
