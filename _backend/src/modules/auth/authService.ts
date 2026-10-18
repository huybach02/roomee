import { injectable } from "tsyringe";
import { User } from "../../entities/user.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { RegisterDto } from "./authSchema.js";
import argon2 from "argon2";
import { CODE_RESPONSE, Gender, UserRole } from "../../utils/constanst.js";
import { MailService } from "../mail/mailService.js";
import { OtpService } from "./otpService.js";

@injectable()
export class AuthService {
  private readonly jwtSecret = process.env.JWT_SECRET || "default_secret";

  constructor(
    private userRepository: UserRepository,
    private mailService: MailService,
    private otpService: OtpService,
  ) {}

  public async register(
    dtoData: RegisterDto,
  ): Promise<{ user: User; code: string }> {
    // Check if the email already exists
    const existingUser = await this.userRepository.findOneBy({
      email: dtoData.email,
    });
    if (existingUser) {
      throw new Error(t("emailAlreadyExists"));
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
      isActive: true,
      provinceId: dtoData.provinceId || null,
      wardId: dtoData.wardId || null,
    });

    const savedUser = await this.userRepository.save(user);

    // Tạo mã OTP 6 số và lưu vào Redis (hết hạn sau 10 phút)
    const otp = await this.otpService.generateAndSaveOtp(
      savedUser.email,
      "register",
      600,
    );

    // Gửi email chứa mã OTP xác thực
    await this.mailService.sendOtpEmail({
      to: savedUser.email,
      otp,
      fullName: savedUser.fullName,
      expiresInMinutes: 10,
    });

    return {
      user: savedUser as User,
      code: CODE_RESPONSE.NEED_VERIFY_EMAIL,
    };
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
