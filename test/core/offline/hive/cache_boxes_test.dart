import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';

void main() {
  late Directory directory;
  late CacheBoxes boxes;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cache_boxes_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();
  });

  tearDown(() async {
    for (final box in boxes.all) {
      await box.close();
    }
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('clearAccountData deletes only keys for the specified account and leaves global data intact', () async {
    // 1. Put data for Account A
    await boxes[HiveBoxNames.workspaces].put(CacheKeyBuilder.entity('acc-a', 'ws-1'), {'name': 'Ws A1'});
    await boxes[HiveBoxNames.users].put(CacheKeyBuilder.entity('acc-a', 'user-a'), {'name': 'User A'});
    await boxes[HiveBoxNames.metadata].put(CacheKeyBuilder.metadata('acc-a', 'workspaces'), {'count': 1});

    // 2. Put data for Account B
    await boxes[HiveBoxNames.workspaces].put(CacheKeyBuilder.entity('acc-b', 'ws-2'), {'name': 'Ws B1'});
    await boxes[HiveBoxNames.users].put(CacheKeyBuilder.entity('acc-b', 'user-b'), {'name': 'User B'});
    await boxes[HiveBoxNames.metadata].put(CacheKeyBuilder.metadata('acc-b', 'workspaces'), {'count': 1});

    // 3. Put global data (provinces, wards)
    await boxes[HiveBoxNames.provinces].put(CacheKeyBuilder.entity('global', '92'), {'name': 'Cần Thơ'});
    await boxes[HiveBoxNames.wards].put(CacheKeyBuilder.entity('global', '310'), {'name': 'Ninh Kiều'});

    // 4. Clear data for Account A
    await boxes.clearAccountData('acc-a');

    // Account A data should be deleted:
    expect(boxes[HiveBoxNames.workspaces].get(CacheKeyBuilder.entity('acc-a', 'ws-1')), isNull);
    expect(boxes[HiveBoxNames.users].get(CacheKeyBuilder.entity('acc-a', 'user-a')), isNull);
    expect(boxes[HiveBoxNames.metadata].get(CacheKeyBuilder.metadata('acc-a', 'workspaces')), isNull);

    // Account B data must remain untouched:
    expect(boxes[HiveBoxNames.workspaces].get(CacheKeyBuilder.entity('acc-b', 'ws-2')), isNotNull);
    expect(boxes[HiveBoxNames.users].get(CacheKeyBuilder.entity('acc-b', 'user-b')), isNotNull);
    expect(boxes[HiveBoxNames.metadata].get(CacheKeyBuilder.metadata('acc-b', 'workspaces')), isNotNull);

    // Global data must remain untouched:
    expect(boxes[HiveBoxNames.provinces].get(CacheKeyBuilder.entity('global', '92')), isNotNull);
    expect(boxes[HiveBoxNames.wards].get(CacheKeyBuilder.entity('global', '310')), isNotNull);
  });

  test('CacheBoxes.configs configures all boxes and operator [] returns correct box', () {
    expect(CacheBoxes.configs[HiveBoxNames.workspaces], isTrue);
    expect(CacheBoxes.configs[HiveBoxNames.users], isTrue);
    expect(CacheBoxes.configs[HiveBoxNames.provinces], isFalse);
    expect(CacheBoxes.configs[HiveBoxNames.wards], isFalse);
    expect(CacheBoxes.configs[HiveBoxNames.metadata], isFalse);

    expect(boxes[HiveBoxNames.workspaces], equals(boxes.box(HiveBoxNames.workspaces)));
    expect(boxes.all.length, CacheBoxes.configs.length);
  });
}
