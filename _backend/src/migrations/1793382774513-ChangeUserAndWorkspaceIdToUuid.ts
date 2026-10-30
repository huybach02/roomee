import { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Chuyển khóa chính users.id / workspaces.id sang UUID và đồng bộ toàn bộ cột
 * tham chiếu tới user id (userId, createdBy, updatedBy, deletedBy).
 *
 * Dữ liệu cũ (nếu có) được ánh xạ tất định qua md5 để giữ nguyên quan hệ khóa ngoại.
 */
export class ChangeUserAndWorkspaceIdToUuid1793382774513
  implements MigrationInterface
{
  name = "ChangeUserAndWorkspaceIdToUuid1793382774513";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    // 1. Bỏ khóa ngoại tham chiếu tới users.id
    await queryRunner.query(
      `ALTER TABLE "workspaces" DROP CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" DROP CONSTRAINT "FK_610102b60fea1455310ccd299de"`,
    );

    // 2. Bỏ khóa chính cũ (integer)
    await queryRunner.query(
      `ALTER TABLE "workspaces" DROP CONSTRAINT "PK_098656ae401f3e1a4586f47fd8e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" DROP CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433"`,
    );

    // 3. Đổi khóa chính sang uuid (ánh xạ tất định để giữ liên kết dữ liệu cũ)
    await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "id" DROP DEFAULT`);
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "id" TYPE uuid USING md5('users:' || "id"::text)::uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "id" SET DEFAULT uuid_generate_v4()`,
    );

    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" DROP DEFAULT`,
    );
    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" TYPE uuid USING md5('workspaces:' || "id"::text)::uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" SET DEFAULT uuid_generate_v4()`,
    );

    // 4. Đổi các cột tham chiếu tới user id
    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "userId" TYPE uuid USING md5('users:' || "userId"::text)::uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ALTER COLUMN "userId" TYPE uuid USING md5('users:' || "userId"::text)::uuid`,
    );

    for (const table of [
      "users",
      "workspaces",
      "refresh_tokens",
      "provinces",
      "wards",
    ]) {
      for (const column of ["createdBy", "updatedBy"]) {
        await queryRunner.query(
          `ALTER TABLE "${table}" ALTER COLUMN "${column}" TYPE uuid USING md5('users:' || "${column}"::text)::uuid`,
        );
      }
    }
    for (const table of ["users", "workspaces"]) {
      await queryRunner.query(
        `ALTER TABLE "${table}" ALTER COLUMN "deletedBy" TYPE uuid USING md5('users:' || "deletedBy"::text)::uuid`,
      );
    }

    // 5. Tạo lại khóa chính
    await queryRunner.query(
      `ALTER TABLE "users" ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "workspaces" ADD CONSTRAINT "PK_098656ae401f3e1a4586f47fd8e" PRIMARY KEY ("id")`,
    );

    // 6. Tạo lại khóa ngoại
    await queryRunner.query(
      `ALTER TABLE "workspaces" ADD CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD CONSTRAINT "FK_610102b60fea1455310ccd299de" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "workspaces" DROP CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" DROP CONSTRAINT "FK_610102b60fea1455310ccd299de"`,
    );

    await queryRunner.query(
      `ALTER TABLE "workspaces" DROP CONSTRAINT "PK_098656ae401f3e1a4586f47fd8e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" DROP CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433"`,
    );

    // Chuyển ngược uuid -> integer (không khôi phục được giá trị gốc, chỉ đảm bảo hợp lệ)
    const toInt = (column: string) =>
      `('x' || substr(replace("${column}"::text, '-', ''), 1, 8))::bit(32)::int`;

    for (const table of [
      "users",
      "workspaces",
      "refresh_tokens",
      "provinces",
      "wards",
    ]) {
      for (const column of ["createdBy", "updatedBy"]) {
        await queryRunner.query(
          `ALTER TABLE "${table}" ALTER COLUMN "${column}" TYPE integer USING ${toInt(column)}`,
        );
      }
    }
    for (const table of ["users", "workspaces"]) {
      await queryRunner.query(
        `ALTER TABLE "${table}" ALTER COLUMN "deletedBy" TYPE integer USING ${toInt("deletedBy")}`,
      );
    }

    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "userId" TYPE integer USING ${toInt("userId")}`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ALTER COLUMN "userId" TYPE integer USING ${toInt("userId")}`,
    );

    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" DROP DEFAULT`,
    );
    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" TYPE integer USING ${toInt("id")}`,
    );
    await queryRunner.query(`CREATE SEQUENCE IF NOT EXISTS "workspaces_id_seq"`);
    await queryRunner.query(
      `ALTER TABLE "workspaces" ALTER COLUMN "id" SET DEFAULT nextval('workspaces_id_seq')`,
    );
    await queryRunner.query(
      `SELECT setval('workspaces_id_seq', COALESCE((SELECT MAX("id") FROM "workspaces"), 0) + 1, false)`,
    );

    await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "id" DROP DEFAULT`);
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "id" TYPE integer USING ${toInt("id")}`,
    );
    await queryRunner.query(`CREATE SEQUENCE IF NOT EXISTS "users_id_seq"`);
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "id" SET DEFAULT nextval('users_id_seq')`,
    );
    await queryRunner.query(
      `SELECT setval('users_id_seq', COALESCE((SELECT MAX("id") FROM "users"), 0) + 1, false)`,
    );

    await queryRunner.query(
      `ALTER TABLE "users" ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "workspaces" ADD CONSTRAINT "PK_098656ae401f3e1a4586f47fd8e" PRIMARY KEY ("id")`,
    );

    await queryRunner.query(
      `ALTER TABLE "workspaces" ADD CONSTRAINT "FK_dc53b3d0b16419a8f5f17458403" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD CONSTRAINT "FK_610102b60fea1455310ccd299de" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }
}
