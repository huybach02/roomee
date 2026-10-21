import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roomee/utils/constanst.dart';

class _RetryQueueItem {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RetryQueueItem({
    required this.options,
    required this.handler,
  });
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final void Function()? onUnauthorized;
  final Dio? clientDio;
  final Dio _refreshDio;

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String localeKey = 'app_locale';

  bool _isRefreshing = false;
  final List<_RetryQueueItem> _retryQueue = [];

  AuthInterceptor({
    FlutterSecureStorage? secureStorage,
    this.onUnauthorized,
    this.clientDio,
    Dio? refreshDio,
    String? baseUrl,
  })  : _storage = secureStorage ?? const FlutterSecureStorage(),
        _refreshDio = refreshDio ??
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
            );

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Bỏ qua nếu không phải lỗi 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;

    // 2. Nếu chính endpoint refresh token trả về 401 -> thu hồi và logout ngay
    if (path.contains('/auth/refresh-token')) {
      _rejectAndClearQueue(err);
      onUnauthorized?.call();
      return handler.next(err);
    }

    // 3. Nếu request không có Authorization header (ví dụ login sai pass) -> lỗi thông thường
    final authHeader = err.requestOptions.headers['Authorization'] as String?;
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return handler.next(err);
    }

    // 4. Nếu đã có 1 request đang thực hiện refresh ngầm -> đưa vào hàng đợi chờ
    if (_isRefreshing) {
      _retryQueue.add(
        _RetryQueueItem(options: err.requestOptions, handler: handler),
      );
      return;
    }

    // 5. Bắt đầu tiến trình refresh ngầm (chỉ 1 request đầu tiên được thực hiện)
    _isRefreshing = true;
    _retryQueue.add(
      _RetryQueueItem(options: err.requestOptions, handler: handler),
    );

    try {
      final refreshToken = await _storage.read(key: refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const FormatException('Missing refresh token');
      }

      final locale = await _storage.read(key: localeKey) ?? 'vi';

      // Gọi endpoint refresh token qua _refreshDio độc lập (chống đệ quy vô hạn)
      final response = await _refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Accept-Language': locale,
          },
        ),
      );

      final data = response.data;
      String? newAccessToken;
      String? newRefreshToken;

      if (data is Map<String, dynamic>) {
        final payload = data['data'] as Map<String, dynamic>? ?? data;
        newAccessToken =
            payload['accessToken'] as String? ?? payload['token'] as String?;
        newRefreshToken = payload['refreshToken'] as String?;
      }

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw const FormatException('Invalid refresh response');
      }

      // Lưu cặp token mới vào Secure Storage
      await _storage.write(key: tokenKey, value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: refreshTokenKey, value: newRefreshToken);
      }

      // Lấy danh sách hàng đợi và giải phóng trạng thái khóa
      final queueToRetry = List<_RetryQueueItem>.from(_retryQueue);
      _retryQueue.clear();
      _isRefreshing = false;

      // Replay lần lượt từng request trong queue theo đúng thứ tự FIFO
      for (final item in queueToRetry) {
        try {
          final options = item.options;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          final dioInstance = clientDio ?? _refreshDio;
          final retryResponse = await dioInstance.fetch(options);
          item.handler.resolve(retryResponse);
        } catch (retryErr) {
          if (retryErr is DioException) {
            item.handler.reject(retryErr);
          } else {
            item.handler.reject(
              DioException(
                requestOptions: item.options,
                error: retryErr,
              ),
            );
          }
        }
      }
    } catch (refreshErr) {
      _isRefreshing = false;
      final queueToReject = List<_RetryQueueItem>.from(_retryQueue);
      _retryQueue.clear();

      for (final item in queueToReject) {
        item.handler.reject(err);
      }

      onUnauthorized?.call();
    }
  }

  void _rejectAndClearQueue(DioException err) {
    _isRefreshing = false;
    final queue = List<_RetryQueueItem>.from(_retryQueue);
    _retryQueue.clear();
    for (final item in queue) {
      item.handler.reject(err);
    }
  }
}
