import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { redis } from "../config/redis.js";
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
    // 1. Kiểm tra xem token có nằm trong blacklist của Redis không
    const isBlacklisted = await redis.get(`blacklist:token:${token}`);
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

    // 3. Kiểm tra xem session của token này có bị thu hồi tức thời trong Redis không
    if (decoded.sid) {
      const isSessionBlacklisted = await redis.get(
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
