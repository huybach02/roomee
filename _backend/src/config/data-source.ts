import "reflect-metadata";
import "dotenv/config";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DataSource } from "typeorm";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const AppDataSource = new DataSource({
  type: "postgres",
  url: process.env.DATABASE_URL,
  synchronize: false,
  logging: process.env.NODE_ENV === "development",
  entities: [path.join(__dirname, "..", "entities/**/*.{ts,js}")],
  migrations: [path.join(__dirname, "..", "migrations/**/*.{ts,js}")],
  subscribers: [],
});
