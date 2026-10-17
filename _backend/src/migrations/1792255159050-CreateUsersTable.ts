import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateUsersTable1792255159050 implements MigrationInterface {
    name = 'CreateUsersTable1792255159050'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."users_gender_enum" AS ENUM('male', 'female', 'other')`);
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum" AS ENUM('landlord', 'staff', 'tenant', 'admin')`);
        await queryRunner.query(`CREATE TABLE "users" ("createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "createdBy" integer, "updatedBy" integer, "id" SERIAL NOT NULL, "email" character varying(255) NOT NULL, "password" character varying(255) NOT NULL, "fullName" character varying(100), "phoneNumber" character varying(20), "avatarUrl" character varying(255), "bio" text, "gender" "public"."users_gender_enum" NOT NULL DEFAULT 'male', "role" "public"."users_role_enum" NOT NULL DEFAULT 'tenant', "isActive" boolean NOT NULL DEFAULT true, "language" character varying(100) DEFAULT 'vi', CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "users"`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
        await queryRunner.query(`DROP TYPE "public"."users_gender_enum"`);
    }

}
