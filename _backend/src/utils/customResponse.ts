export class CustomResponse {
  public static success(
    res: any,
    data: any,
    message: string = "Success",
    statusCode: number = 200,
  ): void {
    res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  public static error(
    res: any,
    message: string = "Internal Server Error",
    errors: any = null,
    statusCode: number = 500,
  ): void {
    res.status(statusCode).json({
      success: false,
      message,
      errors,
    });
  }
}
