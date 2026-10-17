import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";
import { Mixin } from "ts-mixer";
import { Gender, UserRole } from "../utils/constanst.js";
import { AuditableTrait } from "../mixins/auditableTrait.js";

@Entity({ name: "users" })
export class User extends Mixin(AuditableTrait) {
  @PrimaryGeneratedColumn()
  id: string;

  @Column({ type: "varchar", length: 255, unique: true })
  email: string;

  @Column({ type: "varchar", length: 255 })
  password: string;

  @Column({ type: "varchar", length: 100, nullable: true })
  fullName: string | null;

  @Column({ type: "varchar", length: 20, nullable: true })
  phoneNumber: string | null;

  @Column({ type: "varchar", length: 255, nullable: true })
  avatarUrl: string | null;

  @Column({ type: "text", nullable: true })
  bio: string | null;

  @Column({
    type: "enum",
    enum: Gender,
    default: Gender.MALE,
  })
  gender: Gender;

  @Column({
    type: "enum",
    enum: UserRole,
    default: UserRole.TENANT,
  })
  role: UserRole;

  @Column({ type: "boolean", default: true })
  isActive: boolean;

  @Column({ type: "varchar", length: 100, default: "vi", nullable: true })
  language: string | null;
}
