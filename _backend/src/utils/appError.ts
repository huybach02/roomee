export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly errors: any;

  constructor(message: string, statusCode: number = 400, errors: any = null) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
    this.isOperational = true;
    this.errors = errors;

    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace?.(this, this.constructor);
  }

  public static badRequest(message: string, errors: any = null): AppError {
    return new AppError(message, 400, errors);
  }

  public static unauthorized(message: string, errors: any = null): AppError {
    return new AppError(message, 401, errors);
  }

  public static forbidden(message: string, errors: any = null): AppError {
    return new AppError(message, 403, errors);
  }

  public static notFound(message: string, errors: any = null): AppError {
    return new AppError(message, 404, errors);
  }

  public static conflict(message: string, errors: any = null): AppError {
    return new AppError(message, 409, errors);
  }

  public static locked(message: string, errors: any = null): AppError {
    return new AppError(message, 423, errors);
  }

  public static tooManyRequests(message: string, errors: any = null): AppError {
    return new AppError(message, 429, errors);
  }

  public static internal(message: string, errors: any = null): AppError {
    return new AppError(message, 500, errors);
  }
}
