import { SupportedLocale } from "../utils/i18n.js";

declare global {
  namespace Express {
    interface Request {
      locale: SupportedLocale;
      t: (key: string, params?: Record<string, string | number>) => string;
    }
  }

  /**
   * Hàm dịch ngôn ngữ toàn cục: tự động nhận diện ngôn ngữ của request hiện tại
   * Gọi trực tiếp ở bất kỳ tầng nào (Controller, Service, Repository, Validator, Helper...)
   */
  function t(
    key: string,
    params?: Record<string, string | number>,
    explicitLocale?: SupportedLocale,
  ): string;
}

export {};
