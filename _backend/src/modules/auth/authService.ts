import { injectable } from "tsyringe";
import crypto from "node:crypto";
import { User } from "../../entities/user.js";
import { RefreshToken } from "../../entities/refreshToken.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { RegisterDto } from "./authSchema.js";
import argon2 from "argon2";
import jwt from "jsonwebtoken";
import {
  ACCESS_TOKEN_EXPIRES_IN,
  CODE_RESPONSE,
  Gender,
  JWT_ALGORITHM,
  LOGIN_LOCKOUT_MINUTES,
  LOGIN_LOCKOUT_SECONDS,
  MAX_LOGIN_ATTEMPTS,
  OTP_EXPIRES_IN_MINUTES,
  REFRESH_TOKEN_EXPIRES_IN_DAYS,
  REFRESH_TOKEN_GRACE_PERIOD_MS,
  TTL_ACCESS_TOKEN_SECONDS,
  TTL_OTP_SECONDS,
  UserRole,
} from "../../utils/constanst.js";
import { MailQueue } from "../../queues/mail/mailQueue.js";
import { OtpService } from "./otpService.js";
import { CacheService } from "../../services/cacheService.js";
import { RefreshTokenRepository } from "../../repositories/refreshTokenRepository.js";
import { AppError } from "../../utils/appError.js";
import { redis } from "../../config/redis.js";

@injectable()
export class AuthService {
  private readonly jwtSecret: string;

  constructor(
    private userRepository: UserRepository,
    private mailQueue: MailQueue,
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
      throw AppError.conflict(t("auth.emailAlreadyExists"));
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

    // Đẩy việc gửi email chứa mã OTP vào hàng đợi BullMQ (xử lý nền bất đồng bộ, retry 3 lần)
    await this.mailQueue.addSendOtpJob({
      to: savedUser.email,
      otp,
      fullName: savedUser.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
    });

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
      throw AppError.tooManyRequests(t("auth.otpCooldown"));
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

    // Đẩy việc gửi email vào hàng đợi BullMQ xử lý nền
    await this.mailQueue.addSendOtpJob({
      to: normalizedEmail,
      otp,
      fullName: user.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
    });
  }

  public async verifyOtp(
    email: string,
    otp: string,
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    user: User;
    accessToken: string;
    refreshToken: string;
  }> {
    const isOtpValid = await this.otpService.verifyOtp(email, otp, "register");
    if (!isOtpValid) {
      throw AppError.badRequest(t("auth.invalidOtp"));
    }

    const user = await this.userRepository.findOne({
      where: { email },
      relations: {
        province: true,
        ward: true,
      },
    });
    if (!user) {
      throw AppError.notFound(t("auth.userNotFound"));
    }

    if (!user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
    }

    user.isEmailVerified = true;
    await this.userRepository.save(user);

    return this.createSessionAndTokens(user, deviceInfo, ipAddress);
  }

