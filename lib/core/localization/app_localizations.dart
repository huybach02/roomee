import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  static final Map<String, Map<String, dynamic>> _cache = {};
  static AppLocalizations? _instance;
  Map<String, dynamic> _localizedStrings = {};

  AppLocalizations(this.locale) {
    if (_cache.containsKey(locale.languageCode)) {
      _localizedStrings = _cache[locale.languageCode]!;
    }
    _instance = this;
  }

  /// Instance toàn cục hiện tại
  static AppLocalizations get instance =>
      _instance ?? AppLocalizations(const Locale('vi'));

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        instance;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  /// Nạp trước tất cả file json vào bộ nhớ cache để chuyển đổi tức thì (0ms)
  static Future<void> preload() async {
    for (final loc in supportedLocales) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/${loc.languageCode}.json',
        );
        _cache[loc.languageCode] =
            json.decode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        _cache[loc.languageCode] = {};
      }
    }
    _instance = AppLocalizations(const Locale('vi'));
  }

  /// Dịch key (hỗ trợ nested key dạng 'auth.login' hoặc key phẳng 'welcomeTitle')
  String translate(String key, [Map<String, String>? params]) {
    dynamic value;
    if (key.contains('.')) {
      final keys = key.split('.');
      dynamic current = _localizedStrings;
      for (final k in keys) {
        if (current is Map<String, dynamic> && current.containsKey(k)) {
          current = current[k];
        } else {
          current = null;
          break;
        }
      }
      value = current;
    } else {
      value = _localizedStrings[key];
    }

    if (value == null || value is! String) {
      return key; // Fallback trả về chính key nếu không tìm thấy
    }

    String result = value;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        result = result.replaceAll('{$paramKey}', paramVal);
      });
    }
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    if (AppLocalizations._cache.containsKey(locale.languageCode)) {
      final loc = AppLocalizations(locale);
      return SynchronousFuture<AppLocalizations>(loc);
    }

    return rootBundle
        .loadString('assets/translations/${locale.languageCode}.json')
        .then((jsonString) {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      AppLocalizations._cache[locale.languageCode] = data;
      return AppLocalizations(locale);
    }).catchError((_) {
      return AppLocalizations(locale);
    });
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Hàm dịch toàn cục cho Mobile: gọi trực tiếp t('key') ở bất kỳ đâu
/// (Widget, Bloc, Repository, Service, Model, Utils) mà KHÔNG cần BuildContext!
String t(String key, [Map<String, String>? params]) {
  return AppLocalizations.instance.translate(key, params);
}

extension AppLocalizationsX on BuildContext {
  /// Cú pháp tiện lợi qua context: context.tr('welcomeTitle')
  String tr(String key, [Map<String, String>? params]) {
    return AppLocalizations.of(this).translate(key, params);
  }
}
