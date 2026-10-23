import { Queue, type JobsOptions } from "bullmq";
import { createRedisConnection } from "../config/redis.js";

/**
 * Lớp cơ sở trừu tượng cho mọi hàng đợi (Queue) trong hệ thống.
 * Tự động cấu hình connection Redis độc lập, retry exponential backoff và cơ chế dọn dẹp job.
 */
export abstract class BaseQueue<T = any, R = any> {
  protected queue: Queue<T, R>;
  public readonly name: string;

  constructor(name: string, defaultJobOptions?: JobsOptions) {
    this.name = name;
    const connection = createRedisConnection();

    this.queue = new Queue<T, R>(name, {
      connection,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: "exponential",
          delay: 2000,
        },
        removeOnComplete: {
          age: 3600, // Lưu job thành công trong 1 giờ để theo dõi
          count: 500,
        },
        removeOnFail: {
          age: 86400 * 7, // Lưu job thất bại trong 7 ngày để debug
        },
        ...defaultJobOptions,
      },
    });
  }

  /**
   * Đẩy một công việc (job) vào hàng đợi
   */
  public async addJob(
    jobName: string,
    data: T,
    opts?: JobsOptions,
  ): Promise<void> {
    await this.queue.add(jobName as any, data as any, opts);
  }

  /**
   * Đóng kết nối queue an toàn
   */
  public async close(): Promise<void> {
    await this.queue.close();
  }

  /**
   * Truy cập đối tượng BullMQ Queue gốc nếu cần thao tác nâng cao
   */
  public getRawQueue(): Queue<T, R> {
    return this.queue;
  }
}
