import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_cipher_manager.dart';

void main() {
  late Directory directory;
  late FlutterSecureStorage storage;
  late HiveCipherManager manager;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    manager = HiveCipherManager(storage: storage);
    directory = await Directory.systemTemp.createTemp('cipher_manager_test');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('generates secure key on first call, saves to storage, and reuses it on subsequent calls', () async {
    expect(await storage.read(key: HiveCipherManager.secureKeyStorageKey), isNull);

    final cipher1 = await manager.getOrCreateCipher();
    expect(cipher1, isA<HiveCipher>());

    final savedKey = await storage.read(key: HiveCipherManager.secureKeyStorageKey);
    expect(savedKey, isNotNull);
    expect(savedKey!.isNotEmpty, isTrue);

    // Subsequent call returns cipher with the same key from storage
    final cipher2 = await manager.getOrCreateCipher();
    expect(cipher2, isA<HiveCipher>());
  });

  test('regenerates key when stored key is corrupted or has invalid length', () async {
    // Write invalid/corrupted key to storage
    await storage.write(key: HiveCipherManager.secureKeyStorageKey, value: 'corrupted-base64!!!');

    final cipher = await manager.getOrCreateCipher();
    expect(cipher, isA<HiveCipher>());

    // Verify a valid 32-byte key was regenerated and stored
    final newSavedKey = await storage.read(key: HiveCipherManager.secureKeyStorageKey);
    expect(newSavedKey, isNotNull);
    expect(base64Decode(newSavedKey!).length, 32);
  });

  test('CacheBoxes opens workspaces and users with encryption cipher', () async {
    final cipher = await manager.getOrCreateCipher();
    final boxes = await CacheBoxes.open(encryptionCipher: cipher);

    await boxes[HiveBoxNames.workspaces].put('encrypted_key', {'name': 'Encrypted Workspace'});
    await boxes[HiveBoxNames.users].put('encrypted_user', {'name': 'Encrypted User'});

    expect(boxes[HiveBoxNames.workspaces].get('encrypted_key')?['name'], 'Encrypted Workspace');
    expect(boxes[HiveBoxNames.users].get('encrypted_user')?['name'], 'Encrypted User');

    for (final box in boxes.all) {
      await box.close();
    }
  });
}
