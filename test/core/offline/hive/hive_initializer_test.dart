import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('hive_initializer_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => directory.path,
        );
  });

  tearDown(() async {
    for (final box in CacheBoxes.configs.keys) {
      if (Hive.isBoxOpen(box)) {
        await Hive.box<Map>(box).close();
      }
    }
    await Hive.close();
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('HiveInitializer.initialize opens all cache boxes with encryption', () async {
    final boxes = await HiveInitializer.initialize(
      secureStorage: const FlutterSecureStorage(),
      encrypt: true,
    );

    expect(boxes.all.length, CacheBoxes.configs.length);
    for (final boxName in CacheBoxes.configs.keys) {
      expect(boxes[boxName].isOpen, isTrue);
    }
  });

  test('HiveInitializer.initialize opens boxes when encrypt is false', () async {
    final boxes = await HiveInitializer.initialize(encrypt: false);

    expect(boxes.all.length, CacheBoxes.configs.length);
    expect(boxes[HiveBoxNames.workspaces].isOpen, isTrue);
  });
}
