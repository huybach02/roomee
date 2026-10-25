import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

enum AppButtonType {
  primary,
  secondary,
  outline,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final double height;
  final double? width;
  final Widget? icon;
  final double? fontSize;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.height = 52.0,
    this.width = double.infinity,
    this.icon,
    this.fontSize,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    final Color backgroundColor;
    final Color textColor;
    final BorderSide? border;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = isDisabled ? DefaultColors.disabled : DefaultColors.primary;
        textColor = DefaultColors.white;
        border = null;
        break;
      case AppButtonType.secondary:
        backgroundColor = isDisabled ? DefaultColors.disabled : DefaultColors.secondary;
        textColor = DefaultColors.white;
        border = null;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = isDisabled ? DefaultColors.disabled : DefaultColors.primary;
        border = BorderSide(
          color: isDisabled ? DefaultColors.disabled : DefaultColors.primary,
          width: 1.5,
        );
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? FontSizes.standardUp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? FontSizes.standardUp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      disabledBackgroundColor: backgroundColor,
      disabledForegroundColor: textColor,
      padding: padding,
      minimumSize: Size(width ?? 0, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        side: border ?? BorderSide.none,
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: buttonStyle,
        child: content,
      ),
    );
  }
}
