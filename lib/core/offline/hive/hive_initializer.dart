import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/hive/hive_cipher_manager.dart';

import 'cache_boxes.dart';

class HiveInitializer {
  static Future<CacheBoxes> initialize({
    FlutterSecureStorage? secureStorage,
    bool encrypt = true,
  }) async {
    await Hive.initFlutter();

    HiveCipher? cipher;
    if (encrypt) {
      try {
        final cipherManager = HiveCipherManager(storage: secureStorage);
        cipher = await cipherManager.getOrCreateCipher();
      } catch (_) {}
    }

    return CacheBoxes.open(encryptionCipher: cipher);
  }
}
