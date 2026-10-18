import { MigrationInterface, QueryRunner } from "typeorm";

export class AddBirthdayToUser1792339200000 implements MigrationInterface {
    name = 'AddBirthdayToUser1792339200000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" ADD "birthday" date`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "birthday"`);
    }
}
