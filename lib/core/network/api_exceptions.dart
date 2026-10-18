import 'dart:io';
import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Hết thời gian chờ kết nối. Vui lòng kiểm tra lại đường truyền mạng.',
        );

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        String message = 'Đã có lỗi xảy ra từ máy chủ.';
        dynamic errors;

        if (response?.data is Map<String, dynamic>) {
          final data = response!.data as Map<String, dynamic>;
          if (data['message'] is String && (data['message'] as String).isNotEmpty) {
            message = data['message'] as String;
          }
          errors = data['errors'];
        } else if (response?.statusMessage != null && response!.statusMessage!.isNotEmpty) {
          message = response.statusMessage!;
        }

        switch (statusCode) {
          case 400:
          case 422:
            return ClientException(
              message: message,
              statusCode: statusCode,
              errors: errors,
            );
          case 401:
            return UnauthorizedException(
              message: message.isNotEmpty
                  ? message
                  : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              statusCode: 401,
              errors: errors,
            );
          case 403:
            return ForbiddenException(
              message: message.isNotEmpty
                  ? message
                  : 'Bạn không có quyền thực hiện thao tác này.',
              statusCode: 403,
              errors: errors,
            );
          case 404:
            return NotFoundException(
              message: message.isNotEmpty ? message : 'Không tìm thấy tài nguyên yêu cầu.',
              statusCode: 404,
              errors: errors,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              message: message,
              statusCode: statusCode,
              errors: errors,
            );
          default:
            return ClientException(
              message: message,
              statusCode: statusCode ?? 400,
              errors: errors,
            );
        }

      case DioExceptionType.cancel:
        return const UnexpectedException(
          message: 'Yêu cầu tới máy chủ đã bị hủy.',
        );

      case DioExceptionType.badCertificate:
        return const UnexpectedException(
          message: 'Chứng chỉ bảo mật máy chủ không hợp lệ.',
        );

      case DioExceptionType.unknown:
      default:
        if (dioException.error is SocketException) {
          return const NoInternetException();
        }
        return UnexpectedException(
          message: dioException.message ?? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        );
    }
  }
}

/// Khi không có kết nối Internet hoặc DNS/mạng lỗi (Offline mode trigger)
class NoInternetException extends ApiException {
  const NoInternetException({
    super.message = 'Không có kết nối Internet. Vui lòng kiểm tra lại mạng.',
    super.statusCode,
    super.errors,
  });
}

/// Khi request bị timeout (connect, send, receive)
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Hết thời gian chờ kết nối. Vui lòng thử lại.',
    super.statusCode,
    super.errors,
  });
}

/// Lỗi 401 Unauthorized (Token hết hạn hoặc không hợp lệ)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    super.statusCode = 401,
    super.errors,
  });
}

/// Lỗi 403 Forbidden (Không có quyền truy cập)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Bạn không có quyền thực hiện thao tác này.',
    super.statusCode = 403,
    super.errors,
  });
}

/// Lỗi 404 Not Found
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Không tìm thấy tài nguyên yêu cầu.',
    super.statusCode = 404,
    super.errors,
  });
}

/// Lỗi 400 Bad Request / 422 Unprocessable Entity (Validate lỗi)
class ClientException extends ApiException {
  const ClientException({
    required super.message,
    super.statusCode = 400,
    super.errors,
  });
}

/// Lỗi 5xx từ máy chủ
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
    super.statusCode = 500,
    super.errors,
  });
}

/// Lỗi không xác định khác
class UnexpectedException extends ApiException {
  const UnexpectedException({
    super.message = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
    super.statusCode,
    super.errors,
  });
}
