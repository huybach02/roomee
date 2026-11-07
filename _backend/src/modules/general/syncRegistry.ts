import { singleton, container } from "tsyringe";
import type { SyncableService } from "../../utils/syncableService.js";

type Constructor<T = any> = new (...args: any[]) => T;

const syncableClasses: Constructor<SyncableService<any>>[] = [];

/**
 * Decorator đánh dấu service có hỗ trợ sync.
 * Khi gắn @syncable(), service sẽ tự động được ghi nhận và resolve bởi SyncRegistry mà không cần đăng ký thủ công.
 */
export function syncable() {
  return function <T extends Constructor<SyncableService<any>>>(target: T): T {
    syncableClasses.push(target);
    return target;
  };
}

@singleton()
export class SyncRegistry {
  private services = new Map<string, SyncableService<any>>();
  private initialized = false;

  private ensureInitialized(): void {
    if (this.initialized) return;
    this.initialized = true;

    for (const serviceClass of syncableClasses) {
      try {
        const instance = container.resolve<SyncableService<any>>(serviceClass);
        if (instance && instance.syncModuleName) {
          this.register(instance);
        }
      } catch (err) {
        console.error(
          `[SyncRegistry] Failed to resolve syncable service ${serviceClass.name}:`,
          err,
        );
      }
    }
  }

  public register(service: SyncableService<any>): void {
    if (!service.syncModuleName) return;
    this.services.set(service.syncModuleName, service);
  }

  public get(moduleName: string): SyncableService<any> | undefined {
    this.ensureInitialized();
    return this.services.get(moduleName);
  }
}
