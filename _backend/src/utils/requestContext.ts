import { AsyncLocalStorage } from "node:async_hooks";

export interface RequestStore {
  userId?: number | null;
  role?: string | null;
  [key: string]: any;
}

export const requestContextStorage = new AsyncLocalStorage<RequestStore>();

export class RequestContext {
  /**
   * Lấy toàn bộ store của request hiện tại
   */
  static getStore(): RequestStore | undefined {
    return requestContextStorage.getStore();
  }

  /**
   * Lấy ID của user hiện tại đang đăng nhập. Trả về null nếu chưa đăng nhập hoặc chạy ngoài request.
   */
  static getUserId(): number | null {
    return requestContextStorage.getStore()?.userId ?? null;
  }

  /**
   * Lấy Role của user hiện tại đang đăng nhập.
   */
  static getRole(): string | null {
    return requestContextStorage.getStore()?.role ?? null;
  }

  /**
   * Cập nhật ID user vào store của request hiện tại
   */
  static setUserId(userId: number | null): void {
    const store = requestContextStorage.getStore();
    if (store) {
      store.userId = userId;
    }
  }

  /**
   * Chạy một callback trong ngữ cảnh RequestStore xác định (hữu ích cho cronjob/worker/seeder)
   */
  static run<T>(store: RequestStore, callback: () => T): T {
    return requestContextStorage.run(store, callback);
  }
}
