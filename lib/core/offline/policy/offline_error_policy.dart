import 'package:roomee/core/network/api_exceptions.dart';

abstract interface class OfflineErrorPolicy {
  bool shouldFallback(Object error);
}

class DefaultOfflineErrorPolicy implements OfflineErrorPolicy {
  final bool fallbackOnServerError;

  const DefaultOfflineErrorPolicy({
    this.fallbackOnServerError = true,
  });

  @override
  bool shouldFallback(Object error) {
    if (error is NoInternetException) return true;
    if (error is TimeoutException) return true;
    if (error is ServerException && fallbackOnServerError) {
      final code = error.statusCode;
      if (code == 502 || code == 503 || code == 504) {
        return true;
      }
    }
    return false;
  }
}
