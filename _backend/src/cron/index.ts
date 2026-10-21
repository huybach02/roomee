import {
  initCleanExpiredRedisCron,
  stopCleanExpiredRedisCron,
} from "./cleanExpiredRedisCron.js";

/**
 * Khởi động toàn bộ các cronjob của hệ thống
 */
export function startCronJobs(): void {
  initCleanExpiredRedisCron();
}

/**
 * Dừng toàn bộ các cronjob khi server tắt
 */
export function stopCronJobs(): void {
  stopCleanExpiredRedisCron();
}
