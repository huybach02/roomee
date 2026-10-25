import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final bool isDanger;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.confirmText,
    this.cancelText,
    this.isDanger = false,
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  }) : assert(
         message != null || content != null,
         'Either message or content must be provided',
       );

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String? confirmText,
    String? cancelText,
    bool isDanger = false,
    Color? confirmColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor =
        confirmColor ??
        (isDanger ? DefaultColors.danger : DefaultColors.primary);

    return AlertDialog(
      backgroundColor: DefaultColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: DefaultColors.textPrimary,
        ),
      ),
      content:
          content ??
          Text(
            message ?? '',
            style: const TextStyle(
              fontSize: FontSizes.standard,
              color: DefaultColors.textSecondary,
            ),
          ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            cancelText ?? t('cancel'),
            style: const TextStyle(
              color: DefaultColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveConfirmColor,
          ),
          child: Text(
            confirmText ?? (isDanger ? t('actionDelete') : t('confirm')),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: DefaultColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
