import { container } from "tsyringe";
import { MailWorker } from "./mail/mailWorker.js";
import { MailQueue } from "./mail/mailQueue.js";

/**
 * Khởi động toàn bộ Worker xử lý hàng đợi trong hệ thống
 */
export function startQueueWorkers(): void {
  const mailWorker = container.resolve(MailWorker);
  mailWorker.start();
  console.log("🚀 All Queue Workers started.");
}

/**
 * Dừng toàn bộ Worker xử lý hàng đợi một cách an toàn
 */
export async function stopQueueWorkers(): Promise<void> {
  const mailWorker = container.resolve(MailWorker);
  await mailWorker.stop();
  console.log("🛑 All Queue Workers stopped gracefully.");
}

/**
 * Đóng kết nối toàn bộ các Queue
 */
export async function closeAllQueues(): Promise<void> {
  try {
    const mailQueue = container.resolve(MailQueue);
    await mailQueue.close();
    console.log("🛑 All Queues closed.");
  } catch (err) {
    console.warn("[Queue] Error closing MailQueue:", err);
  }
}
