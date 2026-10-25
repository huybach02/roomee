import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  type Relation,
} from "typeorm";
import { Mixin } from "ts-mixer";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { Province } from "./province.js";
import { User } from "./user.js";
import { Workspace } from "./workspace.js";

@Entity({ name: "wards" })
export class Ward extends Mixin(AuditableTrait) {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: "integer", unique: true })
  code: number;

  @Column({ type: "integer" })
  provinceId: number;

  @Column({ type: "varchar", length: 255 })
  fullName: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  fullNameEn: string | null;

  @Column({ type: "varchar", length: 255 })
  codeName: string;

  @ManyToOne(() => Province, (province) => province.wards, {
    onDelete: "CASCADE",
  })
  @JoinColumn({ name: "provinceId" })
  province: Relation<Province>;

  @OneToMany(() => User, (user) => user.ward)
  users: Relation<User[]>;

  @OneToMany(() => Workspace, (workspace) => workspace.ward)
  workspaces: Relation<Workspace[]>;
}
