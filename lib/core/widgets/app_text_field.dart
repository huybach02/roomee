import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomee/core/configs/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;

  final bool dense;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.autofocus = false,
    this.inputFormatters,
    this.autovalidateMode,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = dense ? FontSizes.small : FontSizes.standard;
    final radius = BorderRadius.circular(dense ? 6 : 12);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      style: TextStyle(fontSize: fontSize, color: DefaultColors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        labelStyle: TextStyle(
          fontSize: fontSize,
          color: DefaultColors.textSecondary,
        ),
        hintStyle: TextStyle(fontSize: fontSize, color: DefaultColors.textHint),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: dense,
        filled: true,
        fillColor: enabled
            ? DefaultColors.white
            : DefaultColors.disabled.withValues(alpha: 0.1),
        suffixIconConstraints: dense
            ? const BoxConstraints(minWidth: 30, minHeight: 30)
            : null,
        prefixIconConstraints: dense
            ? const BoxConstraints(minWidth: 30, minHeight: 30)
            : null,
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: DefaultColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: DefaultColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: DefaultColors.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: DefaultColors.border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: DefaultColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: DefaultColors.danger, width: 1.5),
        ),
      ),
    );
  }
}
