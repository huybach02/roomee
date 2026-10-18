import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_text_field.dart';

class AppDatePickerField extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String dateFormat;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  const AppDatePickerField({
    super.key,
    this.selectedDate,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.controller,
    this.labelText,
    this.hintText,
    this.dateFormat = 'dd/MM/yyyy',
    this.validator,
    this.prefixIcon = const Icon(Icons.calendar_today_outlined, color: DefaultColors.textSecondary),
    this.suffixIcon = const Icon(Icons.arrow_drop_down, color: DefaultColors.textSecondary),
    this.enabled = true,
  });

  @override
  State<AppDatePickerField> createState() => _AppDatePickerFieldState();
}

class _AppDatePickerFieldState extends State<AppDatePickerField> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(covariant AppDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate ||
        widget.dateFormat != oldWidget.dateFormat) {
      _updateControllerText(isPostFrame: true);
    }
  }

  void _updateControllerText({bool isPostFrame = false}) {
    final newText = widget.selectedDate != null
        ? DateFormat(widget.dateFormat).format(widget.selectedDate!)
        : '';
    if (_effectiveController.text != newText) {
      if (isPostFrame) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _effectiveController.text = newText;
          }
        });
      } else {
        _effectiveController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(1900);
    final last = widget.lastDate ?? DateTime(2100);

    DateTime initial = widget.selectedDate ?? widget.initialDate ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DefaultColors.primary,
              onPrimary: DefaultColors.white,
              onSurface: DefaultColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _effectiveController.text =
          DateFormat(widget.dateFormat).format(pickedDate);
      widget.onDateSelected?.call(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _effectiveController,
      readOnly: true,
      enabled: widget.enabled,
      onTap: () => _pickDate(context),
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      validator: widget.validator,
    );
  }
}
