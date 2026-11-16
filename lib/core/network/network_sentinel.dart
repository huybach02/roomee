import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:roomee/utils/constanst.dart';

enum NetworkStatus {
  online,
  offline,
}

enum ProbeResult {
  online,
  offline,
  timeout,
}

/// Lính canh mạng trung tâm (Network Sentinel) của ứng dụng Mobile.
///
/// Sử dụng [connectivity_plus] để bắt sự kiện kết nối mạng theo thời gian thực,
/// sau đó xác nhận lại bằng health check `/api/health` vì interface mạng (WiFi/4G)
/// chưa chắc đã ra được Internet thật (captive portal, router mất uplink, hết data...).
/// Khi phát hiện mạng hồi phục (chuyển từ offline sang online), tự động kích hoạt
/// các callback đồng bộ dữ liệu (2-Way Sync) và cập nhật trạng thái mạng cho toàn ứng dụng.
class NetworkSentinel {
  static NetworkSentinel? _instance;

  final Connectivity _connectivity;
  final ValueNotifier<NetworkStatus> statusNotifier;
  final Set<Future<void> Function()> _syncCallbacks = {};

  /// Dio riêng cho health check, KHÔNG gắn AuthInterceptor/LoggingInterceptor
  /// để probe không đụng tới luồng refresh token hay gửi kèm access token.
  late final Dio _probeDio;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  DateTime? _lastSyncTriggeredAt;
  Duration syncCooldown;
  Duration probeTimeout;
  final String fallbackUrl;

  /// Tăng mỗi lần xử lý sự kiện mạng để bỏ qua kết quả probe cũ về muộn
  int _statusSeq = 0;

