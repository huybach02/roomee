import {
  Entity,
  PrimaryColumn,
  Column,
  Index,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";

@Entity({ name: "persist_redis" })
export class PersistRedis {
  @PrimaryColumn({ type: "varchar", length: 255 })
  key: string;

  @Column({ type: "jsonb" })
  value: any;

  @Column({ type: "integer", nullable: true })
  ttl: number | null;

  @Index()
  @Column({ type: "timestamp with time zone", nullable: true })
  expiredAt: Date | null;

  @CreateDateColumn({ type: "timestamp with time zone" })
  createdAt: Date;

  @UpdateDateColumn({ type: "timestamp with time zone" })
  updatedAt: Date;
}
