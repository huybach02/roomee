import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

/// Component hiển thị trạng thái rỗng (Empty State) chuẩn Design System.
/// Thường dùng cho các danh sách trống, kết quả tìm kiếm rỗng, hoặc các màn hình chưa có dữ liệu.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final double iconSize;
  final double iconContainerSize;
  final Widget? illustration;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconColor = DefaultColors.primary,
    this.iconBackgroundColor,
    this.iconSize = 44.0,
    this.iconContainerSize = 88.0,
    this.illustration,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = iconBackgroundColor ??
        iconColor.withValues(alpha: 0.08);

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: effectiveBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: FontSizes.medium,
                fontWeight: FontWeight.bold,
                color: DefaultColors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSizes.standard,
                  color: DefaultColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
