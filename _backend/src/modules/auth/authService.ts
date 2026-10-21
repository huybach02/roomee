import { injectable } from "tsyringe";
import { User } from "../../entities/user.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { RegisterDto } from "./authSchema.js";
import argon2 from "argon2";
import {
  CODE_RESPONSE,
  Gender,
  OTP_EXPIRES_IN_MINUTES,
  TTL_OTP_SECONDS,
  UserRole,
} from "../../utils/constanst.js";
import { MailService } from "../mail/mailService.js";
import { OtpService } from "./otpService.js";
import { redis } from "../../config/redis.js";

@injectable()
export class AuthService {
  private readonly jwtSecret: string;

  constructor(
    private userRepository: UserRepository,
    private mailService: MailService,
    private otpService: OtpService,
  ) {
    if (!process.env.JWT_SECRET) {
      throw new Error("JWT_SECRET environment variable is missing.");
    }
    this.jwtSecret = process.env.JWT_SECRET;
  }

  public async register(
    dtoData: RegisterDto,
  ): Promise<{ user: User; code: string }> {
    // Check if the email already exists
    const existingUser = await this.userRepository.findOneBy({
      email: dtoData.email,
    });
    if (existingUser) {
      throw new Error(t("auth.emailAlreadyExists"));
    }

    const hashedPassword = await argon2.hash(dtoData.password);
    const user = this.userRepository.create({
      email: dtoData.email,
      password: hashedPassword,
      fullName: dtoData.fullName || null,
      phoneNumber: dtoData.phoneNumber || null,
      avatarUrl: dtoData.avatarUrl || null,
      bio: dtoData.bio || null,
      birthday: dtoData.birthday || null,
      gender: dtoData.gender || Gender.MALE,
      role: dtoData.role || UserRole.TENANT,
      isEmailVerified: false,
      isActive: true,
      provinceId: dtoData.provinceId || null,
      wardId: dtoData.wardId || null,
    });

    const savedUser = await this.userRepository.save(user);

    // Tạo mã OTP 6 số và lưu vào Redis (hết hạn sau 10 phút)
    const otp = await this.otpService.generateAndSaveOtp(
      savedUser.email,
      "register",
      TTL_OTP_SECONDS,
    );

    // Gửi email chứa mã OTP xác thực
    const isSent = await this.mailService.sendOtpEmail({
      to: savedUser.email,
      otp,
      fullName: savedUser.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
    });

    if (!isSent) {
      throw new Error(t("mail.sendFailed"));
    }

    // Đặt cooldown 60s cho resend OTP
    await redis.set(
      `otp:cooldown:${savedUser.email.trim().toLowerCase()}`,
      "1",
      "EX",
      60,
    );

    const { password: _, ...userWithoutPassword } = savedUser;

    return {
      user: userWithoutPassword as User,
      code: CODE_RESPONSE.NEED_VERIFY_EMAIL,
    };
  }

  public async resendOtp(email: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const cooldownKey = `otp:cooldown:${normalizedEmail}`;

    // 1. Kiểm tra cooldown server-side (60 giây)
    const canSend = await redis.set(cooldownKey, "1", "EX", 60, "NX");
    if (!canSend) {
      throw new Error(t("auth.otpCooldown"));
    }

    // 2. Kiểm tra tài khoản tồn tại và chưa xác thực
    const user = await this.userRepository.findOneBy({ email: normalizedEmail });
    if (!user || user.isEmailVerified) {
      // Kết thúc thành công giả định để tránh user enumeration và spam email
      return;
    }

    // 3. Tạo mã OTP 6 số và lưu vào Redis (hết hạn sau 10 phút)
    const otp = await this.otpService.generateAndSaveOtp(
      normalizedEmail,
      "register",
      TTL_OTP_SECONDS,
    );

    // 4. Gửi email chứa mã OTP xác thực
    const isSent = await this.mailService.sendOtpEmail({
      to: normalizedEmail,
      otp,
      fullName: user.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
    });

    if (!isSent) {
      // Xóa cooldown nếu gửi mail thất bại để người dùng có thể gửi lại
      await redis.del(cooldownKey);
      throw new Error(t("mail.sendFailed"));
    }
  }

  public async verifyOtp(email: string, otp: string): Promise<void> {
    // Xác thực mã OTP
    const isOtpValid = await this.otpService.verifyOtp(email, otp, "register");
    if (!isOtpValid) {
      throw new Error(t("auth.invalidOtp"));
    }

    const user = await this.userRepository.findOneBy({ email });
    if (!user) {
      throw new Error(t("auth.userNotFound"));
    }

    user.isEmailVerified = true;
    await this.userRepository.save(user);
  }

  public async login(
    email: string,
    password: string,
  ): Promise<{ user: User; token: string }> {
    // const user = await this.userRepository.findOneBy({ email });
    // if (!user) {
    //   throw new AppError(404, "User not found");
    // }
    // const isPasswordValid = await bcrypt.compare(password, user.password);
    // if (!isPasswordValid) {
    //   throw new AppError(401, "Invalid password");
    // }
    // const token = jwt.sign({ id: user.id }, this.jwtSecret, {
    //   expiresIn: "1h",
    // });
    // return { user, token };
    return { user: {} as User, token: "dummy_token" }; // Placeholder implementation
  }
}
