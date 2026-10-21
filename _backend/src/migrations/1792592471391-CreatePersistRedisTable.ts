import { MigrationInterface, QueryRunner } from "typeorm";

export class CreatePersistRedisTable1792592471391 implements MigrationInterface {
    name = 'CreatePersistRedisTable1792592471391'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "persist_redis" ("key" character varying(255) NOT NULL, "value" jsonb NOT NULL, "ttl" integer, "expiredAt" TIMESTAMP WITH TIME ZONE, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_2a20a4612ac945291ac24915e4c" PRIMARY KEY ("key"))`);
        await queryRunner.query(`CREATE INDEX "IDX_0db2b21c41c6a42b4c85f533f7" ON "persist_redis"  ("expiredAt") `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_0db2b21c41c6a42b4c85f533f7"`);
        await queryRunner.query(`DROP TABLE "persist_redis"`);
    }

}
