import { MigrationInterface, QueryRunner } from "typeorm";

export class UpdateRefreshTokenPreviousHashAndUnique1792767937184 implements MigrationInterface {
    name = 'UpdateRefreshTokenPreviousHashAndUnique1792767937184'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_c25bc63d248ca90e8dcc1d92d0"`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" ADD "previousTokenHash" character varying(64)`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" ADD "rotatedAt" TIMESTAMP WITH TIME ZONE`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" ADD CONSTRAINT "UQ_c25bc63d248ca90e8dcc1d92d06" UNIQUE ("tokenHash")`);
        await queryRunner.query(`CREATE UNIQUE INDEX "IDX_c25bc63d248ca90e8dcc1d92d0" ON "refresh_tokens"  ("tokenHash") `);
        await queryRunner.query(`CREATE INDEX "IDX_949eca8b290f33278678ce3c10" ON "refresh_tokens"  ("previousTokenHash") `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_949eca8b290f33278678ce3c10"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_c25bc63d248ca90e8dcc1d92d0"`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" DROP CONSTRAINT "UQ_c25bc63d248ca90e8dcc1d92d06"`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" DROP COLUMN "rotatedAt"`);
        await queryRunner.query(`ALTER TABLE "refresh_tokens" DROP COLUMN "previousTokenHash"`);
        await queryRunner.query(`CREATE INDEX "IDX_c25bc63d248ca90e8dcc1d92d0" ON "refresh_tokens" USING btree ("tokenHash") `);
    }

}
