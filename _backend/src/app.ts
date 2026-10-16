import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";

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
        timestamp: new Date().toISOString(),
        uptime: `${Math.floor(process.uptime())}s`,
      });
    });

    // 404 Handler
    this.app.use((req: Request, res: Response) => {
      res.status(404).json({
        success: false,
        message: `Not Found - ${req.originalUrl}`,
      });
    });
  }

  private initializeErrorHandling(): void {
    // Global Error Handler
    this.app.use(
      (err: HttpError, req: Request, res: Response, next: NextFunction) => {
        console.error("Unhandled Error:", err);
        res.status(err.status || 500).json({
          success: false,
          message: err.message || "Internal Server Error",
        });
      }
    );
  }

  public listen(): void {
    const server = this.app.listen(this.port, () => {
      console.log(`🚀 Server is running on http://localhost:${this.port}`);
      console.log(`👉 Health check: http://localhost:${this.port}/api/health`);
    });

    // Graceful shutdown
    const shutdown = (signal: string) => {
      console.log(`\nReceived ${signal}. Shutting down gracefully...`);
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
