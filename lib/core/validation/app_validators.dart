import 'package:flutter/widgets.dart';
import 'package:roomee/core/localization/app_localizations.dart';

class ValidationConfig {
  ValidationConfig._();

  static final RegExp email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp vnPhone = RegExp(r'^(?:\+84|0)(?:3|5|7|8|9)\d{8}$');

  static const int emailMax = 255;
  static const int passwordMin = 8;
  static const int passwordMax = 255;
  static const int fullNameMax = 100;
  static const int bioMax = 500;
  static const int otpLength = 6;
}

/// Tầng 1 — rule nguyên tử, mỗi rule chỉ kiểm tra MỘT điều.
///
/// Quy ước (giống `.optional()` của zod): mọi rule, trừ `required`,
/// đều bỏ qua giá trị rỗng. Field bắt buộc thì ghép thêm `required()`.
/// Message được dịch lúc validate, nên đổi ngôn ngữ vẫn hiển thị đúng.
class Validators {
  Validators._();

  static bool _isEmpty(String? v) => v == null || v.trim().isEmpty;

  /// Chạy lần lượt các rule, trả về lỗi đầu tiên gặp phải.
  static FormFieldValidator<T> compose<T>(List<FormFieldValidator<T>> rules) {
    return (value) {
      for (final rule in rules) {
        final error = rule(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  static FormFieldValidator<String> required({String? messageKey}) =>
      (v) =>
          _isEmpty(v) ? t(messageKey ?? 'validateErrors.fieldRequired') : null;

  /// Dùng cho field không phải String (segmented select, date object...).
  static FormFieldValidator<T> requiredValue<T>({String? messageKey}) =>
      (v) => v == null ? t(messageKey ?? 'validateErrors.fieldRequired') : null;

  static FormFieldValidator<String> minLength(
    int min, {
    bool trim = true,
    String? messageKey,
  }) => (v) {
    if (_isEmpty(v)) return null;
    final s = trim ? v!.trim() : v!;
    return s.length < min
        ? t(messageKey ?? 'validateErrors.minLength', {'min': '$min'})
        : null;
  };

  static FormFieldValidator<String> maxLength(
    int max, {
    bool trim = true,
    String? messageKey,
  }) => (v) {
    if (_isEmpty(v)) return null;
    final s = trim ? v!.trim() : v!;
    return s.length > max
        ? t(messageKey ?? 'validateErrors.maxLength', {'max': '$max'})
        : null;
  };

  static FormFieldValidator<String> pattern(RegExp regex, String messageKey) =>
      (v) {
        if (_isEmpty(v)) return null;
        return regex.hasMatch(v!.trim()) ? null : t(messageKey);
      };

  static FormFieldValidator<String> email() =>
      pattern(ValidationConfig.email, 'validateErrors.invalidEmail');

  static FormFieldValidator<String> vnPhone() =>
      pattern(ValidationConfig.vnPhone, 'validateErrors.invalidPhone');

  static FormFieldValidator<String> digits(int length, {String? messageKey}) =>
      pattern(
        RegExp('^\\d{$length}\$'),
        messageKey ?? 'validateErrors.invalidDigits',
      );

  /// So khớp với giá trị của field khác (đọc lazy qua callback).
  static FormFieldValidator<String> matches(
    String Function() other, {
    String messageKey = 'validateErrors.passwordsDoNotMatch',
  }) =>
      (v) => v == other() ? null : t(messageKey);
}

/// Tầng 2 — rule theo từng loại field, tương đương `ruleValidates.emailRule`,
/// `passwordRule`... bên BE. Screen chỉ gọi tầng này.
class FieldRules {
  FieldRules._();

  static FormFieldValidator<String> email({bool required = true}) =>
      Validators.compose([
        if (required) Validators.required(),
        Validators.maxLength(ValidationConfig.emailMax),
        Validators.email(),
      ]);

  /// Mật khẩu khi tạo mới / đổi mật khẩu.
  static FormFieldValidator<String> password() => Validators.compose([
    Validators.required(),
    Validators.minLength(
      ValidationConfig.passwordMin,
      trim: false,
      messageKey: 'validateErrors.passwordTooShort',
    ),
    Validators.maxLength(ValidationConfig.passwordMax, trim: false),
  ]);

  /// Mật khẩu khi đăng nhập: chỉ bắt buộc nhập (giống loginSchema min: 1).
  static FormFieldValidator<String> loginPassword() => Validators.required();

  static FormFieldValidator<String> confirmPassword(
    String Function() password,
  ) =>
      Validators.compose([Validators.required(), Validators.matches(password)]);

  static FormFieldValidator<String> phone({bool required = false}) =>
      Validators.compose([
        if (required) Validators.required(),
        Validators.vnPhone(),
      ]);

  static FormFieldValidator<String> fullName({bool required = true}) =>
      Validators.compose([
        if (required) Validators.required(),
        Validators.maxLength(ValidationConfig.fullNameMax),
      ]);

  static FormFieldValidator<String> bio() =>
      Validators.maxLength(ValidationConfig.bioMax);

  static FormFieldValidator<String> otp() => Validators.compose([
    Validators.required(messageKey: 'validateErrors.otpInvalid'),
    Validators.digits(
      ValidationConfig.otpLength,
      messageKey: 'validateErrors.otpInvalid',
    ),
  ]);
}
