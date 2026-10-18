import { SupportedLocale } from "../../utils/i18n.js";

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
}

export interface SendOtpEmailParams {
  to: string;
  otp: string;
  fullName?: string | null;
  expiresInMinutes?: number;
  locale?: SupportedLocale;
}
