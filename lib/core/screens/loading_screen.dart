import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';

/// Màn hình Loading dạng Overlay chuẩn Design System Roomee.
///
/// Hỗ trợ 2 cách sử dụng:
/// 1. Imperative (gọi hàm trực tiếp):
///    ```dart
///    LoadingScreen.show(context, message: 'Đang tải...');
///    // hoặc: context.showLoading();
///
///    LoadingScreen.hide(context);
///    // hoặc: context.hideLoading();
///    ```
/// 2. Declarative (bọc widget):
///    ```dart
///    LoadingOverlay(
///      isLoading: state is AuthLoading,
///      child: MyScreenContent(),
///    )
///    ```
class LoadingScreen extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingScreen({
    super.key,
    this.message,
    this.backgroundColor,
  });

  static bool _isShowing = false;

  /// Kiểm tra xem loading overlay dạng dialog có đang hiển thị hay không
  static bool get isShowing => _isShowing;

  /// Hiển thị loading overlay toàn màn hình (chặn tương tác và nút back)
  static Future<void> show(
    BuildContext context, {
    String? message,
  }) {
    if (_isShowing) return Future.value();
    _isShowing = true;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (_) => LoadingScreen(message: message),
    ).then((_) {
      _isShowing = false;
    });
  }

  /// Đóng loading overlay nếu đang hiển thị
  static void hide(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  /// Đặt lại trạng thái hiển thị (hỗ trợ test)
  @visibleForTesting
  static void resetStateForTesting() {
    _isShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? t('loading');

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: DefaultColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DefaultColors.primary,
                    ),
                  ),
                ),
                if (displayMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    displayMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: FontSizes.standard,
                      fontWeight: FontWeight.w500,
                      color: DefaultColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget bọc (declarative wrapper) cho màn hình có trạng thái loading
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? overlayColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: LoadingScreen(
              message: message,
              backgroundColor: overlayColor,
            ),
          ),
      ],
    );
  }
}

extension LoadingOverlayContextX on BuildContext {
  void showLoading({String? message}) =>
      LoadingScreen.show(this, message: message);
  void hideLoading() => LoadingScreen.hide(this);
}
