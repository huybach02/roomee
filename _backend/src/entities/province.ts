import { Entity, PrimaryGeneratedColumn, Column, OneToMany, type Relation } from "typeorm";
import { Mixin } from "ts-mixer";
import { AuditableTrait } from "../mixins/auditableTrait.js";
import { Ward } from "./ward.js";
import { User } from "./user.js";

@Entity({ name: "provinces" })
export class Province extends Mixin(AuditableTrait) {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: "integer", unique: true })
  code: number;

  @Column({ type: "varchar", length: 255 })
  fullName: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  fullNameEn: string | null;

  @Column({ type: "varchar", length: 255 })
  codeName: string;

  @OneToMany(() => Ward, (ward) => ward.province)
  wards: Relation<Ward[]>;

  @OneToMany(() => User, (user) => user.province)
  users: Relation<User[]>;
}
