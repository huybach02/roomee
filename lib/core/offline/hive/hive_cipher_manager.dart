import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveCipherManager {
  static const String secureKeyStorageKey = 'hive_encryption_key';
  final FlutterSecureStorage _storage;

  HiveCipherManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<HiveCipher> getOrCreateCipher() async {
    try {
      final existingKeyBase64 = await _storage.read(key: secureKeyStorageKey);
      if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
        try {
          final keyBytes = base64Decode(existingKeyBase64);
          if (keyBytes.length == 32) {
            return HiveAesCipher(keyBytes);
          }
        } catch (_) {
          // Khóa lưu trữ bị hỏng, tiếp tục sinh khóa mới phía dưới
        }
      }
    } catch (e, s) {
      debugPrint('[HiveCipherManager] Error reading secure key from storage: $e\n$s');
      try {
        await _storage.delete(key: secureKeyStorageKey);
      } catch (_) {}
    }

    final newKeyBytes = Hive.generateSecureKey();
    try {
      await _storage.write(
        key: secureKeyStorageKey,
        value: base64Encode(newKeyBytes),
      );
    } catch (e, s) {
      debugPrint('[HiveCipherManager] Error saving generated key to secure storage: $e\n$s');
    }
    return HiveAesCipher(newKeyBytes);
  }
}
