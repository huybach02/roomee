import { Column, CreateDateColumn, UpdateDateColumn } from "typeorm";
import { decorate } from "ts-mixer";

export class AuditableTrait {
  @decorate(CreateDateColumn({ type: "timestamp with time zone" }))
  createdAt: Date;

  @decorate(UpdateDateColumn({ type: "timestamp with time zone" }))
  updatedAt: Date;

  @decorate(Column({ type: "integer", nullable: true }))
  createdBy: number | null;

  @decorate(Column({ type: "integer", nullable: true }))
  updatedBy: number | null;
}
