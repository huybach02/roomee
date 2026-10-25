import { MigrationInterface, QueryRunner } from "typeorm";

export class AddSoftDeleteToUserAndWorkspace1792822691279 implements MigrationInterface {
    name = 'AddSoftDeleteToUserAndWorkspace1792822691279'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "workspaces" ADD "deletedAt" TIMESTAMP WITH TIME ZONE`);
        await queryRunner.query(`ALTER TABLE "workspaces" ADD "deletedBy" integer`);
        await queryRunner.query(`ALTER TABLE "users" ADD "deletedAt" TIMESTAMP WITH TIME ZONE`);
        await queryRunner.query(`ALTER TABLE "users" ADD "deletedBy" integer`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3"`);
        await queryRunner.query(`CREATE UNIQUE INDEX "IDX_78ca3a129ee713cf4082cb89fd" ON "users"  ("email") WHERE "deletedAt" IS NULL`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_78ca3a129ee713cf4082cb89fd"`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email")`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "deletedBy"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "deletedAt"`);
        await queryRunner.query(`ALTER TABLE "workspaces" DROP COLUMN "deletedBy"`);
        await queryRunner.query(`ALTER TABLE "workspaces" DROP COLUMN "deletedAt"`);
    }

}
