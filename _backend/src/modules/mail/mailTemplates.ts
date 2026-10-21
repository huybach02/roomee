import {
  t,
  SupportedLocale,
  localeStorage,
  DEFAULT_LOCALE,
} from "../../utils/i18n.js";

export interface OtpTemplateData {
  otp: string;
  fullName: string;
  expiresInMinutes: number;
  locale?: SupportedLocale;
}

export function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

export function renderOtpEmailTemplate(data: OtpTemplateData): string {
  const currentLocale =
    data.locale || localeStorage.getStore()?.locale || DEFAULT_LOCALE;

  const safeFullName = escapeHtml(data.fullName || "");
  const safeOtp = escapeHtml(data.otp || "");

  const title = t("mail.verifyOtpSubject", undefined, currentLocale);
  const tagline = t("mail.tagline", undefined, currentLocale);
  const greeting = t("mail.greeting", { name: safeFullName }, currentLocale);
  const intro = t("mail.otpVerifyIntro", undefined, currentLocale);
  const otpLabel = t("mail.otpLabel", undefined, currentLocale);
  const expireNote = t(
    "mail.otpExpireNote",
    { minutes: String(data.expiresInMinutes) },
    currentLocale,
  );
  const footerNote = t("mail.footerNote", undefined, currentLocale);
  const copyright = t("mail.copyright", undefined, currentLocale);

  return `
<!DOCTYPE html>
<html lang="${currentLocale}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f4f6f9;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #333333;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      width: 100%;
      background-color: #f4f6f9;
      padding: 40px 10px;
    }
    .container {
      max-width: 540px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
      border: 1px solid #e9ecef;
    }
    .header {
      background-color: #092E5D;
      padding: 28px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      color: #ffffff;
      font-size: 26px;
      font-weight: 700;
      letter-spacing: 1px;
    }
    .header span {
      color: #ED6B25;
    }
    .header p {
      margin: 6px 0 0 0;
      color: #cbd5e1;
      font-size: 13px;
    }
    .content {
      padding: 32px 28px;
    }
    .greeting {
      font-size: 16px;
      font-weight: 600;
      color: #1e293b;
      margin-bottom: 12px;
    }
    .text {
      font-size: 14px;
      line-height: 1.6;
      color: #475569;
      margin-bottom: 24px;
    }
    .otp-box {
      background: #f8fafc;
      border: 2px dashed #092E5D;
      border-radius: 10px;
      padding: 20px;
      text-align: center;
      margin: 28px 0;
    }
    .otp-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1.5px;
      color: #64748b;
      margin-bottom: 8px;
      font-weight: 600;
    }
    .otp-code {
      font-size: 36px;
      font-weight: 800;
      letter-spacing: 8px;
      color: #ED6B25;
      font-family: 'Courier New', Courier, monospace;
      margin: 0;
    }
    .notice {
      font-size: 13px;
      line-height: 1.5;
      color: #64748b;
      background-color: #fff7ed;
      border-left: 4px solid #ED6B25;
      padding: 12px 14px;
      border-radius: 4px;
      margin-bottom: 24px;
    }
    .footer {
      background-color: #f8fafc;
      border-top: 1px solid #e2e8f0;
      padding: 20px 24px;
      text-align: center;
      font-size: 12px;
      color: #94a3b8;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <div class="header">
        <h1>Roomee</h1>
        <p>${tagline}</p>
      </div>
      <div class="content">
        <div class="greeting">${greeting}</div>
        <div class="text">${intro}</div>
        <div class="otp-box">
          <div class="otp-label">${otpLabel}</div>
          <div class="otp-code">${safeOtp}</div>
        </div>
        <div class="notice">
          ⏱️ ${expireNote}
        </div>
        <div class="text" style="font-size: 12px; color: #94a3b8; margin-bottom: 0;">
          ${footerNote}
        </div>
      </div>
      <div class="footer">
        © ${new Date().getFullYear()} Roomee. ${copyright}
      </div>
    </div>
  </div>
</body>
</html>
  `.trim();
}
