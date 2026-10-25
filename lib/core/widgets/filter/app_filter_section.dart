import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';
import 'package:roomee/core/widgets/filter/filter_field_config.dart';

class AppFilterSection extends StatefulWidget {
  final FilterFieldConfig config;
  final dynamic currentValue;
  final ValueChanged<dynamic> onChanged;

  const AppFilterSection({
    super.key,
    required this.config,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  State<AppFilterSection> createState() => _AppFilterSectionState();
}

class _AppFilterSectionState extends State<AppFilterSection> {
  List<FilterOption>? _asyncOptions;
  bool _isLoadingAsync = false;

  @override
  void initState() {
    super.initState();
    if (widget.config.type == FilterType.dropdown &&
        widget.config.loadOptionsAsync != null) {
      _loadAsyncOptions();
    }
  }

  Future<void> _loadAsyncOptions() async {
    setState(() => _isLoadingAsync = true);
    try {
      final opts = await widget.config.loadOptionsAsync!();
      if (mounted) {
        setState(() {
          _asyncOptions = opts;
          _isLoadingAsync = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAsync = false);
      }
    }
  }

  Widget _buildChips(List<FilterOption> options) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = widget.currentValue == option.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (isSelected && option.value != null) {
                widget.onChanged(null);
              } else {
                widget.onChanged(option.value);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? DefaultColors.primary.withValues(alpha: 0.08)
                    : DefaultColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? DefaultColors.primary
                      : DefaultColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(
                      option.icon,
                      size: 14,
                      color: isSelected
                          ? DefaultColors.primary
                          : DefaultColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? DefaultColors.primary
                          : DefaultColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChips(List<FilterOption> options) {
    final selectedValues = (widget.currentValue is List)
        ? List.from(widget.currentValue as List)
        : <dynamic>[];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option.value);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              final newValues = List.from(selectedValues);
              if (isSelected) {
                newValues.remove(option.value);
              } else {
                newValues.add(option.value);
              }
              widget.onChanged(newValues);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? DefaultColors.primary.withValues(alpha: 0.08)
                    : DefaultColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? DefaultColors.primary
                      : DefaultColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(
                      option.icon,
                      size: 14,
                      color: isSelected
                          ? DefaultColors.primary
                          : DefaultColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? DefaultColors.primary
                          : DefaultColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown() {
    final options = _asyncOptions ?? widget.config.options ?? [];
    return AppDropdownField<dynamic>(
      value: widget.currentValue,
      isLoading: _isLoadingAsync,
      options: options
          .map((opt) =>
              AppDropdownOption<dynamic>(value: opt.value, label: opt.label))
          .toList(),
      onChanged: (val) => widget.onChanged(val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.config.title,
          style: const TextStyle(
            fontSize: FontSizes.small + 0.5,
            fontWeight: FontWeight.bold,
            color: DefaultColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (widget.config.type == FilterType.chips &&
            widget.config.options != null)
          _buildChips(widget.config.options!),
        if (widget.config.type == FilterType.multiChips &&
            widget.config.options != null)
          _buildMultiChips(widget.config.options!),
        if (widget.config.type == FilterType.dropdown) _buildDropdown(),
      ],
    );
  }
}
