import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
  type Relation,
} from "typeorm";
import { Mixin } from "ts-mixer";
import { Gender, UserRole } from "../utils/constanst.js";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { SoftDeletableTrait } from "../mixins/softDeletableTrait.js";
import { Province } from "./province.js";
import { Ward } from "./ward.js";
import { Workspace } from "./workspace.js";

@Entity({ name: "users" })
@Index(["email"], { unique: true, where: '"deletedAt" IS NULL' })
export class User extends Mixin(AuditableTrait, SoftDeletableTrait) {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "varchar", length: 255 })
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

  @OneToMany(() => Workspace, (workspace) => workspace.user)
  workspaces: Relation<Workspace[]>;
}
