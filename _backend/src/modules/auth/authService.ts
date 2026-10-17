import { injectable } from "tsyringe";
import { User } from "../../entities/user.js";
import { UserRepository } from "../../repositories/userRepository.js";

@injectable()
export class AuthService {
  private readonly saltRounds = 10;
  private readonly jwtSecret = process.env.JWT_SECRET || "default_secret";

  constructor(private userRepository: UserRepository) {}

  public async register(
    username: string,
    email: string,
    password: string,
  ): Promise<{ user: User; token: string }> {
    // const hashedPassword = await bcrypt.hash(password, this.saltRounds);
    // const newUser = await this.userRepository.save(
    //   this.userRepository.create({
    //     username,
    //     email,
    //     password: hashedPassword,
    //   }),
    // );
    // const token = jwt.sign({ id: newUser.id }, this.jwtSecret, {
    //   expiresIn: "1h",
    // });
    // return { user: newUser, token };
    return { user: {} as User, token: "dummy_token" }; // Placeholder implementation
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
