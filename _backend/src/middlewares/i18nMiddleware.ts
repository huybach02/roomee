import { NextFunction, Request, Response } from "express";
import { getLocaleFromRequest, localeStorage, t } from "../utils/i18n.js";

export function i18nMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const locale = getLocaleFromRequest(req);
  req.locale = locale;
  req.t = (key: string, params?: Record<string, string | number>) =>
    t(key, params, locale);

  // Đính kèm Content-Language vào response để client nhận biết
  res.setHeader("Content-Language", locale);

  // Chạy toàn bộ request trong AsyncLocalStorage context để hàm t() global tự nhận diện locale
  localeStorage.run({ locale }, () => {
    next();
  });
}
