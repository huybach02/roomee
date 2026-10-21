import { MigrationInterface, QueryRunner } from "typeorm";

export class AddHasContractToUserEntity1792579568037 implements MigrationInterface {
    name = 'AddHasContractToUserEntity1792579568037'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" ADD "hasContract" boolean NOT NULL DEFAULT false`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "hasContract"`);
    }

}
