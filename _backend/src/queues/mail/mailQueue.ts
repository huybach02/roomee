import { injectable } from "tsyringe";
import { BaseQueue } from "../baseQueue.js";
import { SendOtpEmailParams } from "../../modules/mail/mailTypes.js";

export const MAIL_QUEUE_NAME = "mail-queue";

export enum MailJobName {
  SEND_OTP = "send-otp",
}

@injectable()
export class MailQueue extends BaseQueue<SendOtpEmailParams> {
  constructor() {
    super(MAIL_QUEUE_NAME);
  }

  /**
   * Đẩy job gửi mã OTP vào hàng đợi xử lý nền
   */
  public async addSendOtpJob(params: SendOtpEmailParams): Promise<void> {
    await this.addJob(MailJobName.SEND_OTP, params);
  }
}
