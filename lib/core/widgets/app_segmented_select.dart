import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';

class AppSelectOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSegmentedSelect<T> extends StatelessWidget {
  final List<AppSelectOption<T>> options;
  final String? labelText;
  final double spacing;
  final bool isMultiSelect;
  final T? selected;
  final Set<T>? selectedValues;
  final ValueChanged<T>? onChanged;
  final ValueChanged<Set<T>>? onMultiChanged;

  const AppSegmentedSelect({
    super.key,
    required T this.selected,
    required this.options,
    required ValueChanged<T> this.onChanged,
    this.labelText,
    this.spacing = 10.0,
  })  : isMultiSelect = false,
        selectedValues = null,
        onMultiChanged = null;

  const AppSegmentedSelect.multiple({
    super.key,
    required Set<T> this.selectedValues,
    required this.options,
    required ValueChanged<Set<T>> this.onMultiChanged,
    this.labelText,
    this.spacing = 10.0,
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
          const SizedBox(height: 8),
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
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? DefaultColors.primary : DefaultColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? DefaultColors.primary : DefaultColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.icon != null) ...[
                          Icon(
                            option.icon,
                            size: 18,
                            color: isSelected ? DefaultColors.white : DefaultColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            option.label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: FontSizes.standard,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? DefaultColors.white : DefaultColors.textPrimary,
                            ),
                          ),
                        ),
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
