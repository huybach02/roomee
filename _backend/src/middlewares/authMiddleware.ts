import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { container } from "tsyringe";
import { CacheService } from "../services/cacheService.js";
import { CustomResponse } from "../utils/customResponse.js";

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

    // 1. Kiểm tra xem token có nằm trong blacklist không (ưu tiên Redis, fallback DB)
    const isBlacklisted = await cacheService.get(`blacklist:token:${token}`);
    if (isBlacklisted) {
      CustomResponse.error(res, t("common.unauthorized"), null, 401);
      return;
    }

    // 2. Xác thực tính hợp lệ của token
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error("JWT_SECRET environment variable is missing.");
    }

    const decoded = jwt.verify(token, jwtSecret) as unknown as {
      sub: number;
      email: string;
      role: string;
      sid?: string;
      exp?: number;
      [key: string]: any;
    };

    // 3. Kiểm tra xem session của token này có bị thu hồi tức thời không (ưu tiên Redis, fallback DB)
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
    next();
  } catch (error) {
    CustomResponse.error(res, t("common.unauthorized"), null, 401);
  }
};
