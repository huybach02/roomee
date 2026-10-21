import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  type Relation,
} from "typeorm";
import { Mixin } from "ts-mixer";
import { Gender, UserRole } from "../utils/constanst.js";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { Province } from "./province.js";
import { Ward } from "./ward.js";

@Entity({ name: "users" })
export class User extends Mixin(AuditableTrait) {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: "varchar", length: 255, unique: true })
  email: string;

  @Column({ type: "varchar", length: 255, select: false })
  password: string;

  @Column({ type: "varchar", length: 100, nullable: true })
  fullName: string | null;

  @Column({ type: "varchar", length: 20, nullable: true })
  phoneNumber: string | null;

  @Column({ type: "varchar", length: 255, nullable: true })
  avatarUrl: string | null;

  @Column({ type: "text", nullable: true })
  bio: string | null;

  @Column({ type: "date", nullable: true })
  birthday: string | null;

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

  @Column({ type: "integer", nullable: true })
  provinceId: number | null;

  @ManyToOne(() => Province, (province) => province.users, {
    nullable: true,
    onDelete: "SET NULL",
  })
  @JoinColumn({ name: "provinceId" })
  province: Relation<Province> | null;

  @Column({ type: "integer", nullable: true })
  wardId: number | null;

  @ManyToOne(() => Ward, (ward) => ward.users, {
    nullable: true,
    onDelete: "SET NULL",
  })
  @JoinColumn({ name: "wardId" })
  ward: Relation<Ward> | null;

  @Column({ type: "boolean", default: false })
  isEmailVerified: boolean;

  @Column({ type: "boolean", default: false })
  hasContract: boolean;
}
