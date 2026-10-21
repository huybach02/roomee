import { injectable } from "tsyringe";
import nodemailer, { type Transporter } from "nodemailer";
import { SendEmailOptions, SendOtpEmailParams } from "./mailTypes.js";
import { renderOtpEmailTemplate } from "./mailTemplates.js";
import { t } from "../../utils/i18n.js";
import { OTP_EXPIRES_IN_MINUTES } from "../../utils/constanst.js";

@injectable()
export class MailService {
  private transporter: Transporter | null = null;
  private fromEmail: string;

  constructor() {
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    const host = process.env.SMTP_HOST || "smtp.gmail.com";
    const port = Number(process.env.SMTP_PORT) || 465;
    const secure = process.env.SMTP_SECURE === "true" || port === 465;

    this.fromEmail =
      process.env.MAIL_FROM ||
      (user ? `Roomee <${user}>` : "Roomee <no-reply@roomee.vn>");

    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: {
          user,
          pass,
        },
      });
    }
  }

  /**
   * Gửi email qua Gmail SMTP (hoặc fallback in log console nếu chưa cấu hình tài khoản Gmail)
   */
  public async sendMail(
    options: SendEmailOptions,
  ): Promise<{ id?: string; success: boolean }> {
    const recipients = Array.isArray(options.to)
      ? options.to.join(", ")
      : options.to;

    if (!this.transporter) {
      if (process.env.NODE_ENV !== "production") {
        console.warn("[MailService] SMTP not configured. Skipped sending email in development.");
        return { success: true };
      }
      console.error("[MailService] SMTP not configured.");
      return { success: false };
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.fromEmail,
        to: options.to,
        subject: options.subject,
        html: options.html,
        text: options.text,
      });

      return { id: info.messageId, success: true };
    } catch (error) {
      console.error("Failed to send email via Gmail SMTP:", error);
      return { success: false };
    }
  }

  /**
   * Gửi email chứa mã OTP xác thực
   */
  public async sendOtpEmail(params: SendOtpEmailParams): Promise<boolean> {
    const {
      to,
      otp,
      fullName,
      expiresInMinutes = OTP_EXPIRES_IN_MINUTES,
      locale,
      subject: customSubject,
      intro: customIntro,
    } = params;

    // Trong môi trường dev, luôn in mã OTP ra console để dễ lấy mã và test
    if (process.env.NODE_ENV !== "production") {
      console.log(
        `\n🔑 [DEV OTP] Mã xác thực gửi tới ${to}: ${otp} (Hiệu lực: ${expiresInMinutes} phút)\n`,
      );
    }

    const subject =
      customSubject || t("mail.verifyOtpSubject", undefined, locale);
    const html = renderOtpEmailTemplate({
      otp,
      fullName: fullName || to,
      expiresInMinutes,
      locale,
      title: subject,
      intro: customIntro,
    });

    const result = await this.sendMail({
      to,
      subject,
      html,
      text: t(
        "mail.otpEmailText",
        { otp, minutes: String(expiresInMinutes) },
        locale,
      ),
    });

    return result.success;
  }
}