  NetworkSentinel({
    Connectivity? connectivity,
    Dio? probeDio,
    NetworkStatus initialStatus = NetworkStatus.online,
    this.syncCooldown = const Duration(seconds: 5),
    this.probeTimeout = const Duration(seconds: 4),
    this.fallbackUrl = 'https://www.google.com',
  })  : _connectivity = connectivity ?? Connectivity(),
        _probeDio = probeDio ??
            Dio(
              BaseOptions(
                baseUrl: apiBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        statusNotifier = ValueNotifier<NetworkStatus>(initialStatus);

  /// Singleton instance cho toàn app
  static NetworkSentinel get instance => _instance ??= NetworkSentinel();

  /// Hỗ trợ reset singleton phục vụ testing
  @visibleForTesting
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  /// Trạng thái mạng hiện tại
  NetworkStatus get status => statusNotifier.value;
  bool get isOnline => status == NetworkStatus.online;

  /// Khởi động lính canh theo dõi mạng nền
  void initialize() {
    _subscription?.cancel();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChanged);

    // Kiểm tra trạng thái mạng ban đầu
    unawaited(checkStatus());
  }

  /// Đăng ký callback đồng bộ khi mạng hồi phục
  void registerSyncCallback(Future<void> Function() callback) {
    _syncCallbacks.add(callback);
  }

  /// Hủy đăng ký callback
  void unregisterSyncCallback(Future<void> Function() callback) {
    _syncCallbacks.remove(callback);
  }

  Future<void> _handleConnectivityChanged(
      List<ConnectivityResult> results) async {
    final seq = ++_statusSeq;
    await _applyConnectivity(results, seq);
  }

  /// Kiểm tra trạng thái mạng hiện tại từ connectivity
  Future<NetworkStatus> checkStatus() async {
    final seq = ++_statusSeq;
    try {
      final results = await _connectivity.checkConnectivity();
      return await _applyConnectivity(results, seq);
    } catch (_) {
      return status;
    }
  }

  /// Áp dụng kết quả connectivity, có xác nhận Internet thật bằng health check
  Future<NetworkStatus> _applyConnectivity(
    List<ConnectivityResult> results,
    int seq,
  ) async {
    // Đã có sự kiện mạng mới hơn được xử lý trong lúc chờ -> bỏ qua kết quả cũ
    if (seq != _statusSeq) return status;

    final hasInterface = results.any((r) => r != ConnectivityResult.none);

    // Không có interface mạng -> offline ngay, không cần probe
    if (!hasInterface) {
      _updateStatus(NetworkStatus.offline);
      return status;
    }

    // Có interface chưa chắc ra được Internet -> xác nhận bằng probe
    final probeResult = await _probeInternet();

    // Một sự kiện mạng mới hơn đã được xử lý trong lúc probe -> bỏ qua kết quả cũ
    if (seq != _statusSeq) return status;

    if (probeResult == ProbeResult.online) {
      _updateStatus(NetworkStatus.online);
    } else if (probeResult == ProbeResult.offline) {
      _updateStatus(NetworkStatus.offline);
    }
    // Nếu probeResult == ProbeResult.timeout: coi là "chưa biết", giữ nguyên trạng thái
    // hiện tại, không vội vàng phán đoán offline làm giật UI banner.

    return status;
  }

  /// Ping endpoint health check của server để xác nhận kết nối Internet thực tế.
  ///
  /// 1. Gọi /api/health của máy chủ Roomee. Bất kỳ HTTP response nào cũng chứng minh
  ///    đã kết nối được tới server và Internet.
  /// 2. Nếu server Roomee bị lỗi mạng (server tắt/bảo trì, connection refused, DNS lỗi),
  ///    fallback ping tới [fallbackUrl] (mặc định https://www.google.com) để xác nhận
  ///    thiết bị có thực sự ra Internet hay không (tránh coi server lỗi thành mất mạng).
  /// 3. Nếu cả hai đều timeout (probeTimeout hết hạn), coi là [ProbeResult.timeout]
  ///    ("chưa biết") chứ chưa hẳn offline để tránh vội vã chuyển trạng thái giật lag UI banner.
  Future<ProbeResult> _probeInternet() async {
    bool healthTimedOut = false;

    try {
      final healthUrl = Uri.parse(_probeDio.options.baseUrl)
          .replace(path: '/api/health')
          .toString();
      await _probeDio.get(
        healthUrl,
        options: Options(
          sendTimeout: probeTimeout,
          receiveTimeout: probeTimeout,
          // Không throw với mã lỗi HTTP: server có phản hồi tức là có Internet
          validateStatus: (_) => true,
        ),
      );
      return ProbeResult.online;
    } on DioException catch (e) {
      // Có response nghĩa là request đã tới được server -> Internet vẫn hoạt động
      if (e.response != null) {
        return ProbeResult.online;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        healthTimedOut = true;
      }
    } catch (_) {}

    // Fallback: Ping fallbackUrl (mặc định https://www.google.com)
    try {
      await _probeDio.get(
        fallbackUrl,
        options: Options(
          sendTimeout: probeTimeout,
          receiveTimeout: probeTimeout,
          validateStatus: (_) => true,
        ),
      );
      return ProbeResult.online;
    } on DioException catch (e) {
      if (e.response != null) {
        return ProbeResult.online;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ProbeResult.timeout;
      }
    } catch (_) {}

    if (healthTimedOut) {
      return ProbeResult.timeout;
    }

    return ProbeResult.offline;
  }

  /// Kích hoạt chuông đồng bộ chủ động cho tất cả repository đã đăng ký
  /// (ví dụ: sau khi người dùng đăng nhập xong hoặc app khởi động có sẵn sóng và còn phiếu)
  void triggerSync({bool force = false}) {
    if (force) {
      _lastSyncTriggeredAt = null;
    }
    if (isOnline) {
      _triggerSyncCallbacks();
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    final wasOffline = status == NetworkStatus.offline;
    statusNotifier.value = newStatus;

    // Khi mạng hồi phục từ offline -> online: tự động kích hoạt 2-way sync
    if (wasOffline && newStatus == NetworkStatus.online) {
      _triggerSyncCallbacks();
    }
  }

  Timer? _pendingSyncTimer;

  /// Kích hoạt các tác vụ sync khi mạng hồi phục (kèm cooldown chống bão gọi)
  void _triggerSyncCallbacks() {
    final now = DateTime.now();
    if (_lastSyncTriggeredAt != null &&
        syncCooldown > Duration.zero &&
        now.difference(_lastSyncTriggeredAt!) < syncCooldown) {
      final remaining = syncCooldown - now.difference(_lastSyncTriggeredAt!);
      _pendingSyncTimer ??= Timer(remaining, () {
        _pendingSyncTimer = null;
        if (status == NetworkStatus.online) {
          _triggerSyncCallbacks();
        }
      });
      return;
    }
    _pendingSyncTimer?.cancel();
    _pendingSyncTimer = null;
    _lastSyncTriggeredAt = now;

    for (final callback in List.of(_syncCallbacks)) {
      unawaited(
        callback().catchError((e, s) {
          debugPrint('[NetworkSentinel] Sync callback error: $e\n$s');
        }),
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _pendingSyncTimer?.cancel();
    _pendingSyncTimer = null;
    _probeDio.close(force: true);
    statusNotifier.dispose();
    _syncCallbacks.clear();
  }
}
