import "reflect-metadata";
import "dotenv/config";
import App from "./app.js";
import { AppDataSource } from "./config/data-source.js";
import { connectRedis } from "./config/redis.js";
import { startCronJobs } from "./cron/index.js";
import { DEFAULT_PORT } from "./utils/constanst.js";

const PORT = Number(process.env.PORT) || DEFAULT_PORT;

async function bootstrap() {
  try {
    console.log("⏳ Initializing TypeORM database connection...");
    await AppDataSource.initialize();
    console.log("📦 Connected to PostgreSQL database via TypeORM successfully");

    console.log("⏳ Connecting to Redis...");
    await connectRedis();
    console.log("🧠 Connected to Redis successfully");

    startCronJobs();

    const server = new App(PORT);
    server.listen();
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
}

bootstrap();
