import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { container } from "tsyringe";
import { CacheService } from "../services/cacheService.js";
import { CustomResponse } from "../utils/customResponse.js";
import { JWT_ALLOWED_ALGORITHMS } from "../utils/constanst.js";
import { RequestContext } from "../utils/requestContext.js";

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    CustomResponse.error(res, t("common.unauthorized"), null, 401);
    return;
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    CustomResponse.error(res, t("common.unauthorized"), null, 401);
    return;
  }

  try {
    const cacheService = container.resolve(CacheService);

    // 1. Xác thực tính hợp lệ của token
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error("JWT_SECRET environment variable is missing.");
    }

    const decoded = jwt.verify(token, jwtSecret, {
      algorithms: JWT_ALLOWED_ALGORITHMS,
    }) as unknown as {
      sub: string;
      email: string;
      role: string;
      sid?: string;
      exp?: number;
      [key: string]: any;
    };

    // 2. Kiểm tra xem session của token này có bị thu hồi tức thời không (ưu tiên Redis, fallback DB)
    if (decoded.sid) {
      const isSessionBlacklisted = await cacheService.get(
        `blacklist:session:${decoded.sid}`,
      );
      if (isSessionBlacklisted) {
        CustomResponse.error(res, t("common.unauthorized"), null, 401);
        return;
      }
    }

    req.user = decoded;
    req.token = token;

    // Thiết lập ngữ cảnh người dùng hiện tại vào RequestContext
    const userId = decoded.sub;
    const store = RequestContext.getStore();
    if (store) {
      store.userId = userId;
      store.role = decoded.role;
      next();
    } else {
      RequestContext.run({ userId, role: decoded.role }, () => {
        next();
      });
    }
  } catch (error) {
    CustomResponse.error(res, t("common.unauthorized"), null, 401);
  }
};
