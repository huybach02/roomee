import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateWorkspaceTable1792817052539 implements MigrationInterface {
    name = 'CreateWorkspaceTable1792817052539'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."workspaces_type_enum" AS ENUM('rented_room', 'apartment/mini_house', 'dormitory')`);
        await queryRunner.query(`CREATE TABLE "workspaces" ("id" SERIAL NOT NULL, "userId" integer NOT NULL, "type" "public"."workspaces_type_enum" NOT NULL DEFAULT 'rented_room', "name" character varying(255) NOT NULL, "area" double precision NOT NULL, "numberOfRooms" integer NOT NULL DEFAULT '0', "provinceId" integer NOT NULL, "wardId" integer NOT NULL, "address" character varying(255) NOT NULL, "description" text, "contactName" character varying(100) NOT NULL, "contactPhone" character varying(20) NOT NULL, "contactZalo" character varying(20), "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "createdBy" integer, "updatedBy" integer, CONSTRAINT "PK_098656ae401f3e1a4586f47fd8e" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_dc53b3d0b16419a8f5f1745840" ON "workspaces"  ("userId") `);
        await queryRunner.query(`ALTER TABLE "workspaces" ADD CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "workspaces" ADD CONSTRAINT "FK_0f2a907774b358bdba8da6ab8e8" FOREIGN KEY ("provinceId") REFERENCES "provinces"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "workspaces" ADD CONSTRAINT "FK_6e42bbbd1061c403c676bf5ac65" FOREIGN KEY ("wardId") REFERENCES "wards"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "workspaces" DROP CONSTRAINT "FK_6e42bbbd1061c403c676bf5ac65"`);
        await queryRunner.query(`ALTER TABLE "workspaces" DROP CONSTRAINT "FK_0f2a907774b358bdba8da6ab8e8"`);
        await queryRunner.query(`ALTER TABLE "workspaces" DROP CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_dc53b3d0b16419a8f5f1745840"`);
        await queryRunner.query(`DROP TABLE "workspaces"`);
        await queryRunner.query(`DROP TYPE "public"."workspaces_type_enum"`);
    }

}
