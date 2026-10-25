import { NextFunction, Request, Response } from "express";
import { RequestContext, RequestStore } from "../utils/requestContext.js";

/**
 * Middleware khởi tạo RequestContext cho mỗi HTTP request bằng AsyncLocalStorage.
 * Đảm bảo các hàm truy vấn DB / Service có thể lấy được context người dùng mà không cần truyền tay.
 */
export function requestContextMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const store: RequestStore = {
    userId: null,
    role: null,
  };

  RequestContext.run(store, () => {
    next();
  });
}
