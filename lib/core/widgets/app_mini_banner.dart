import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/utils/function_helper.dart';

enum AppMiniBannerType { info, warning, success, error, syncing }

class AppMiniBanner extends StatelessWidget {
  final String text;
  final AppMiniBannerType type;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppMiniBanner({
    super.key,
    required this.text,
    this.type = AppMiniBannerType.info,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// Banner dạng đang đồng bộ (Syncing)
  factory AppMiniBanner.syncing({String? message}) {
    return AppMiniBanner(
      text: message ?? t('common.syncingData'),
      type: AppMiniBannerType.syncing,
    );
  }

  /// Banner dạng thành công (Success)
  factory AppMiniBanner.success({required String message}) {
    return AppMiniBanner(text: message, type: AppMiniBannerType.success);
  }

  /// Banner dạng ngoại tuyến (Offline)
  factory AppMiniBanner.offline({DateTime? lastFetchedAt, String? message}) {
    String text = message ?? t('common.offlineModeNotice');
    if (lastFetchedAt != null) {
      final timeStr = FunctionHelper.formatDateTime(
        lastFetchedAt,
        pattern: 'HH:mm dd/MM',
      );
      text = '$text (${t('common.lastUpdated', {'time': timeStr})})';
    }
    return AppMiniBanner(
      text: text,
      type: AppMiniBannerType.warning,
      leading: const Icon(
        Icons.wifi_off_rounded,
        size: 16,
        color: DefaultColors.secondary,
      ),
    );
  }

  /// Banner cảnh báo (Warning)
  factory AppMiniBanner.warning({
    required String message,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppMiniBanner(
      text: message,
      type: AppMiniBannerType.warning,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Banner thông tin (Info)
  factory AppMiniBanner.info({
    required String message,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppMiniBanner(
      text: message,
      type: AppMiniBannerType.info,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Banner lỗi (Error)
  factory AppMiniBanner.error({
    required String message,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AppMiniBanner(
      text: message,
      type: AppMiniBannerType.error,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Widget thông minh tự động điều phối trạng thái Sync (Syncing, Success 1.5s, Offline)
  static Widget syncStatus({
    Key? key,
    bool isSyncing = false,
    ValueListenable<bool>? isSyncingListenable,
    ValueListenable<bool?>? syncSuccessListenable,
    bool isOffline = false,
    ValueListenable<NetworkStatus>? networkStatusListenable,
    DateTime? lastFetchedAt,
    String? offlineMessage,
    String? syncingMessage,
  }) {
    return _AppSyncStatusMiniBanner(
      key: key,
      isSyncing: isSyncing,
      isSyncingListenable: isSyncingListenable,
      syncSuccessListenable: syncSuccessListenable,
      isOffline: isOffline,
      networkStatusListenable:
          networkStatusListenable ?? NetworkSentinel.instance.statusNotifier,
      lastFetchedAt: lastFetchedAt,
      offlineMessage: offlineMessage,
      syncingMessage: syncingMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final defaultLeading = _getDefaultLeading();

    Widget child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading ?? defaultLeading,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: FontSizes.small,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );

    if (onTap != null) {
      child = InkWell(onTap: onTap, child: child);
    }

    return child;
  }

  ({Color background, Color border, Color text}) _getColors() {
    switch (type) {
      case AppMiniBannerType.syncing:
      case AppMiniBannerType.info:
        return (
          background: DefaultColors.primary.withValues(alpha: 0.08),
          border: DefaultColors.primary.withValues(alpha: 0.25),
          text: DefaultColors.primary,
        );
      case AppMiniBannerType.warning:
        return (
          background: DefaultColors.secondary.withValues(alpha: 0.12),
          border: DefaultColors.secondary.withValues(alpha: 0.3),
          text: DefaultColors.secondary,
        );
      case AppMiniBannerType.success:
        return (
          background: const Color(0xFF2E7D32).withValues(alpha: 0.1),
          border: const Color(0xFF2E7D32).withValues(alpha: 0.25),
          text: const Color(0xFF2E7D32),
        );
      case AppMiniBannerType.error:
        return (
          background: const Color(0xFFC62828).withValues(alpha: 0.1),
          border: const Color(0xFFC62828).withValues(alpha: 0.25),
          text: const Color(0xFFC62828),
        );
    }
  }

  Widget _getDefaultLeading() {
    switch (type) {
      case AppMiniBannerType.syncing:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DefaultColors.primary,
          ),
        );
      case AppMiniBannerType.info:
        return const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: DefaultColors.primary,
        );
      case AppMiniBannerType.warning:
        return const Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: DefaultColors.secondary,
        );
      case AppMiniBannerType.success:
        return const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Color(0xFF2E7D32),
        );
      case AppMiniBannerType.error:
        return const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: Color(0xFFC62828),
        );
    }
  }
}

class _AppSyncStatusMiniBanner extends StatefulWidget {
  final bool isSyncing;
  final ValueListenable<bool>? isSyncingListenable;
  final ValueListenable<bool?>? syncSuccessListenable;
  final bool isOffline;
  final ValueListenable<NetworkStatus>? networkStatusListenable;
  final DateTime? lastFetchedAt;
  final String? offlineMessage;
  final String? syncingMessage;

  const _AppSyncStatusMiniBanner({
    super.key,
    this.isSyncing = false,
    this.isSyncingListenable,
    this.syncSuccessListenable,
    this.isOffline = false,
    this.networkStatusListenable,
    this.lastFetchedAt,
    this.offlineMessage,
    this.syncingMessage,
  });

  @override
  State<_AppSyncStatusMiniBanner> createState() =>
      _AppSyncStatusMiniBannerState();
}

class _AppSyncStatusMiniBannerState extends State<_AppSyncStatusMiniBanner> {
  bool _isSyncing = false;
  bool _showSuccessBriefly = false;
  NetworkStatus _networkStatus = NetworkStatus.online;
  Timer? _hideSuccessTimer;

  @override
  void initState() {
    super.initState();
    _isSyncing = widget.isSyncingListenable?.value ?? widget.isSyncing;
    widget.isSyncingListenable?.addListener(_handleSyncingChanged);

    _networkStatus =
        widget.networkStatusListenable?.value ??
        (widget.isOffline ? NetworkStatus.offline : NetworkStatus.online);
    widget.networkStatusListenable?.addListener(_handleNetworkStatusChanged);
  }

  void _handleNetworkStatusChanged() {
    if (mounted) {
      setState(() {
        _networkStatus =
            widget.networkStatusListenable?.value ?? NetworkStatus.online;
      });
    }
  }

  @override
  void didUpdateWidget(_AppSyncStatusMiniBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSyncingListenable != widget.isSyncingListenable) {
      oldWidget.isSyncingListenable?.removeListener(_handleSyncingChanged);
      widget.isSyncingListenable?.addListener(_handleSyncingChanged);
      _isSyncing = widget.isSyncingListenable?.value ?? widget.isSyncing;
    } else if (widget.isSyncingListenable == null &&
        oldWidget.isSyncing != widget.isSyncing) {
      _updateSyncing(widget.isSyncing);
    }

    if (oldWidget.networkStatusListenable != widget.networkStatusListenable) {
      oldWidget.networkStatusListenable?.removeListener(
        _handleNetworkStatusChanged,
      );
      widget.networkStatusListenable?.addListener(_handleNetworkStatusChanged);
      _networkStatus =
          widget.networkStatusListenable?.value ??
          (widget.isOffline ? NetworkStatus.offline : NetworkStatus.online);
    }
  }

  void _handleSyncingChanged() {
    final newValue = widget.isSyncingListenable?.value ?? false;
    _updateSyncing(newValue);
  }

  void _updateSyncing(bool syncing) {
    if (_isSyncing && !syncing) {
      _isSyncing = false;

      // CHỈ hiển thị "Đã đồng bộ dữ liệu" khi sync THỰC SỰ THÀNH CÔNG!
      // Nếu sync thất bại (lỗi kết nối, không có mạng), tuyệt đối không hiển thị thành công giả!
      final didSucceed = widget.syncSuccessListenable != null
          ? widget.syncSuccessListenable!.value == true
          : true;

      if (didSucceed) {
        setState(() {
          _showSuccessBriefly = true;
        });
        _hideSuccessTimer?.cancel();
        _hideSuccessTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _showSuccessBriefly = false;
            });
          }
        });
      } else {
        setState(() {
          _showSuccessBriefly = false;
        });
      }
    } else {
      if (syncing) {
        _hideSuccessTimer?.cancel();
        _showSuccessBriefly = false;
      }
      setState(() {
        _isSyncing = syncing;
      });
    }
  }

  @override
  void dispose() {
    widget.isSyncingListenable?.removeListener(_handleSyncingChanged);
    widget.networkStatusListenable?.removeListener(_handleNetworkStatusChanged);
    _hideSuccessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDeviceOffline = _networkStatus == NetworkStatus.offline;
    final isEffectivelyOffline = widget.isOffline || isDeviceOffline;

    final shouldShowSyncing = _isSyncing;
    final shouldShowSuccess = _showSuccessBriefly;
    final shouldShowOffline =
        isEffectivelyOffline && !shouldShowSyncing && !shouldShowSuccess;

    if (!shouldShowSyncing && !shouldShowSuccess && !shouldShowOffline) {
      return const SizedBox.shrink();
    }

    if (shouldShowSyncing) {
      return AppMiniBanner.syncing(message: widget.syncingMessage);
    } else if (shouldShowSuccess) {
      return AppMiniBanner.success(message: t('common.syncCompleted'));
    } else {
      return AppMiniBanner.offline(
        lastFetchedAt: widget.lastFetchedAt,
        message: widget.offlineMessage,
      );
    }
  }
}
