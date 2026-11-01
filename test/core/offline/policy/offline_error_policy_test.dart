import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/offline/policy/offline_error_policy.dart';

void main() {
  group('DefaultOfflineErrorPolicy', () {
    const policy = DefaultOfflineErrorPolicy();

    test('shouldFallback returns true for NoInternetException and TimeoutException', () {
      expect(policy.shouldFallback(const NoInternetException()), isTrue);
      expect(policy.shouldFallback(const TimeoutException()), isTrue);
    });

    test('shouldFallback returns true for ServerException 502, 503, 504 by default', () {
      expect(policy.shouldFallback(const ServerException(statusCode: 502)), isTrue);
      expect(policy.shouldFallback(const ServerException(statusCode: 503)), isTrue);
      expect(policy.shouldFallback(const ServerException(statusCode: 504)), isTrue);
      // 500 is internal server error, not temporarily unavailable
      expect(policy.shouldFallback(const ServerException(statusCode: 500)), isFalse);
    });

    test('shouldFallback returns false for 401, 403, 400, 404, FormatException', () {
      expect(policy.shouldFallback(const UnauthorizedException()), isFalse);
      expect(policy.shouldFallback(const ForbiddenException()), isFalse);
      expect(policy.shouldFallback(const ClientException(statusCode: 400)), isFalse);
      expect(policy.shouldFallback(const NotFoundException(statusCode: 404)), isFalse);
      expect(policy.shouldFallback(const FormatException('bad json')), isFalse);
    });
  });
}
