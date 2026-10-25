import { MigrationInterface, QueryRunner } from "typeorm";

export class AutoMigration1792915749575 implements MigrationInterface {
    name = 'AutoMigration1792915749575'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "workspaces" ADD "status" integer NOT NULL DEFAULT '1'`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "workspaces" DROP COLUMN "status"`);
    }

}
