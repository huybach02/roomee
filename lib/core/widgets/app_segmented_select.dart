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
  final FormFieldValidator<T>? validator;
  final AutovalidateMode? autovalidateMode;

  const AppSegmentedSelect({
    super.key,
    required T this.selected,
    required this.options,
    required ValueChanged<T> this.onChanged,
    this.labelText,
    this.spacing = 10.0,
    this.validator,
    this.autovalidateMode,
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
    this.validator,
    this.autovalidateMode,
  })  : isMultiSelect = true,
        selected = null,
        onChanged = null;

  void _handleTap(T value, FormFieldState<T>? formState) {
    if (isMultiSelect) {
      final current = Set<T>.from(selectedValues ?? {});
      if (current.contains(value)) {
        current.remove(value);
      } else {
        current.add(value);
      }
      onMultiChanged?.call(current);
    } else {
      formState?.didChange(value);
      onChanged?.call(value);
    }
  }

  bool _isSelected(T value, FormFieldState<T>? formState) {
    if (isMultiSelect) {
      return selectedValues?.contains(value) ?? false;
    }
    final effectiveSelected = formState?.value ?? selected;
    return effectiveSelected == value;
  }

  Widget _buildContent(BuildContext context, FormFieldState<T>? formState) {
    final hasError = formState?.hasError ?? false;

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
            final isSelected = _isSelected(option.value, formState);
            final isLast = option == options.last;

            final borderColor = isSelected
                ? DefaultColors.primary
                : (hasError ? DefaultColors.danger : DefaultColors.border);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : spacing),
                child: GestureDetector(
                  onTap: () => _handleTap(option.value, formState),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? DefaultColors.primary : DefaultColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (option.icon != null) ...[
                          Icon(
                            option.icon,
                            size: 18,
                            color: isSelected ? DefaultColors.white : DefaultColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: FontSizes.standard,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? DefaultColors.white : DefaultColors.textPrimary,
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
        if (hasError && formState?.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              formState!.errorText!,
              style: const TextStyle(
                fontSize: FontSizes.small - 1,
                color: DefaultColors.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (validator == null) {
      return _buildContent(context, null);
    }

    return FormField<T>(
      initialValue: selected,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (formState) => _buildContent(context, formState),
    );
  }
}
