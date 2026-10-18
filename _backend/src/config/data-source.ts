import "reflect-metadata";
import "dotenv/config";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DataSource } from "typeorm";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class CustomDataSource extends DataSource {
  async buildMetadatas(): Promise<void> {
    await super.buildMetadatas();
    const auditProps = ["createdAt", "updatedAt", "createdBy", "updatedBy"];

    for (const meta of this.entityMetadatas) {
      const sortFn = (
        a: { propertyName: string; isPrimary: boolean },
        b: { propertyName: string; isPrimary: boolean }
      ) => {
        const aIsAudit = auditProps.includes(a.propertyName);
        const bIsAudit = auditProps.includes(b.propertyName);

        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        if (aIsAudit && !bIsAudit) return 1;
        if (!aIsAudit && bIsAudit) return -1;
        return 0;
      };

      meta.columns.sort(sortFn);
      if (meta.ownColumns) {
        meta.ownColumns.sort(sortFn);
      }
    }
  }
}

export const AppDataSource = new CustomDataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: false,
  logging: process.env.NODE_ENV === "development" ? ["error"] : false,
  entities: [path.join(__dirname, "..", "entities/**/*.{ts,js}")],
  migrations: [path.join(__dirname, "..", "migrations/**/*.{ts,js}")],
  subscribers: [],
});
