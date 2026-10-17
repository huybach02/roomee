import fs from "node:fs";
import { AsyncLocalStorage } from "node:async_hooks";
import { Request } from "express";

export type SupportedLocale = "vi" | "en";
export const DEFAULT_LOCALE: SupportedLocale = "vi";
export const SUPPORTED_LOCALES: SupportedLocale[] = ["vi", "en"];

// AsyncLocalStorage lưu trữ ngữ cảnh ngôn ngữ cho từng request bất đồng bộ
export const localeStorage = new AsyncLocalStorage<{ locale: SupportedLocale }>();

const dictionaries: Record<SupportedLocale, Record<string, any>> = {
  vi: {},
  en: {},
};

function loadDictionary(filename: string): Record<string, any> {
  const possibleUrls = [
    new URL(`../locales/${filename}`, import.meta.url),
    new URL(`../../src/locales/${filename}`, import.meta.url),
    new URL(`../src/locales/${filename}`, import.meta.url),
  ];

  for (const url of possibleUrls) {
    if (fs.existsSync(url)) {
      try {
        const content = fs.readFileSync(url, "utf-8");
        return JSON.parse(content);
      } catch (err) {
        console.error(`Error parsing ${filename} at ${url.pathname}:`, err);
      }
    }
  }

  console.warn(`Translation file ${filename} not found in any search path.`);
  return {};
}

dictionaries.vi = loadDictionary("vi.json");
dictionaries.en = loadDictionary("en.json");

/**
 * Chuẩn hóa chuỗi locale về 'vi' hoặc 'en'
 */
export function normalizeLocale(locale?: string | null): SupportedLocale {
  if (!locale) return DEFAULT_LOCALE;
  const clean = locale.toLowerCase().trim();
  if (clean.startsWith("en")) return "en";
  if (clean.startsWith("vi")) return "vi";
  return DEFAULT_LOCALE;
}

/**
 * Lấy locale từ HTTP Request (qua Header Accept-Language hoặc query param ?lang=)
 */
export function getLocaleFromRequest(req: Request): SupportedLocale {
  const queryLang = req.query?.lang as string | undefined;
  if (queryLang) {
    return normalizeLocale(queryLang);
  }

  const acceptLang = req.headers["accept-language"];
  if (acceptLang) {
    const primary = acceptLang.split(",")[0]?.trim();
    return normalizeLocale(primary);
  }

  return DEFAULT_LOCALE;
}

/**
 * Hàm dịch toàn cục: tự động nhận diện ngôn ngữ của request hiện tại qua AsyncLocalStorage.
 * Có thể gọi ở bất kỳ đâu (Controller, Service, Repository, Middleware, Error Handler).
 *
 * @param key Key dạng lồng nhau: 'auth.loginSuccess' hoặc 'common.notFound'
 * @param params Object chứa giá trị thay thế: { path: '/api/users' }
 * @param explicitLocale Ngôn ngữ cụ thể nếu muốn ghi đè (thường dùng trong background worker/cronjob)
 */
export function t(
  key: string,
  params?: Record<string, string | number>,
  explicitLocale?: SupportedLocale,
): string {
  const currentLocale =
    explicitLocale || localeStorage.getStore()?.locale || DEFAULT_LOCALE;

  const targetDict = dictionaries[currentLocale] || dictionaries[DEFAULT_LOCALE];
  const fallbackDict = dictionaries[DEFAULT_LOCALE];

  const resolve = (dict: Record<string, any>): string | null => {
    const segments = key.split(".");
    let current: any = dict;
    for (const segment of segments) {
      if (current && typeof current === "object" && segment in current) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return typeof current === "string" ? current : null;
  };

  let template = resolve(targetDict) ?? resolve(fallbackDict) ?? key;

  if (params) {
    for (const [paramKey, paramValue] of Object.entries(params)) {
      template = template.replaceAll(`{${paramKey}}`, String(paramValue));
    }
  }

  return template;
}

// Đăng ký t() vào globalThis để có thể gọi ở bất kỳ đâu mà không bắt buộc phải import
(globalThis as any).t = t;
