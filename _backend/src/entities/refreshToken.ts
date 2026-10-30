import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Index,
  type Relation,
} from "typeorm";
import { Mixin } from "ts-mixer";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { User } from "./user.js";

@Entity({ name: "refresh_tokens" })
export class RefreshToken extends Mixin(AuditableTrait) {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Index()
  @Column({ type: "uuid" })
  userId: string;

  @ManyToOne(() => User, { onDelete: "CASCADE" })
  @JoinColumn({ name: "userId" })
  user: Relation<User>;

  @Index({ unique: true })
  @Column({ type: "varchar", length: 64, unique: true })
  tokenHash: string;

  @Index()
  @Column({ type: "varchar", length: 64, nullable: true })
  previousTokenHash: string | null;

  @Column({ type: "timestamp with time zone", nullable: true })
  rotatedAt: Date | null;

  @Column({ type: "varchar", length: 255, nullable: true })
  deviceInfo: string | null;

  @Column({ type: "varchar", length: 45, nullable: true })
  ipAddress: string | null;

  @Column({ type: "timestamp with time zone" })
  expiresAt: Date;

  @Column({ type: "boolean", default: false })
  isRevoked: boolean;

  @Column({
    type: "timestamp with time zone",
    default: () => "CURRENT_TIMESTAMP",
  })
  lastActiveAt: Date;
}
