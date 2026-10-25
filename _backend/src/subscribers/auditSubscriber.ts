import {
  EventSubscriber,
  EntitySubscriberInterface,
  InsertEvent,
  UpdateEvent,
  SoftRemoveEvent,
} from "typeorm";
import { RequestContext } from "../utils/requestContext.js";

/**
 * TypeORM Subscriber tự động gán thông tin Audit Trail (createdBy, updatedBy, deletedBy)
 * dựa trên ID của người dùng đang đăng nhập lấy từ RequestContext (AsyncLocalStorage).
 */
@EventSubscriber()
export class AuditSubscriber implements EntitySubscriberInterface {
  /**
   * Kích hoạt trước khi một Entity được INSERT vào database qua repository.save()
   */
  beforeInsert(event: InsertEvent<any>): void {
    const userId = RequestContext.getUserId();
    if (userId && event.entity) {
      if ("createdBy" in event.entity && event.entity.createdBy == null) {
        event.entity.createdBy = userId;
      }
      if ("updatedBy" in event.entity && event.entity.updatedBy == null) {
        event.entity.updatedBy = userId;
      }
    }
  }

  /**
   * Kích hoạt trước khi một Entity được UPDATE vào database qua repository.save()
   */
  beforeUpdate(event: UpdateEvent<any>): void {
    const userId = RequestContext.getUserId();
    if (userId && event.entity) {
      if ("updatedBy" in event.entity) {
        event.entity.updatedBy = userId;
      }
    }
  }

  /**
   * Kích hoạt trước khi một Entity được SOFT REMOVE khỏi database qua repository.softRemove()
   */
  beforeSoftRemove(event: SoftRemoveEvent<any>): void {
    const userId = RequestContext.getUserId();
    if (userId && event.entity) {
      if ("deletedBy" in event.entity) {
        event.entity.deletedBy = userId;
      }
    }
  }
}
