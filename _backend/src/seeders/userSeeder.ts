import { DataSource } from "typeorm";
import argon2 from "argon2";
import { User } from "../entities/user.js";
import { Gender, UserRole } from "../utils/constanst.js";
import type { ISeeder } from "./index.js";

export class UserSeeder implements ISeeder {
  public readonly name = "UserSeeder";

  public async run(dataSource: DataSource): Promise<void> {
    const userRepository = dataSource.getRepository(User);
    const defaultPassword = "password";
    const hashedPassword = await argon2.hash(defaultPassword);

    const initialUsers = [
      {
        email: "minhtuan@roomee.vn",
        fullName: "Minh Tuấn",
        phoneNumber: "0901111111",
        role: UserRole.TENANT,
        hasContract: true,
        isActive: true,
        isEmailVerified: true,
        gender: Gender.MALE,
      },
      {
        email: "vantoan@roomee.vn",
        fullName: "Văn Toàn",
        phoneNumber: "0902222222",
        role: UserRole.TENANT,
        hasContract: false,
        isActive: true,
        isEmailVerified: true,
        gender: Gender.MALE,
      },
      {
        email: "huybach2002ct@gmail.com",
        fullName: "Huy Bách",
        phoneNumber: "0903333333",
        role: UserRole.LANDLORD,
        hasContract: false,
        isActive: true,
        isEmailVerified: true,
        gender: Gender.MALE,
      },
    ];

    console.log(`[UserSeeder] 👤 Bắt đầu khởi tạo ${initialUsers.length} tài khoản người dùng...`);

    for (const userData of initialUsers) {
      const existingUser = await userRepository.findOneBy({
        email: userData.email,
      });

      if (existingUser) {
        existingUser.fullName = userData.fullName;
        existingUser.password = hashedPassword;
        existingUser.phoneNumber = userData.phoneNumber;
        existingUser.role = userData.role;
        existingUser.hasContract = userData.hasContract;
        existingUser.isActive = userData.isActive;
        existingUser.isEmailVerified = userData.isEmailVerified;
        existingUser.gender = userData.gender;
        await userRepository.save(existingUser);
        console.log(`[UserSeeder] 🔄 Đã cập nhật tài khoản: ${userData.email} (${userData.role}, hasContract: ${userData.hasContract})`);
      } else {
        const newUser = userRepository.create({
          ...userData,
          password: hashedPassword,
        });
        await userRepository.save(newUser);
        console.log(`[UserSeeder] ➕ Đã tạo mới tài khoản: ${userData.email} (${userData.role}, hasContract: ${userData.hasContract})`);
      }
    }

    console.log(`[UserSeeder] ✅ Khởi tạo dữ liệu người dùng hoàn tất!`);
  }
}
