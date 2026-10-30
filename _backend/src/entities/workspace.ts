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
import { WorkspaceType } from "../utils/constanst.js";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { SoftDeletableTrait } from "../mixins/softDeletableTrait.js";
import { User } from "./user.js";
import { Province } from "./province.js";
import { Ward } from "./ward.js";

@Entity({ name: "workspaces" })
export class Workspace extends Mixin(AuditableTrait, SoftDeletableTrait) {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Index()
  @Column({ type: "uuid" })
  userId: string;

  @ManyToOne(() => User, (user) => user.workspaces, {
    onDelete: "CASCADE",
  })
  @JoinColumn({ name: "userId" })
  user: Relation<User>;

  @Column({
    type: "enum",
    enum: WorkspaceType,
    default: WorkspaceType.RENTED_ROOM,
  })
  type: WorkspaceType;

  @Column({ type: "varchar", length: 255 })
  name: string;

  @Column({ type: "double precision" })
  area: number;

  @Column({ type: "integer", default: 0 })
  numberOfRooms: number;

  @Column({ type: "integer" })
  provinceId: number;

  @ManyToOne(() => Province, (province) => province.workspaces, {
    onDelete: "RESTRICT",
  })
  @JoinColumn({ name: "provinceId" })
  province: Relation<Province>;

  @Column({ type: "integer" })
  wardId: number;

  @ManyToOne(() => Ward, (ward) => ward.workspaces, {
    onDelete: "RESTRICT",
  })
  @JoinColumn({ name: "wardId" })
  ward: Relation<Ward>;

  @Column({ type: "varchar", length: 255 })
  address: string;

  @Column({ type: "text", nullable: true })
  description: string | null;

  @Column({ type: "varchar", length: 100 })
  contactName: string;

  @Column({ type: "varchar", length: 20 })
  contactPhone: string;

  @Column({ type: "varchar", length: 20, nullable: true })
  contactZalo: string | null;

  @Column({ type: "integer", default: 1 })
  status: number;
}
