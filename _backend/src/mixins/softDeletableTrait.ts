import { Column, DeleteDateColumn } from "typeorm";
import { decorate } from "ts-mixer";

export class SoftDeletableTrait {
  @decorate(DeleteDateColumn({ type: "timestamp with time zone", nullable: true }))
  deletedAt: Date | null;

  @decorate(Column({ type: "uuid", nullable: true }))
  deletedBy: string | null;
}
