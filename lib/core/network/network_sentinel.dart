import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:roomee/core/network/api_client.dart';

enum NetworkStatus {
  online,
  offline,
}

/// Lính canh mạng trung tâm (Network Sentinel) của ứng dụng Mobile.
///
/// Sử dụng [connectivity_plus] để bắt sự kiện kết nối mạng theo thời gian thực.
/// Khi phát hiện mạng hồi phục (chuyển từ offline sang online), tự động kích hoạt
/// các callback đồng bộ dữ liệu (2-Way Sync) và cập nhật trạng thái mạng cho toàn ứng dụng.
class NetworkSentinel {
  static NetworkSentinel? _instance;

  final Connectivity _connectivity;
  final ValueNotifier<NetworkStatus> statusNotifier;
  final Set<Future<void> Function()> _syncCallbacks = {};

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  DateTime? _lastSyncTriggeredAt;
  Duration syncCooldown;

  NetworkSentinel({
    Connectivity? connectivity,
    ApiClient? apiClient,
    NetworkStatus initialStatus = NetworkStatus.online,
    this.syncCooldown = const Duration(seconds: 5),
  })  : _connectivity = connectivity ?? Connectivity(),
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
    final isDeviceConnected = results.any((r) => r != ConnectivityResult.none);
    final newStatus =
        isDeviceConnected ? NetworkStatus.online : NetworkStatus.offline;

    final wasOffline = status == NetworkStatus.offline;
    statusNotifier.value = newStatus;

    // Khi mạng hồi phục từ offline -> online: tự động kích hoạt 2-way sync
    if (wasOffline && newStatus == NetworkStatus.online) {
      _triggerSyncCallbacks();
    }
  }

  /// Kiểm tra trạng thái mạng hiện tại từ connectivity
  Future<NetworkStatus> checkStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isDeviceConnected =
          results.any((r) => r != ConnectivityResult.none);
      final newStatus =
          isDeviceConnected ? NetworkStatus.online : NetworkStatus.offline;

      final wasOffline = status == NetworkStatus.offline;
      statusNotifier.value = newStatus;

      if (wasOffline && newStatus == NetworkStatus.online) {
        _triggerSyncCallbacks();
      }

      return newStatus;
    } catch (_) {
      return status;
    }
  }

  /// Kích hoạt các tác vụ sync khi mạng hồi phục (kèm cooldown chống bão gọi)
  void _triggerSyncCallbacks() {
    final now = DateTime.now();
    if (_lastSyncTriggeredAt != null &&
        now.difference(_lastSyncTriggeredAt!) < syncCooldown) {
      return;
    }
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
    statusNotifier.dispose();
    _syncCallbacks.clear();
  }
}
