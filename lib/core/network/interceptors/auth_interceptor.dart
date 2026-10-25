import 'dart:async';
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
  final void Function()? onNetworkError;
  final void Function()? onNetworkRestored;
  final Dio? clientDio;
  final Dio _refreshDio;

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String localeKey = 'app_locale';

  /// Thời gian chờ tối đa khi mất mạng trước khi giải phóng bộ nhớ (10 phút)
  static const Duration inactivityTimeout = Duration(minutes: 10);

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;
  Timer? _inactivityTimer;
  final List<_RetryQueueItem> _retryQueue = [];

  AuthInterceptor({
    FlutterSecureStorage? secureStorage,
    this.onUnauthorized,
    this.onNetworkError,
    this.onNetworkRestored,
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

  /// Kiểm tra có request nào đang bị treo chờ mạng hay không
  bool get hasPendingRequests => _retryQueue.isNotEmpty;

  /// Số lượng request đang chờ trong hàng đợi
  int get pendingCount => _retryQueue.length;

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
    // 1. Chốt chặn vòng lặp vô hạn: Nếu request này đã từng retry rồi mà vẫn 401 -> Dừng ngay
    if (err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    // 2. Bỏ qua nếu không phải lỗi 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;

    // 3. Nếu chính endpoint refresh token trả về 401/403 -> thu hồi và logout ngay
    if (path.contains('/auth/refresh-token')) {
      _cancelInactivityTimer();
      _rejectAndClearQueue(err);
      onUnauthorized?.call();
      return handler.next(err);
    }

    // 4. Nếu request không có Authorization header (ví dụ login sai pass) -> lỗi thông thường
    final authHeader = err.requestOptions.headers['Authorization'] as String?;
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return handler.next(err);
    }

    // 5. Nếu ĐANG có tiến trình refresh token chạy dở từ một request khác:
    // Đợi trực tiếp Completer hoàn tất và dùng token mới để retry ngay mà KHÔNG gọi API thừa
    if (_refreshCompleter != null) {
      _resetInactivityTimer();
      try {
        final newAccessToken = await _refreshCompleter!.future;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final opts = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newAccessToken'
            ..extra['retried'] = true;
          final dioInstance = clientDio ?? _refreshDio;
          final response = await dioInstance.fetch(opts);
          return handler.resolve(response);
        } else {
          // Refresh thất bại (mất mạng / lỗi), đưa vào queue để chờ thử lại
          _retryQueue.add(
            _RetryQueueItem(options: err.requestOptions, handler: handler),
          );
          return;
        }
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.reject(retryErr);
        }
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: retryErr,
          ),
        );
      }
    }

    // 6. Nếu có hàng đợi đang bị treo do mất mạng -> đưa vào hàng đợi chờ
    if (_isRefreshing || _retryQueue.isNotEmpty) {
      _resetInactivityTimer();
      _retryQueue.add(
        _RetryQueueItem(options: err.requestOptions, handler: handler),
      );
      return;
    }

    // 7. Khóa đồng bộ NGAY LẬP TỨC (0ms latency, triệt tiêu hoàn toàn async gap)
    final completer = Completer<String?>();
    _refreshCompleter = completer;
    _isRefreshing = true;
    _resetInactivityTimer();
    _retryQueue.add(
      _RetryQueueItem(options: err.requestOptions, handler: handler),
    );

    try {
      // Kiểm tra Token Staleness: nếu token trong storage đã mới hơn token request đã gửi thì không cần gọi API
      final sent = authHeader.substring(7).trim();
      final current = await _storage.read(key: tokenKey);
      String newAccessToken;

      if (current != null && current.isNotEmpty && current != sent) {
        newAccessToken = current;
      } else {
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
        String? extractedAccessToken;
        String? newRefreshToken;

        if (data is Map<String, dynamic>) {
          final payload = data['data'] as Map<String, dynamic>? ?? data;
          extractedAccessToken =
              payload['accessToken'] as String? ?? payload['token'] as String?;
          newRefreshToken = payload['refreshToken'] as String?;
        }

        if (extractedAccessToken == null || extractedAccessToken.isEmpty) {
          throw const FormatException('Invalid refresh response');
        }

        newAccessToken = extractedAccessToken;

        // Lưu cặp token mới vào Secure Storage
        await _storage.write(key: tokenKey, value: newAccessToken);
        // Chỉ lưu refresh token mới nếu có giá trị và không rỗng (chống ghi đè token cũ khi grace period trả về rỗng)
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _storage.write(key: refreshTokenKey, value: newRefreshToken);
        }
      }

      _cancelInactivityTimer();
      completer.complete(newAccessToken);
      _refreshCompleter = null;

      // Lấy danh sách hàng đợi và giải phóng trạng thái khóa
      final queueToRetry = List<_RetryQueueItem>.from(_retryQueue);
      _retryQueue.clear();
      _isRefreshing = false;

      // Replay lần lượt từng request trong queue theo đúng thứ tự FIFO
      for (final item in queueToRetry) {
        try {
          final options = item.options;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          options.extra['retried'] = true;
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

      onNetworkRestored?.call();
    } catch (refreshErr) {
      _isRefreshing = false;
      completer.complete(null);
      _refreshCompleter = null;

      bool isAuthFailure = false;
      DioException? authException;

      if (refreshErr is DioException) {
        final statusCode = refreshErr.response?.statusCode;
        // Chỉ coi là lỗi danh tính thực sự khi server trả về 401 hoặc 403
        if (statusCode == 401 || statusCode == 403) {
          isAuthFailure = true;
          authException = refreshErr;
        }
      } else if (refreshErr is FormatException) {
        // Không có refresh token trong storage
        isAuthFailure = true;
      }

      if (isAuthFailure) {
        // 1. Lỗi danh tính: Reject toàn bộ và logout ngay
        _cancelInactivityTimer();
        _rejectAndClearQueue(authException ?? err);
        onUnauthorized?.call();
      } else {
        // 2. Lỗi môi trường (mất mạng, timeout, 5xx):
        // TUYỆT ĐỐI KHÔNG gọi onUnauthorized!
        // Giữ nguyên _retryQueue và khởi động Timer 10 phút
        _resetInactivityTimer();
        onNetworkError?.call();
      }
    }
  }

  /// Thử thực hiện lại toàn bộ hàng đợi request đang chờ (gọi khi bấm nút "Thử lại")
  Future<bool> retryPendingQueue() async {
    if (_retryQueue.isEmpty) return true;

    // Reset lại timer 10 phút vì người dùng vừa có tương tác
    _resetInactivityTimer();

    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const FormatException('Missing refresh token');
      }

      final locale = await _storage.read(key: localeKey) ?? 'vi';

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

      await _storage.write(key: tokenKey, value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: refreshTokenKey, value: newRefreshToken);
      }

      _cancelInactivityTimer();

      final queueToRetry = List<_RetryQueueItem>.from(_retryQueue);
      _retryQueue.clear();
      _isRefreshing = false;

      for (final item in queueToRetry) {
        try {
          final options = item.options;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          options.extra['retried'] = true;
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

      onNetworkRestored?.call();
      return true;
    } catch (e) {
      _isRefreshing = false;
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          _cancelInactivityTimer();
          _rejectAndClearQueue(e);
          onUnauthorized?.call();
          return false;
        }
      } else if (e is FormatException) {
        _cancelInactivityTimer();
        _rejectAndClearQueue(
          DioException(
            requestOptions: RequestOptions(path: '/auth/refresh-token'),
            error: e,
          ),
        );
        onUnauthorized?.call();
        return false;
      }
      // Vẫn là lỗi môi trường: giữ nguyên queue
      return false;
    }
  }

  /// Xóa sạch hàng đợi và reject các request (giải phóng bộ nhớ khi quá 10 phút hoặc hủy)
  void clearAndRejectQueue([DioException? error]) {
    _cancelInactivityTimer();
    _isRefreshing = false;
    final queue = List<_RetryQueueItem>.from(_retryQueue);
    _retryQueue.clear();
    final errToPass = error ??
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Request cancelled after inactivity timeout',
          type: DioExceptionType.cancel,
        );
    for (final item in queue) {
      item.handler.reject(errToPass);
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () {
      clearAndRejectQueue(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Network request queue timed out after 10 minutes of inactivity',
          type: DioExceptionType.connectionTimeout,
        ),
      );
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
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
