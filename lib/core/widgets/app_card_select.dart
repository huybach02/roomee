import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

class AppCardOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const AppCardOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

class AppCardSelect<T> extends StatelessWidget {
  final List<AppCardOption<T>> options;
  final String? labelText;
  final double spacing;
  final bool isMultiSelect;
  final T? selected;
  final Set<T>? selectedValues;
  final ValueChanged<T>? onChanged;
  final ValueChanged<Set<T>>? onMultiChanged;

  const AppCardSelect({
    super.key,
    required T this.selected,
    required this.options,
    required ValueChanged<T> this.onChanged,
    this.labelText,
    this.spacing = 12.0,
  })  : isMultiSelect = false,
        selectedValues = null,
        onMultiChanged = null;

  const AppCardSelect.multiple({
    super.key,
    required Set<T> this.selectedValues,
    required this.options,
    required ValueChanged<Set<T>> this.onMultiChanged,
    this.labelText,
    this.spacing = 12.0,
  })  : isMultiSelect = true,
        selected = null,
        onChanged = null;

  void _handleTap(T value) {
    if (isMultiSelect) {
      final current = Set<T>.from(selectedValues ?? {});
      if (current.contains(value)) {
        current.remove(value);
      } else {
        current.add(value);
      }
      onMultiChanged?.call(current);
    } else {
      onChanged?.call(value);
    }
  }

  bool _isSelected(T value) {
    if (isMultiSelect) {
      return selectedValues?.contains(value) ?? false;
    }
    return selected == value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null && labelText!.isNotEmpty) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: FontSizes.standard,
              fontWeight: FontWeight.w600,
              color: DefaultColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: options.map((option) {
            final isSelected = _isSelected(option.value);
            final isLast = option == options.last;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : spacing),
                child: GestureDetector(
                  onTap: () => _handleTap(option.value),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DefaultColors.primary.withValues(alpha: 0.06)
                          : DefaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? DefaultColors.primary : DefaultColors.border,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.icon != null) ...[
                          Icon(
                            option.icon,
                            size: 26,
                            color: isSelected ? DefaultColors.primary : DefaultColors.textSecondary,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          option.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: FontSizes.small,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? DefaultColors.primary : DefaultColors.textPrimary,
                          ),
                        ),
                        if (option.subtitle != null && option.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            option.subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: FontSizes.small - 2,
                              color: DefaultColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
