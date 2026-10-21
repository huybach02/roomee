import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import { container } from "tsyringe";
import { AppDataSource } from "./config/data-source.js";
import { closeRedis, redis } from "./config/redis.js";
import { stopCronJobs } from "./cron/index.js";
import { Routes } from "./routes.js";
import { CustomResponse } from "./utils/customResponse.js";
import { i18nMiddleware } from "./middlewares/i18nMiddleware.js";

interface HttpError extends Error {
  status?: number;
}

export class App {
  public app: Application;
  public port: number;

  constructor(port: number = 5000) {
    this.app = express();
    this.port = port;

    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  private initializeMiddlewares(): void {
    this.app.use(cors());
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
    this.app.use(i18nMiddleware);

    // Request logger for development
    if (process.env.NODE_ENV !== "production") {
      this.app.use((req: Request, res: Response, next: NextFunction) => {
        console.log(
          `[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`
        );
        next();
      });
    }
  }

  private initializeRoutes(): void {
    // Root route
    this.app.get("/", (req: Request, res: Response) => {
      res.json({
        message: "Roomee Backend Server is running",
        apiDocs: "/api",
        health: "/api/health",
      });
    });

    // Health check route
    this.app.get("/api/health", (req: Request, res: Response) => {
      res.json({
        status: "UP",
        database: AppDataSource.isInitialized ? "connected" : "disconnected",
        redis: redis.status === "ready" ? "connected" : "disconnected",
        timestamp: new Date().toISOString(),
        uptime: `${Math.floor(process.uptime())}s`,
      });
    });

    // API routes
    container.resolve(Routes).register(this.app);

    // 404 Handler
    this.app.use((req: Request, res: Response) => {
      CustomResponse.error(
        res,
        t("common.notFound", { path: req.originalUrl }),
        null,
        404,
      );
    });
  }

  private initializeErrorHandling(): void {
    // Global Error Handler
    this.app.use(
      (err: HttpError, req: Request, res: Response, next: NextFunction) => {
        console.error("Unhandled Error:", err);
        CustomResponse.error(
          res,
          err.message || t("common.internalServerError"),
          (err as any).errors ?? null,
          err.status || 500
        );
      }
    );
  }

  public listen(): void {
    const server = this.app.listen(this.port, () => {
      console.log(`🚀 Server is running on http://localhost:${this.port}`);
      console.log(`👉 Health check: http://localhost:${this.port}/api/health`);
    });

    // Graceful shutdown
    const shutdown = async (signal: string) => {
      console.log(`\nReceived ${signal}. Shutting down gracefully...`);
      stopCronJobs();
      if (AppDataSource.isInitialized) {
        await AppDataSource.destroy();
        console.log("Database connection closed.");
      }
      await closeRedis();
      console.log("Redis connection closed.");
      server.close(() => {
        console.log("Server closed successfully.");
        process.exit(0);
      });
    };

    process.on("SIGINT", () => shutdown("SIGINT"));
    process.on("SIGTERM", () => shutdown("SIGTERM"));
  }
}

export default App;
