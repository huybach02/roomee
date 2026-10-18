import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final void Function()? onUnauthorized;

  static const String tokenKey = 'access_token';
  static const String localeKey = 'app_locale';

  AuthInterceptor({
    FlutterSecureStorage? secureStorage,
    this.onUnauthorized,
  }) : _storage = secureStorage ?? const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Đính kèm token nếu có trong secure storage
      final token = await _storage.read(key: tokenKey);
      if (token != null && token.isNotEmpty) {
        if (!options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Đính kèm Accept-Language đồng bộ với backend i18n
      final locale = await _storage.read(key: localeKey) ?? 'vi';
      if (!options.headers.containsKey('Accept-Language')) {
        options.headers['Accept-Language'] = locale;
      }
    } catch (_) {
      // Bỏ qua lỗi đọc storage nếu có để không chặn request
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
