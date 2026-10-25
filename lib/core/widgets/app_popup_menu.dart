import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

/// Định nghĩa một mục (item) trong [AppPopupMenu].
class AppMenuItem<T> {
  final T value;
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final bool isDanger;
  final bool hasDividerBefore;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? customWidget;

  const AppMenuItem({
    required this.value,
    required this.title,
    this.icon,
    this.iconColor,
    this.textColor,
    this.isDanger = false,
    this.hasDividerBefore = false,
    this.enabled = true,
    this.onTap,
    this.customWidget,
  });
}

/// Menu popup chuẩn Design System hiển thị danh sách thao tác khi nhấn nút ba chấm (hoặc icon tùy biến).
/// Hỗ trợ cả 2 cách xử lý:
/// - Item-level: truyền [AppMenuItem.onTap] trực tiếp cho từng item.
/// - Menu-level: truyền callback [onSelected] ở cấp [AppPopupMenu].
class AppPopupMenu<T> extends StatelessWidget {
  final List<AppMenuItem<T>> items;
  final ValueChanged<T>? onSelected;
  final Widget? icon;
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final ShapeBorder? shape;
  final double elevation;
  final Color color;
  final String? tooltip;
  final Offset offset;
  final BoxConstraints? constraints;

  const AppPopupMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.icon,
    this.iconColor = DefaultColors.textSecondary,
    this.iconSize = 22,
    this.padding = EdgeInsets.zero,
    this.shape,
    this.elevation = 6,
    this.color = DefaultColors.white,
    this.tooltip,
    this.offset = const Offset(0, 4),
    this.constraints = const BoxConstraints(),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShape = shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: DefaultColors.border, width: 1),
        );

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: DefaultColors.divider,
        popupMenuTheme: PopupMenuThemeData(
          color: color,
          surfaceTintColor: Colors.transparent,
          elevation: elevation,
          shape: effectiveShape,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: PopupMenuButton<T>(
        icon: icon ??
            Icon(
              Icons.more_vert_rounded,
              color: iconColor,
              size: iconSize,
            ),
        shape: effectiveShape,
        elevation: elevation,
        padding: padding,
        color: color,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        tooltip: tooltip,
        offset: offset,
        constraints: constraints,
        onSelected: (val) {
          for (final item in items) {
            if (item.value == val) {
              item.onTap?.call();
              break;
            }
          }
          onSelected?.call(val);
        },
        itemBuilder: (context) {
          final entries = <PopupMenuEntry<T>>[];
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            if (item.hasDividerBefore || (item.isDanger && i > 0)) {
              entries.add(
                const PopupMenuDivider(height: 8),
              );
            }
            entries.add(
              PopupMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: item.customWidget ?? _buildDefaultItem(item),
              ),
            );
          }
          return entries;
        },
      ),
    );
  }

  Widget _buildDefaultItem(AppMenuItem<T> item) {
    final effectiveTextColor = item.textColor ??
        (item.isDanger ? DefaultColors.danger : DefaultColors.textPrimary);
    final effectiveIconColor = item.iconColor ??
        (item.isDanger ? DefaultColors.danger : DefaultColors.textSecondary);

    return Row(
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 19,
            color: effectiveIconColor,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            item.title,
            style: TextStyle(
              fontSize: FontSizes.standard,
              color: effectiveTextColor,
              fontWeight: item.isDanger ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
