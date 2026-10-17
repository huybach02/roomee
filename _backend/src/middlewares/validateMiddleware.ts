import { NextFunction, Request, Response } from "express";
import { ZodType } from "zod";
import { CustomResponse } from "../utils/customResponse.js";

export function validate(schema: ZodType) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      const errors = result.error.issues.map((issue) => ({
        field: issue.path.join(".") || "body",
        message: issue.message,
      }));
      return CustomResponse.error(res, "Validation failed", errors, 400);
    }

    req.body = result.data;
    next();
  };
}
