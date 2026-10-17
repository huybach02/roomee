import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _localeKey = 'app_locale';
  final FlutterSecureStorage _storage;

  LocaleCubit({
    Locale initialLocale = const Locale('vi'),
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        super(initialLocale);

  /// Đặt ngôn ngữ cụ thể ('vi' hoặc 'en') và lưu vào secure storage
  Future<void> setLocale(Locale locale) async {
    if (state.languageCode == locale.languageCode) return;
    emit(locale);
    try {
      await _storage.write(key: _localeKey, value: locale.languageCode);
    } catch (_) {
      // Bỏ qua lỗi lưu storage nếu có
    }
  }

  /// Chuyển đổi nhanh giữa 'vi' và 'en'
  Future<void> toggleLocale() async {
    final next = state.languageCode == 'vi' ? const Locale('en') : const Locale('vi');
    await setLocale(next);
  }
}
