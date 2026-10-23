import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_client.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_notification.dart';

/// Màn hình thông báo mất kết nối Internet chuẩn Design System Roomee.
///
/// Chặn điều hướng bằng [PopScope(canPop: false)] để bảo vệ các BLoC và Widget tree bên dưới
/// không bị hủy trong lúc mất mạng, giữ nguyên hàng đợi request chờ thử lại.
class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetrySuccess;

  const NoInternetScreen({
    super.key,
    this.onRetrySuccess,
  });

  static bool _isShowing = false;

  /// Trạng thái màn hình NoInternet có đang hiển thị hay không
  static bool get isShowing => _isShowing;

  /// Hiển thị màn hình mất kết nối toàn màn hình
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onRetrySuccess,
  }) {
    if (_isShowing) return Future.value();
    _isShowing = true;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      useSafeArea: false,
      builder: (_) => NoInternetScreen(onRetrySuccess: onRetrySuccess),
    ).then((_) {
      _isShowing = false;
    });
  }

  /// Đóng màn hình nếu đang hiển thị
  static void hide(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  /// Đặt lại trạng thái hiển thị (hỗ trợ testing)
  @visibleForTesting
  static void resetStateForTesting() {
    _isShowing = false;
  }

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // 1. Kiểm tra kết nối Internet thực tế bằng cách ping endpoint health check của server
      final client = ApiClient.instance;
      await client.dio.get(
        '/api/health',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      // 2. Đã có mạng thật và server online -> Thử replay lại các request trong hàng đợi
      final interceptor = client.authInterceptor;
      if (interceptor != null && interceptor.hasPendingRequests) {
        await interceptor.retryPendingQueue();
      }

      if (!mounted) return;

      // 3. Đóng màn hình No Internet và thông báo thành công
      NoInternetScreen.hide(context);
      widget.onRetrySuccess?.call();

      AppNotification.showSuccess(
        context,
        t('errors.connectionRestored'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
      });

      // Vẫn chưa có kết nối mạng thực tế
      AppNotification.showWarning(
        context,
        t('errors.stillNoInternet'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DefaultColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon mất mạng nổi bật
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: DefaultColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 52,
                      color: DefaultColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tiêu đề
                Text(
                  t('errors.noInternetTitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeight.bold,
                    color: DefaultColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Mô tả
                Text(
                  t('errors.noInternetMessage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: FontSizes.standard,
                    color: DefaultColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const Spacer(),

                // Nút Thử lại
                AppButton(
                  text: t('retry'),
                  isLoading: _isChecking,
                  type: AppButtonType.primary,
                  onPressed: _isChecking ? null : _handleRetry,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
