import { injectable } from "tsyringe";
import crypto from "node:crypto";
import { User } from "../../entities/user.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { RegisterDto } from "./authSchema.js";
import argon2 from "argon2";
import jwt from "jsonwebtoken";
import {
  CODE_RESPONSE,
  Gender,
  LOGIN_LOCKOUT_MINUTES,
  LOGIN_LOCKOUT_SECONDS,
  MAX_LOGIN_ATTEMPTS,
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

    // Kiểm tra cooldown server-side (60 giây)
    const canSend = await redis.set(cooldownKey, "1", "EX", 60, "NX");
    if (!canSend) {
      throw new Error(t("auth.otpCooldown"));
    }

    const user = await this.userRepository.findOneBy({
      email: normalizedEmail,
    });
    if (!user || user.isEmailVerified) {
      return;
    }

    const otp = await this.otpService.generateAndSaveOtp(
      normalizedEmail,
      "register",
      TTL_OTP_SECONDS,
    );

    const isSent = await this.mailService.sendOtpEmail({
      to: normalizedEmail,
      otp,
      fullName: user.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
    });

    if (!isSent) {
      await redis.del(cooldownKey);
      throw new Error(t("mail.sendFailed"));
    }
  }

  public async verifyOtp(email: string, otp: string): Promise<void> {
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
  ): Promise<{ user: User; token: string; code?: string }> {
    const normalizedEmail = email.trim().toLowerCase();
    const lockoutKey = `login:lockout:${normalizedEmail}`;
    const attemptsKey = `login:attempts:${normalizedEmail}`;

    // Kiểm tra tài khoản có đang bị tạm khóa hay không
    const isLocked = await redis.get(lockoutKey);
    if (isLocked) {
      const ttl = await redis.ttl(lockoutKey);
      const remainingMinutes = Math.max(1, Math.ceil(ttl / 60));
      throw new Error(
        t("auth.accountLocked", { minutes: remainingMinutes.toString() }),
      );
    }

    // Helper xử lý tăng số lần thử sai và kích hoạt tạm khóa nếu chạm ngưỡng
    const handleFailedAttempt = async (): Promise<never> => {
      const attempts = await redis.incr(attemptsKey);
      if (attempts === 1) {
        await redis.expire(attemptsKey, LOGIN_LOCKOUT_SECONDS);
      }

      if (attempts >= MAX_LOGIN_ATTEMPTS) {
        await redis.set(lockoutKey, "1", "EX", LOGIN_LOCKOUT_SECONDS);
        await redis.del(attemptsKey);
        throw new Error(
          t("auth.accountLocked", {
            minutes: LOGIN_LOCKOUT_MINUTES.toString(),
          }),
        );
      }

      const remaining = MAX_LOGIN_ATTEMPTS - attempts;
      throw new Error(
        t("auth.invalidCredentialsWithAttempts", {
          remaining: remaining.toString(),
        }),
      );
    };

    const user =
      await this.userRepository.findByEmailWithPassword(normalizedEmail);
    if (!user) {
      return await handleFailedAttempt();
    }

    if (!user.isActive) {
      throw new Error(t("auth.accountInactive"));
    }

    const isPasswordValid =
      user.password && (await argon2.verify(user.password, password));
    if (!isPasswordValid) {
      return await handleFailedAttempt();
    }

    await redis.del(attemptsKey);

    const { password: _, ...userWithoutPassword } = user;

    if (!user.isEmailVerified) {
      const cooldownKey = `otp:cooldown:${normalizedEmail}`;
      const canSend = await redis.set(cooldownKey, "1", "EX", 60, "NX");
      if (canSend) {
        const otp = await this.otpService.generateAndSaveOtp(
          normalizedEmail,
          "register",
          TTL_OTP_SECONDS,
        );
        await this.mailService.sendOtpEmail({
          to: normalizedEmail,
          otp,
          fullName: user.fullName,
          expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
        });
      }

      return {
        user: userWithoutPassword as User,
        token: "",
        code: CODE_RESPONSE.NEED_VERIFY_EMAIL,
      };
    }

    const token = jwt.sign(
      {
        sub: user.id,
        email: user.email,
        role: user.role,
      },
      this.jwtSecret,
      {
        expiresIn: "7d",
      },
    );

    return {
      user: userWithoutPassword as User,
      token,
    };
  }

  public async forgotPassword(email: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const cooldownKey = `otp:cooldown:forgot_password:${normalizedEmail}`;

    // 1. Kiểm tra cooldown (60 giây)
    const canSend = await redis.set(cooldownKey, "1", "EX", 60, "NX");
    if (!canSend) {
      throw new Error(t("auth.otpCooldown"));
    }

    // 2. Kiểm tra tài khoản tồn tại và đang hoạt động
    const user = await this.userRepository.findOneBy({ email: normalizedEmail });
    if (!user || !user.isActive) {
      // Kết thúc thành công giả định để tránh user enumeration
      return;
    }

    // 3. Tạo mã OTP 6 số lưu vào Redis với purpose 'forgot_password'
    const otp = await this.otpService.generateAndSaveOtp(
      normalizedEmail,
      "forgot_password",
      TTL_OTP_SECONDS,
    );

    // 4. Gửi email
    const isSent = await this.mailService.sendOtpEmail({
      to: normalizedEmail,
      otp,
      fullName: user.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
      subject: t("mail.forgotPasswordSubject"),
      intro: t("mail.forgotPasswordIntro"),
    });

    if (!isSent) {
      await redis.del(cooldownKey);
      throw new Error(t("mail.sendFailed"));
    }
  }

  public async verifyResetOtp(
    email: string,
    otp: string,
  ): Promise<{ resetToken: string }> {
    const normalizedEmail = email.trim().toLowerCase();

    // 1. Xác thực OTP với purpose 'forgot_password'
    const isValid = await this.otpService.verifyOtp(
      normalizedEmail,
      otp,
      "forgot_password",
    );
    if (!isValid) {
      throw new Error(t("auth.invalidOtp"));
    }

    // 2. Kiểm tra user có tồn tại
    const user = await this.userRepository.findOneBy({ email: normalizedEmail });
    if (!user) {
      throw new Error(t("auth.userNotFound"));
    }

    // 3. Tạo reset token ngẫu nhiên an toàn (TTL 15 phút)
    const resetToken = crypto.randomUUID();
    await redis.set(
      `password_reset_token:${resetToken}`,
      normalizedEmail,
      "EX",
      900,
    );

    return { resetToken };
  }

  public async resetPassword(
    resetToken: string,
    newPassword: string,
  ): Promise<void> {
    // 1. Lấy email từ token trong Redis
    const tokenKey = `password_reset_token:${resetToken}`;
    const email = await redis.get(tokenKey);
    if (!email) {
      throw new Error(t("auth.invalidResetToken"));
    }

    // 2. Tìm user
    const user = await this.userRepository.findOneBy({ email });
    if (!user) {
      throw new Error(t("auth.userNotFound"));
    }

    // 3. Băm mật khẩu mới bằng Argon2 & lưu DB
    user.password = await argon2.hash(newPassword);
    user.isEmailVerified = true;
    await this.userRepository.save(user);

    // 4. Xóa resetToken khỏi Redis (dùng 1 lần duy nhất)
    await redis.del(tokenKey);

    // 5. Xóa key lockout / attempts của tài khoản (nếu đang bị khóa)
    await redis.del(`login:attempts:${email}`, `login:lockout:${email}`);
  }

  public async logout(token: string): Promise<void> {
    if (!token) return;

    try {
      // Giải mã token để tính thời gian sống còn lại (TTL)
      const decoded = jwt.decode(token) as { exp?: number } | null;
      if (decoded && decoded.exp) {
        const nowInSeconds = Math.floor(Date.now() / 1000);
        const remainingTtl = decoded.exp - nowInSeconds;

        if (remainingTtl > 0) {
          // Lưu token vào Redis blacklist cho đến khi token tự hết hạn
          await redis.set(`blacklist:token:${token}`, "1", "EX", remainingTtl);
          return;
        }
      }
      // Fallback mặc định 7 ngày nếu không đọc được exp
      await redis.set(`blacklist:token:${token}`, "1", "EX", 7 * 24 * 3600);
    } catch {
      await redis.set(`blacklist:token:${token}`, "1", "EX", 7 * 24 * 3600);
    }
  }
}
