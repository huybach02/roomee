import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

enum AppNotificationType {
  success,
  error,
  warning,
  info,
}

class AppNotification {
  AppNotification._();

  /// Hiển thị thông báo SnackBar chuẩn Design System với icon prefix và màu sắc tương ứng
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      createSnackBar(
        message: message,
        type: type,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Hiển thị thông báo thành công (background: DefaultColors.success, icon: check_circle_outline)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return show(
      context,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị thông báo lỗi (background: DefaultColors.danger, icon: error_outline)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return show(
      context,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị thông báo cảnh báo (background: DefaultColors.warning, icon: warning_amber_rounded)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return show(
      context,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị thông báo thông tin (background: DefaultColors.info, icon: info_outline)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return show(
      context,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
      action: action,
    );
  }

  /// Tạo instance SnackBar có icon prefix và style chuẩn hóa
  static SnackBar createSnackBar({
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final Color backgroundColor;
    final IconData iconData;

    switch (type) {
      case AppNotificationType.success:
        backgroundColor = DefaultColors.success;
        iconData = Icons.check_circle_outline;
        break;
      case AppNotificationType.error:
        backgroundColor = DefaultColors.danger;
        iconData = Icons.error_outline;
        break;
      case AppNotificationType.warning:
        backgroundColor = DefaultColors.warning;
        iconData = Icons.warning_amber_rounded;
        break;
      case AppNotificationType.info:
        backgroundColor = DefaultColors.info;
        iconData = Icons.info_outline;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(
            iconData,
            color: DefaultColors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: DefaultColors.white,
                fontSize: FontSizes.standard,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: duration,
      action: action,
    );
  }
}

extension AppNotificationContextX on BuildContext {
  void showSuccessNotification(String message) =>
      AppNotification.showSuccess(this, message);
  void showErrorNotification(String message) =>
      AppNotification.showError(this, message);
  void showWarningNotification(String message) =>
      AppNotification.showWarning(this, message);
  void showInfoNotification(String message) =>
      AppNotification.showInfo(this, message);
}