  private async createSessionAndTokens(
    user: User,
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    user: User;
    accessToken: string;
    refreshToken: string;
  }> {
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
      deviceInfo: deviceInfo ? deviceInfo.slice(0, 255) : null,
      ipAddress: ipAddress ? ipAddress.slice(0, 45) : null,
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
        algorithm: JWT_ALGORITHM,
      },
    );

    const { password: _, ...userWithoutPassword } = user;

    return {
      user: userWithoutPassword as User,
      accessToken,
      refreshToken: rawRefreshToken,
    };
  }

  public async login(
    email: string,
    password: string,
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    user: User;
    accessToken: string;
    refreshToken: string;
    code?: string;
  }> {
    const normalizedEmail = email.trim().toLowerCase();
    const clientIp = ipAddress ? ipAddress.trim() : "unknown";
    const lockoutKey = `login:lockout:${normalizedEmail}:${clientIp}`;
    const attemptsKey = `login:attempts:${normalizedEmail}:${clientIp}`;

    // Kiểm tra tài khoản có đang bị tạm khóa theo IP này hay không
    const isLocked = await this.cacheService.get(lockoutKey);
    if (isLocked) {
      const ttl = await this.cacheService.ttl(lockoutKey);
      const remainingMinutes = Math.max(1, Math.ceil(ttl / 60));
      throw AppError.locked(
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
        throw AppError.locked(
          t("auth.accountLocked", {
            minutes: LOGIN_LOCKOUT_MINUTES.toString(),
          }),
        );
      }

      const remaining = MAX_LOGIN_ATTEMPTS - attempts;
      throw AppError.unauthorized(
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

    const isPasswordValid =
      user.password && (await argon2.verify(user.password, password));
    if (!isPasswordValid) {
      return await handleFailedAttempt();
    }

    // Kiểm tra trạng thái tài khoản CHỈ KHI đã xác thực đúng mật khẩu (chống User Enumeration)
    if (!user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
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
        // Đẩy việc gửi email vào hàng đợi BullMQ xử lý nền
        await this.mailQueue.addSendOtpJob({
          to: normalizedEmail,
          otp,
          fullName: user.fullName,
          expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
        });
      }

      return {
        user: userWithoutPassword as User,
        accessToken: "",
        refreshToken: "",
        code: CODE_RESPONSE.NEED_VERIFY_EMAIL,
      };
    }

    // Sinh phiên đăng nhập và cặp Token
    return this.createSessionAndTokens(user, deviceInfo, ipAddress);
  }

  public async forgotPassword(email: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const cooldownKey = `otp:cooldown:forgot_password:${normalizedEmail}`;

    // 1. Kiểm tra cooldown (60 giây)
    const canSend = await this.cacheService.setNx(cooldownKey, "1", 60);
    if (!canSend) {
      throw AppError.tooManyRequests(t("auth.otpCooldown"));
    }

    // 2. Kiểm tra tài khoản tồn tại và đang hoạt động
    const user = await this.userRepository.findOneBy({
      email: normalizedEmail,
    });
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

    // 4. Đẩy việc gửi email vào hàng đợi BullMQ (xử lý nền, triệt tiêu hoàn toàn timing attack)
    await this.mailQueue.addSendOtpJob({
      to: normalizedEmail,
      otp,
      fullName: user.fullName,
      expiresInMinutes: OTP_EXPIRES_IN_MINUTES,
      subject: t("mail.forgotPasswordSubject"),
      intro: t("mail.forgotPasswordIntro"),
    });
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
      throw AppError.badRequest(t("auth.invalidOtp"));
    }

    // 2. Kiểm tra user có tồn tại
    const user = await this.userRepository.findOneBy({
      email: normalizedEmail,
    });
    if (!user) {
      throw AppError.notFound(t("auth.userNotFound"));
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
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    user: User;
    accessToken: string;
    refreshToken: string;
  }> {
    // 1. Lấy email từ token trong Redis (fallback DB)
    const tokenKey = `password_reset_token:${resetToken}`;
    const email = await this.cacheService.get<string>(tokenKey);
    if (!email) {
      throw AppError.badRequest(t("auth.invalidResetToken"));
    }

    // 2. Tìm user
    const user = await this.userRepository.findOne({
      where: { email },
      relations: {
        province: true,
        ward: true,
      },
    });
    if (!user) {
      throw AppError.notFound(t("auth.userNotFound"));
    }

    if (!user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
    }

    // 3. Băm mật khẩu mới bằng Argon2 & lưu DB
    user.password = await argon2.hash(newPassword);
    user.isEmailVerified = true;
    await this.userRepository.save(user);

    // 4. Thu hồi toàn bộ session đăng nhập cũ của user
    await this.refreshTokenRepository.revokeAllUserSessions(user.id);

    // 5. Xóa resetToken khỏi Redis & DB (dùng 1 lần duy nhất)
    await this.cacheService.del(tokenKey);

    // 6. Xóa key lockout / attempts của tài khoản trên mọi IP (nếu đang bị khóa)
    try {
      if (redis.status === "ready") {
        const lockoutKeys = await redis.keys(`login:*:${email}:*`);
        if (lockoutKeys.length > 0) {
          await this.cacheService.del(...lockoutKeys);
        }
      }
    } catch (error) {
      console.warn(
        `[AuthService] Clear lockout keys failed for ${email}:`,
        error,
      );
    }

    // 7. Tự động sinh phiên đăng nhập mới và trả về Token cho thiết bị vừa đổi mật khẩu
    return this.createSessionAndTokens(user, deviceInfo, ipAddress);
  }

  public async getProfile(userId: number): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: {
        province: true,
        ward: true,
      },
    });

    if (!user) {
      throw AppError.notFound(t("auth.userNotFound"));
    }

    if (!user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
    }

    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword as User;
  }

  public async logout(token: string): Promise<void> {
    if (!token) return;

    // Giải mã token để lấy thông tin session và TTL còn lại
    const decoded = jwt.decode(token) as {
      exp?: number;
      sid?: string;
    } | null;

    if (!decoded || !decoded.sid) {
      return;
    }

    let remainingTtl = TTL_ACCESS_TOKEN_SECONDS;
    if (decoded.exp) {
      const nowInSeconds = Math.floor(Date.now() / 1000);
      const calculated = decoded.exp - nowInSeconds;
      if (calculated > 0) {
        remainingTtl = calculated;
      }
    }

    // Thu hồi session trong DB và Redis
    await this.refreshTokenRepository.revokeBySessionId(decoded.sid);
    await this.cacheService.set(
      `blacklist:session:${decoded.sid}`,
      "1",
      remainingTtl,
    );
  }

  public async refreshToken(
    refreshTokenString: string,
    deviceInfo?: string,
    ipAddress?: string,
  ): Promise<{
    accessToken: string;
    refreshToken: string;
  }> {
    if (!refreshTokenString) {
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    const incomingHash = crypto
      .createHash("sha256")
      .update(refreshTokenString)
      .digest("hex");

    const session =
      await this.refreshTokenRepository.findByCurrentOrPreviousTokenHash(
        incomingHash,
      );

    if (!session) {
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    if (session.isRevoked) {
      // Session đã bị thu hồi trước đó -> Thu hồi toàn bộ session để bảo vệ tài khoản
      await this.refreshTokenRepository.revokeAllUserSessions(session.userId);
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    if (new Date(session.expiresAt).getTime() <= Date.now()) {
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    if (!session.user || !session.user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
    }

    // 1. Kiểm tra kịch bản DÙNG LẠI TOKEN CŨ (Token Reuse Detection):
    if (session.previousTokenHash === incomingHash) {
      const nowMs = Date.now();
      const rotatedAtMs = session.rotatedAt
        ? new Date(session.rotatedAt).getTime()
        : 0;
      const isWithinGracePeriod =
        nowMs - rotatedAtMs <= REFRESH_TOKEN_GRACE_PERIOD_MS;

      if (isWithinGracePeriod) {
        // Cho phép cấp lại Access Token hợp lệ mà không khóa tài khoản.
        // Không trả về refreshToken cũ để tránh client ghi đè ngược token đã rotate vào storage.
        const reissuedAccessToken = jwt.sign(
          {
            sub: session.user.id,
            email: session.user.email,
            role: session.user.role,
            sid: session.id,
          },
          this.jwtSecret,
          {
            expiresIn: ACCESS_TOKEN_EXPIRES_IN,
            algorithm: JWT_ALGORITHM,
          },
        );

        return {
          accessToken: reissuedAccessToken,
          refreshToken: "",
        };
      }

      // Vượt quá Grace Period (> 15s): Phát hiện token cũ bị kẻ gian dùng lại!
      await this.refreshTokenRepository.revokeAllUserSessions(session.userId);
      await this.cacheService.set(
        `blacklist:session:${session.id}`,
        "1",
        TTL_ACCESS_TOKEN_SECONDS,
      );
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    // 2. Kịch bản HỢP LỆ (incomingHash === session.tokenHash):
    // Giữ nguyên sid (session.id), chỉ cập nhật tokenHash & previousTokenHash
    const newRawRefreshToken = crypto.randomBytes(32).toString("hex");
    const newTokenHash = crypto
      .createHash("sha256")
      .update(newRawRefreshToken)
      .digest("hex");
    const newExpiresAt = new Date(
      Date.now() + REFRESH_TOKEN_EXPIRES_IN_DAYS * 24 * 60 * 60 * 1000,
    );
    const now = new Date();

    const effectiveDeviceInfo = deviceInfo
      ? deviceInfo.slice(0, 255)
      : session.deviceInfo;
    const effectiveIpAddress = ipAddress
      ? ipAddress.slice(0, 45)
      : session.ipAddress;

    // Cập nhật nguyên tử trên DB (chống race condition)
    const updateResult = await this.refreshTokenRepository
      .createQueryBuilder()
      .update(RefreshToken)
      .set({
        previousTokenHash: session.tokenHash,
        tokenHash: newTokenHash,
        rotatedAt: now,
        lastActiveAt: now,
        expiresAt: newExpiresAt,
        deviceInfo: effectiveDeviceInfo,
        ipAddress: effectiveIpAddress,
      })
      .where('id = :id AND "tokenHash" = :tokenHash AND "isRevoked" = false', {
        id: session.id,
        tokenHash: session.tokenHash,
      })
      .execute();

    if (updateResult.affected !== 1) {
      // Kiểm tra xem có phải do request song song đã vừa rotate thành công trong Grace Period không
      const currentSession = await this.refreshTokenRepository.findOne({
        where: { id: session.id },
        relations: { user: true },
      });

      if (
        currentSession &&
        !currentSession.isRevoked &&
        currentSession.previousTokenHash === session.tokenHash
      ) {
        const nowMs = Date.now();
        const rotatedAtMs = currentSession.rotatedAt
          ? new Date(currentSession.rotatedAt).getTime()
          : 0;
        if (nowMs - rotatedAtMs <= REFRESH_TOKEN_GRACE_PERIOD_MS) {
          const reissuedAccessToken = jwt.sign(
            {
              sub: session.user.id,
              email: session.user.email,
              role: session.user.role,
              sid: session.id,
            },
            this.jwtSecret,
            {
              expiresIn: ACCESS_TOKEN_EXPIRES_IN,
              algorithm: JWT_ALGORITHM,
            },
          );

          return {
            accessToken: reissuedAccessToken,
            refreshToken: "",
          };
        }
      }

      await this.refreshTokenRepository.revokeAllUserSessions(session.userId);
      throw AppError.unauthorized(t("auth.invalidRefreshToken"));
    }

    // Cấp Access Token mới mang CÙNG sid (session.id)
    const newAccessToken = jwt.sign(
      {
        sub: session.user.id,
        email: session.user.email,
        role: session.user.role,
        sid: session.id,
      },
      this.jwtSecret,
      {
        expiresIn: ACCESS_TOKEN_EXPIRES_IN,
        algorithm: JWT_ALGORITHM,
      },
    );

    return {
      accessToken: newAccessToken,
      refreshToken: newRawRefreshToken,
    };
  }
}
