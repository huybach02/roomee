import { injectable } from "tsyringe";
import crypto from "node:crypto";
import { User } from "../../entities/user.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { RegisterDto } from "./authSchema.js";
import argon2 from "argon2";
import jwt from "jsonwebtoken";
import {
  ACCESS_TOKEN_EXPIRES_IN,
  CODE_RESPONSE,
  Gender,
  LOGIN_LOCKOUT_MINUTES,
  LOGIN_LOCKOUT_SECONDS,
  MAX_LOGIN_ATTEMPTS,
  OTP_EXPIRES_IN_MINUTES,
  REFRESH_TOKEN_EXPIRES_IN_DAYS,
  TTL_ACCESS_TOKEN_SECONDS,
  TTL_OTP_SECONDS,
  UserRole,
} from "../../utils/constanst.js";
import { MailService } from "../mail/mailService.js";
import { OtpService } from "./otpService.js";
import { CacheService } from "../../services/cacheService.js";
import { RefreshTokenRepository } from "../../repositories/refreshTokenRepository.js";

@injectable()
export class AuthService {
  private readonly jwtSecret: string;

  constructor(
    private userRepository: UserRepository,
    private mailService: MailService,
    private otpService: OtpService,
    private cacheService: CacheService,
    private refreshTokenRepository: RefreshTokenRepository,
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
    await this.cacheService.set(
      `otp:cooldown:${savedUser.email.trim().toLowerCase()}`,
      "1",
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
    const canSend = await this.cacheService.setNx(cooldownKey, "1", 60);
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
      await this.cacheService.del(cooldownKey);
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
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    user: User;
    token: string;
    accessToken: string;
    refreshToken: string;
    code?: string;
  }> {
    const normalizedEmail = email.trim().toLowerCase();
    const lockoutKey = `login:lockout:${normalizedEmail}`;
    const attemptsKey = `login:attempts:${normalizedEmail}`;

    // Kiểm tra tài khoản có đang bị tạm khóa hay không
    const isLocked = await this.cacheService.get(lockoutKey);
    if (isLocked) {
      const ttl = await this.cacheService.ttl(lockoutKey);
      const remainingMinutes = Math.max(1, Math.ceil(ttl / 60));
      throw new Error(
        t("auth.accountLocked", { minutes: remainingMinutes.toString() }),
      );
    }

    // Helper xử lý tăng số lần thử sai và kích hoạt tạm khóa nếu chạm ngưỡng
    const handleFailedAttempt = async (): Promise<never> => {
      const attempts = await this.cacheService.incr(
        attemptsKey,
        LOGIN_LOCKOUT_SECONDS,
      );

      if (attempts >= MAX_LOGIN_ATTEMPTS) {
        await this.cacheService.set(lockoutKey, "1", LOGIN_LOCKOUT_SECONDS);
        await this.cacheService.del(attemptsKey);
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

    await this.cacheService.del(attemptsKey);

    const { password: _, ...userWithoutPassword } = user;

    if (!user.isEmailVerified) {
      const cooldownKey = `otp:cooldown:${normalizedEmail}`;
      const canSend = await this.cacheService.setNx(cooldownKey, "1", 60);
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
        accessToken: "",
        refreshToken: "",
        code: CODE_RESPONSE.NEED_VERIFY_EMAIL,
      };
    }

    // Sinh Refresh Token (64 ký tự hex ngẫu nhiên) và lưu bản ghi phiên
    const rawRefreshToken = crypto.randomBytes(32).toString("hex");
    const tokenHash = crypto
      .createHash("sha256")
      .update(rawRefreshToken)
      .digest("hex");
    const expiresAt = new Date(
      Date.now() + REFRESH_TOKEN_EXPIRES_IN_DAYS * 24 * 60 * 60 * 1000,
    );

    const session = this.refreshTokenRepository.create({
      userId: user.id,
      tokenHash,
      deviceInfo: deviceInfo || null,
      ipAddress: ipAddress || null,
      expiresAt,
      isRevoked: false,
    });
    const savedSession = await this.refreshTokenRepository.save(session);

    // Sinh Access Token ngắn hạn mang sid (Session ID)
    const accessToken = jwt.sign(
      {
        sub: user.id,
        email: user.email,
        role: user.role,
        sid: savedSession.id,
      },
      this.jwtSecret,
      {
        expiresIn: ACCESS_TOKEN_EXPIRES_IN,
      },
    );

    return {
      user: userWithoutPassword as User,
      token: accessToken,
      accessToken,
      refreshToken: rawRefreshToken,
    };
  }

  public async forgotPassword(email: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const cooldownKey = `otp:cooldown:forgot_password:${normalizedEmail}`;

    // 1. Kiểm tra cooldown (60 giây)
    const canSend = await this.cacheService.setNx(cooldownKey, "1", 60);
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
      await this.cacheService.del(cooldownKey);
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
    await this.cacheService.set(
      `password_reset_token:${resetToken}`,
      normalizedEmail,
      900,
    );

    return { resetToken };
  }

  public async resetPassword(
    resetToken: string,
    newPassword: string,
  ): Promise<void> {
    // 1. Lấy email từ token trong Redis (fallback DB)
    const tokenKey = `password_reset_token:${resetToken}`;
    const email = await this.cacheService.get<string>(tokenKey);
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

    // 4. Xóa resetToken khỏi Redis & DB (dùng 1 lần duy nhất)
    await this.cacheService.del(tokenKey);

    // 5. Xóa key lockout / attempts của tài khoản (nếu đang bị khóa)
    await this.cacheService.del(
      `login:attempts:${email}`,
      `login:lockout:${email}`,
    );
  }

  public async logout(token: string): Promise<void> {
    if (!token) return;

    try {
      // Giải mã token để lấy thông tin session và TTL còn lại
      const decoded = jwt.decode(token) as {
        exp?: number;
        sid?: string;
      } | null;

      let remainingTtl = TTL_ACCESS_TOKEN_SECONDS;
      if (decoded && decoded.exp) {
        const nowInSeconds = Math.floor(Date.now() / 1000);
        const calculated = decoded.exp - nowInSeconds;
        if (calculated > 0) {
          remainingTtl = calculated;
        }
      }

      // 1. Blacklist access token trong Redis + DB
      await this.cacheService.set(
        `blacklist:token:${token}`,
        "1",
        remainingTtl,
      );

      // 2. Thu hồi session trong DB và Redis nếu có sid
      if (decoded && decoded.sid) {
        await this.refreshTokenRepository.revokeBySessionId(decoded.sid);
        await this.cacheService.set(
          `blacklist:session:${decoded.sid}`,
          "1",
          remainingTtl,
        );
      }
    } catch {
      await this.cacheService.set(
        `blacklist:token:${token}`,
        "1",
        TTL_ACCESS_TOKEN_SECONDS,
      );
    }
  }

  public async refreshToken(
    refreshTokenString: string,
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    token: string;
  }> {
    if (!refreshTokenString) {
      throw new Error(t("auth.invalidRefreshToken"));
    }

    const tokenHash = crypto
      .createHash("sha256")
      .update(refreshTokenString)
      .digest("hex");

    const session =
      await this.refreshTokenRepository.findByTokenHash(tokenHash);

    if (
      !session ||
      session.isRevoked ||
      new Date(session.expiresAt).getTime() <= Date.now()
    ) {
      throw new Error(t("auth.invalidRefreshToken"));
    }

    if (!session.user || !session.user.isActive) {
      throw new Error(t("auth.accountInactive"));
    }

    // Token Rotation: Thu hồi session cũ
    session.isRevoked = true;
    await this.refreshTokenRepository.save(session);

    // Blacklist session cũ trong Redis + DB để chặn tức thì các token của phiên cũ
    await this.cacheService.set(
      `blacklist:session:${session.id}`,
      "1",
      TTL_ACCESS_TOKEN_SECONDS,
    );

    // Sinh refresh token mới và session mới
    const newRawRefreshToken = crypto.randomBytes(32).toString("hex");
    const newTokenHash = crypto
      .createHash("sha256")
      .update(newRawRefreshToken)
      .digest("hex");
    const newExpiresAt = new Date(
      Date.now() + REFRESH_TOKEN_EXPIRES_IN_DAYS * 24 * 60 * 60 * 1000,
    );

    const newSession = this.refreshTokenRepository.create({
      userId: session.userId,
      tokenHash: newTokenHash,
      deviceInfo: deviceInfo || session.deviceInfo,
      ipAddress: ipAddress || session.ipAddress,
      expiresAt: newExpiresAt,
      isRevoked: false,
    });
    const savedNewSession = await this.refreshTokenRepository.save(newSession);

    const newAccessToken = jwt.sign(
      {
        sub: session.user.id,
        email: session.user.email,
        role: session.user.role,
        sid: savedNewSession.id,
      },
      this.jwtSecret,
      {
        expiresIn: ACCESS_TOKEN_EXPIRES_IN,
      },
    );

    return {
      accessToken: newAccessToken,
      refreshToken: newRawRefreshToken,
      token: newAccessToken,
    };
  }
}
