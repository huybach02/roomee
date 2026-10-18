import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import { User } from "../entities/user.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class UserRepository extends Repository<User> {
  constructor() {
    super(User, AppDataSource.manager);
  }

  // Add custom methods for complex queries if needed

  public async findByEmailWithPassword(email: string): Promise<User | null> {
    return this.createQueryBuilder("user")
      .where("user.email = :email", { email })
      .addSelect("user.password")
      .getOne();
  }
}
