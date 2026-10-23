import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roomee/core/network/interceptors/auth_interceptor.dart';
import 'package:roomee/core/network/interceptors/logging_interceptor.dart';
import 'package:roomee/utils/constanst.dart';

class ApiClient {
  static ApiClient? _instance;
  final Dio _dio;
  late final AuthInterceptor? _authInterceptor;

  ApiClient._internal({
    Dio? dio,
    String? baseUrl,
    FlutterSecureStorage? secureStorage,
    void Function()? onUnauthorized,
    void Function()? onNetworkError,
    void Function()? onNetworkRestored,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    if (dio == null) {
      final authInterceptor = AuthInterceptor(
        secureStorage: secureStorage,
        onUnauthorized: onUnauthorized,
        onNetworkError: onNetworkError,
        onNetworkRestored: onNetworkRestored,
        clientDio: _dio,
        baseUrl: baseUrl ?? apiBaseUrl,
      );
      _authInterceptor = authInterceptor;
      _dio.interceptors.addAll([
        authInterceptor,
        LoggingInterceptor(),
      ]);
    } else {
      _authInterceptor = null;
    }
  }

  /// Singleton instance cho toàn app
  factory ApiClient({
    Dio? dio,
    String? baseUrl,
    FlutterSecureStorage? secureStorage,
    void Function()? onUnauthorized,
    void Function()? onNetworkError,
    void Function()? onNetworkRestored,
  }) {
    if (dio != null ||
        baseUrl != null ||
        secureStorage != null ||
        onUnauthorized != null ||
        onNetworkError != null ||
        onNetworkRestored != null) {
      _instance = ApiClient._internal(
        dio: dio,
        baseUrl: baseUrl,
        secureStorage: secureStorage,
        onUnauthorized: onUnauthorized,
        onNetworkError: onNetworkError,
        onNetworkRestored: onNetworkRestored,
      );
      return _instance!;
    }
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Reset singleton instance (hỗ trợ test)
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  /// Instance getter tiện lợi
  static ApiClient get instance => ApiClient();

  /// Truy cập AuthInterceptor
  AuthInterceptor? get authInterceptor => _authInterceptor;

  /// Truy cập Dio gốc khi cần các tính năng đặc thù (download file, upload progress...)
  Dio get dio => _dio;

  /// Hook mở rộng: Thêm interceptor (chuẩn bị cho cache/offline mode sau này)
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}
