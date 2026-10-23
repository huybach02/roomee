import { injectable } from "tsyringe";
import { Job } from "bullmq";
import { BaseWorker } from "../baseWorker.js";
import { MAIL_QUEUE_NAME, MailJobName } from "./mailQueue.js";
import { MailService } from "../../modules/mail/mailService.js";
import { SendOtpEmailParams } from "../../modules/mail/mailTypes.js";

@injectable()
export class MailWorker extends BaseWorker<SendOtpEmailParams, { success: boolean }> {
  constructor(private mailService: MailService) {
    super(MAIL_QUEUE_NAME, 5);
  }

  /**
   * Xử lý từng job gửi email trong hàng đợi
   */
  protected async handleJob(
    job: Job<SendOtpEmailParams>,
  ): Promise<{ success: boolean }> {
    if (job.name === MailJobName.SEND_OTP) {
      const data = job.data;
      const success = await this.mailService.sendOtpEmail(data);
      if (!success) {
        throw new Error(`Failed to send OTP email to ${data.to}`);
      }
      return { success: true };
    }

    return { success: false };
  }
}
