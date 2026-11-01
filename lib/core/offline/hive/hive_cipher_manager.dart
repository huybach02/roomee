import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveCipherManager {
  static const String secureKeyStorageKey = 'hive_encryption_key';
  final FlutterSecureStorage _storage;

  HiveCipherManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<HiveCipher> getOrCreateCipher() async {
    final existingKeyBase64 = await _storage.read(key: secureKeyStorageKey);
    if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
      final keyBytes = base64Decode(existingKeyBase64);
      return HiveAesCipher(keyBytes);
    }

    final newKeyBytes = Hive.generateSecureKey();
    await _storage.write(
      key: secureKeyStorageKey,
      value: base64Encode(newKeyBytes),
    );
    return HiveAesCipher(newKeyBytes);
  }
}
