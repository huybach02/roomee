import { MigrationInterface, QueryRunner } from "typeorm";

export class InitDatabase1792264935669 implements MigrationInterface {
    name = 'InitDatabase1792264935669'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."users_gender_enum" AS ENUM('male', 'female', 'other')`);
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum" AS ENUM('landlord', 'staff', 'tenant', 'admin')`);
        await queryRunner.query(`CREATE TABLE "users" ("id" SERIAL NOT NULL, "email" character varying(255) NOT NULL, "password" character varying(255) NOT NULL, "fullName" character varying(100), "phoneNumber" character varying(20), "avatarUrl" character varying(255), "bio" text, "gender" "public"."users_gender_enum" NOT NULL DEFAULT 'male', "role" "public"."users_role_enum" NOT NULL DEFAULT 'tenant', "isActive" boolean NOT NULL DEFAULT true, "provinceId" integer, "wardId" integer, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "createdBy" integer, "updatedBy" integer, CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "wards" ("id" SERIAL NOT NULL, "code" integer NOT NULL, "provinceId" integer NOT NULL, "fullName" character varying(255) NOT NULL, "fullNameEn" character varying(255), "codeName" character varying(255) NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "createdBy" integer, "updatedBy" integer, CONSTRAINT "UQ_24f16d2207b1dcb6ce07d81d20f" UNIQUE ("code"), CONSTRAINT "PK_f67afa72e02ac056570c0dde279" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "provinces" ("id" SERIAL NOT NULL, "code" integer NOT NULL, "fullName" character varying(255) NOT NULL, "fullNameEn" character varying(255), "codeName" character varying(255) NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "createdBy" integer, "updatedBy" integer, CONSTRAINT "UQ_f4b684af62d5cb3aa174f6b9b8a" UNIQUE ("code"), CONSTRAINT "PK_2e4260eedbcad036ec53222e0c7" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "FK_29c8b688bed71f61f2373cb76bd" FOREIGN KEY ("provinceId") REFERENCES "provinces"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "FK_d5b5ae072248834f4b95adabdf7" FOREIGN KEY ("wardId") REFERENCES "wards"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "wards" ADD CONSTRAINT "FK_94149b5470f5d69f6a9e1c223a2" FOREIGN KEY ("provinceId") REFERENCES "provinces"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "wards" DROP CONSTRAINT "FK_94149b5470f5d69f6a9e1c223a2"`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "FK_d5b5ae072248834f4b95adabdf7"`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "FK_29c8b688bed71f61f2373cb76bd"`);
        await queryRunner.query(`DROP TABLE "provinces"`);
        await queryRunner.query(`DROP TABLE "wards"`);
        await queryRunner.query(`DROP TABLE "users"`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
        await queryRunner.query(`DROP TYPE "public"."users_gender_enum"`);
    }

}
