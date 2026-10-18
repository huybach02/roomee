import 'dart:io';
import 'package:dio/dio.dart';
import 'package:roomee/core/localization/app_localizations.dart';

abstract class ApiException implements Exception {
  final String? rawMessage;
  final int? statusCode;
  final dynamic errors;

  const ApiException({
    String? message,
    this.statusCode,
    this.errors,
  }) : rawMessage = message;

  String get defaultMessage => t('errors.unexpected');

  String get message => rawMessage ?? defaultMessage;

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: t('errors.connectionTimeout'),
        );

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        String? message;
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
              message: message,
              statusCode: 401,
              errors: errors,
            );
          case 403:
            return ForbiddenException(
              message: message,
              statusCode: 403,
              errors: errors,
            );
          case 404:
            return NotFoundException(
              message: message,
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
        return UnexpectedException(
          message: t('errors.requestCancelled'),
        );

      case DioExceptionType.badCertificate:
        return UnexpectedException(
          message: t('errors.badCertificate'),
        );

      case DioExceptionType.unknown:
      default:
        if (dioException.error is SocketException) {
          return const NoInternetException();
        }
        return UnexpectedException(
          message: dioException.message,
        );
    }
  }
}

/// Khi không có kết nối Internet hoặc DNS/mạng lỗi (Offline mode trigger)
class NoInternetException extends ApiException {
  const NoInternetException({
    super.message,
    super.statusCode,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.noInternet');
}

/// Khi request bị timeout (connect, send, receive)
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message,
    super.statusCode,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.timeout');
}

/// Lỗi 401 Unauthorized (Token hết hạn hoặc không hợp lệ)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message,
    super.statusCode = 401,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.unauthorized');
}

/// Lỗi 403 Forbidden (Không có quyền truy cập)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message,
    super.statusCode = 403,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.forbidden');
}

/// Lỗi 404 Not Found
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message,
    super.statusCode = 404,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.notFound');
}

/// Lỗi 400 Bad Request / 422 Unprocessable Entity (Validate lỗi)
class ClientException extends ApiException {
  const ClientException({
    super.message,
    super.statusCode = 400,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.badRequest');
}

/// Lỗi 5xx từ máy chủ
class ServerException extends ApiException {
  const ServerException({
    super.message,
    super.statusCode = 500,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.internalServerError');
}

/// Lỗi không xác định khác
class UnexpectedException extends ApiException {
  const UnexpectedException({
    super.message,
    super.statusCode,
    super.errors,
  });

  @override
  String get defaultMessage => t('errors.unexpected');
}
