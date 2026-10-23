import { Worker, Job, type WorkerOptions } from "bullmq";
import { createRedisConnection } from "../config/redis.js";

/**
 * Lớp cơ sở trừu tượng cho mọi Worker xử lý tác vụ nền trong hệ thống.
 * Tự động cấu hình connection, concurrency, ghi log sự kiện (completed/failed/error) và vòng đời stop.
 */
export abstract class BaseWorker<T = any, R = any> {
  protected worker: Worker<T, R> | null = null;
  public readonly queueName: string;
  protected readonly concurrency: number;

  constructor(queueName: string, concurrency: number = 5) {
    this.queueName = queueName;
    this.concurrency = concurrency;
  }

  /**
   * Phương thức trừu tượng thực thi logic xử lý job. Các Worker con bắt buộc phải triển khai.
   */
  protected abstract handleJob(job: Job<T, R>): Promise<R>;

  /**
   * Khởi động Worker lắng nghe hàng đợi
   */
  public start(customOptions?: Partial<WorkerOptions>): Worker<T, R> {
    if (this.worker) return this.worker;

    const connection = createRedisConnection();

    this.worker = new Worker<T, R>(
      this.queueName,
      async (job: Job<T, R>) => this.handleJob(job),
      {
        connection,
        concurrency: this.concurrency,
        ...customOptions,
      },
    );

    this.worker.on("completed", (job) => {
      console.log(
        `[Worker:${this.queueName}] Job ${job.id} (${job.name}) completed successfully.`,
      );
    });

    this.worker.on("failed", (job, err) => {
      console.error(
        `[Worker:${this.queueName}] Job ${job?.id} (${job?.name}) failed (attempt ${job?.attemptsMade}):`,
        err.message,
      );
    });

    this.worker.on("error", (err) => {
      console.error(`[Worker:${this.queueName}] Connection error:`, err);
    });

    return this.worker;
  }

  /**
   * Dừng Worker an toàn (chờ xử lý xong các job dở dang)
   */
  public async stop(): Promise<void> {
    if (this.worker) {
      await this.worker.close();
      this.worker = null;
      console.log(`[Worker:${this.queueName}] Worker stopped gracefully.`);
    }
  }

  /**
   * Truy cập đối tượng BullMQ Worker gốc nếu cần thao tác nâng cao
   */
  public getRawWorker(): Worker<T, R> | null {
    return this.worker;
  }
}
