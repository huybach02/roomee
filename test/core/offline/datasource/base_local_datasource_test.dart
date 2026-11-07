import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';
import 'package:roomee/core/offline/contracts/relation_adapter.dart';
import 'package:roomee/core/offline/datasource/base_local_datasource.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

class _FakeItem {
  final String id;
  final String title;
  final String? relationTitle;

  const _FakeItem({
    required this.id,
    required this.title,
    this.relationTitle,
  });

  _FakeItem copyWith({String? relationTitle}) {
    return _FakeItem(
      id: id,
      title: title,
      relationTitle: relationTitle ?? this.relationTitle,
    );
  }
}

class _FakeCodec extends EntityCodec<_FakeItem, String> {
  @override
  String getId(_FakeItem entity) => entity.id;

  @override
  Map<String, dynamic> toJson(_FakeItem entity) => {
    'id': entity.id,
    'title': entity.title,
  };

  @override
  _FakeItem fromJson(Map<String, dynamic> json) => _FakeItem(
    id: json['id'] as String,
    title: json['title'] as String,
  );
}

class _FakeRelationAdapter extends RelationAdapter<_FakeItem> {
  int saveRelationsCalls = 0;
  int clearRelationsCalls = 0;
  List<String> lastHydratedIds = [];

  @override
  Future<void> saveRelations(
    String accountId,
    List<_FakeItem> entities,
  ) async {
    saveRelationsCalls++;
  }

  @override
  Future<List<_FakeItem>> hydrate(
    String accountId,
    List<_FakeItem> entities,
  ) async {
    lastHydratedIds = entities.map((e) => e.id).toList();
    return entities
        .map((e) => e.copyWith(relationTitle: 'Hydrated ${e.title}'))
        .toList();
  }

  @override
  Future<void> clearRelations(String accountId) async {
    clearRelationsCalls++;
  }
}

class _TestLocalDataSource extends BaseLocalDataSource<_FakeItem, String> {
  _TestLocalDataSource({
    required super.entityStore,
    required super.metadataBox,
    super.relationAdapter,
    super.cacheFormatVersion,
  }) : super(
         entityName: 'fake_items',
         queryEngine: const LocalQueryEngine<_FakeItem>(),
         querySchema: LocalQuerySchema<_FakeItem>(
           searchFields: [(item) => item.title],
           uniqueId: (item) => item.id,
         ),
       );
}

void main() {
  late Directory directory;
  late CacheBoxes boxes;
  late HiveEntityStore<_FakeItem, String> store;
  late _FakeRelationAdapter adapter;
  late _TestLocalDataSource dataSource;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('base_datasource_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();
    store = HiveEntityStore(box: boxes[HiveBoxNames.workspaces], codec: _FakeCodec());
    adapter = _FakeRelationAdapter();
    dataSource = _TestLocalDataSource(
      entityStore: store,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
    );
  });

  tearDown(() async {
    for (final box in boxes.all) {
      await box.close();
    }
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test(
    'saveAll calls relation adapter, stores entities, and updates metadata with count',
    () async {
      final items = [
        const _FakeItem(id: '1', title: 'Item 1'),
        const _FakeItem(id: '2', title: 'Item 2'),
      ];

      await dataSource.saveAll(
        accountId: 'acc-1',
        items: items,
        isComplete: false,
      );

      expect(adapter.saveRelationsCalls, 1);
      expect(await store.count(accountId: 'acc-1'), 2);

      final metadata = dataSource.getMetadata('acc-1');
      expect(metadata, isNotNull);
      expect(metadata?.entityName, 'fake_items');
      expect(metadata?.cachedCount, 2);
      expect(metadata?.isComplete, isFalse);
      expect(metadata?.lastFetchedAt, isNotNull);
    },
  );

  test(
    'saveAll with isComplete true clears previous items of that account before saving',
    () async {
      await dataSource.saveAll(
        accountId: 'acc-1',
        items: [
          const _FakeItem(id: 'old-1', title: 'Old 1'),
          const _FakeItem(id: 'old-2', title: 'Old 2'),
        ],
        isComplete: false,
      );
      expect(await store.count(accountId: 'acc-1'), 2);

      // Now sync with isComplete: true with only 1 item
      await dataSource.saveAll(
        accountId: 'acc-1',
        items: [const _FakeItem(id: 'new-1', title: 'New 1')],
        isComplete: true,
      );

      expect(await store.count(accountId: 'acc-1'), 1);
      final item = await dataSource.getById(accountId: 'acc-1', id: 'new-1');
      expect(item, isNotNull);
      expect(
        await dataSource.getById(accountId: 'acc-1', id: 'old-1'),
        isNull,
      );

      final metadata = dataSource.getMetadata('acc-1');
      expect(metadata?.isComplete, isTrue);
      expect(metadata?.cachedCount, 1);
      expect(metadata?.lastFullSyncAt, isNotNull);
    },
  );

  test('getById returns single entity with hydrated relations', () async {
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [const _FakeItem(id: '1', title: 'My Item')],
    );

    final item = await dataSource.getById(accountId: 'acc-1', id: '1');
    expect(item, isNotNull);
    expect(item?.id, '1');
    expect(item?.relationTitle, 'Hydrated My Item');

    expect(await dataSource.getById(accountId: 'acc-1', id: '999'), isNull);
  });

  test(
    'queryPage hydrates relations before calling queryEngine so relation fields can be queried',
    () async {
      final items = List.generate(
        10,
        (i) => _FakeItem(id: '$i', title: 'Item $i'),
      );
      await dataSource.saveAll(accountId: 'acc-1', items: items);

      final page = await dataSource.queryPage(
        accountId: 'acc-1',
        queryParameters: {'page': 1, 'limit': 3},
      );

      expect(page.data.length, 3);
      expect(page.total, 10);
      expect(page.totalPages, 4);
      expect(page.source, DataSourceKind.local);

      // Verify that all items were hydrated so search/filter on relation fields works
      expect(adapter.lastHydratedIds.length, 10);
      expect(page.data.first.relationTitle, 'Hydrated Item 0');
    },
  );

  test('saveOne saves relations, stores single entity, and updates metadata count', () async {
    const item = _FakeItem(id: 'single-1', title: 'Single Item');

    await dataSource.saveOne(accountId: 'acc-1', item: item);

    expect(adapter.saveRelationsCalls, 1);
    expect(await store.count(accountId: 'acc-1'), 1);

    final saved = await dataSource.getById(accountId: 'acc-1', id: 'single-1');
    expect(saved?.title, 'Single Item');
    expect(saved?.relationTitle, 'Hydrated Single Item');

    final metadata = dataSource.getMetadata('acc-1');
    expect(metadata?.cachedCount, 1);
  });

  test('deleteOne deletes entity from store and decrements metadata count', () async {
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [
        const _FakeItem(id: '1', title: 'Item 1'),
        const _FakeItem(id: '2', title: 'Item 2'),
      ],
    );
    expect(await store.count(accountId: 'acc-1'), 2);
    expect(dataSource.getMetadata('acc-1')?.cachedCount, 2);

    await dataSource.deleteOne(accountId: 'acc-1', id: '1');

    expect(await store.count(accountId: 'acc-1'), 1);
    expect(await dataSource.getById(accountId: 'acc-1', id: '1'), isNull);
    expect(await dataSource.getById(accountId: 'acc-1', id: '2'), isNotNull);
    expect(dataSource.getMetadata('acc-1')?.cachedCount, 1);
  });

  test('clearAccount removes items, cleans relations, and deletes metadata', () async {
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [const _FakeItem(id: '1', title: 'Item 1')],
    );

    expect(await store.count(accountId: 'acc-1'), 1);
    expect(dataSource.getMetadata('acc-1'), isNotNull);

    await dataSource.clearAccount(accountId: 'acc-1');

    expect(await store.count(accountId: 'acc-1'), 0);
    expect(adapter.clearRelationsCalls, 1);
    expect(dataSource.getMetadata('acc-1'), isNull);
  });

  test('automatically invalidates and clears stale cache when cacheFormatVersion is upgraded', () async {
    // 1. Save item with version 1
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [const _FakeItem(id: '1', title: 'Old Format Item')],
    );
    expect(await store.count(accountId: 'acc-1'), 1);
    expect(dataSource.getMetadata('acc-1')?.cacheFormatVersion, 1);

    // 2. Create new DataSource instance configured with cacheFormatVersion = 2 (incompatible upgrade)
    final upgradedDataSource = _TestLocalDataSource(
      entityStore: store,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
      cacheFormatVersion: 2,
    );

    // 3. Querying on upgraded data source detects stale format and invalidates cache
    final result = await upgradedDataSource.queryPage(
      accountId: 'acc-1',
      queryParameters: {},
    );

    expect(result.data.isEmpty, isTrue);
    expect(await store.count(accountId: 'acc-1'), 0);
  });

  test('saveAll invalidates stale cache when cacheFormatVersion is upgraded before saving new items', () async {
    // 1. Save items with version 1
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [
        const _FakeItem(id: 'old-1', title: 'Old 1'),
        const _FakeItem(id: 'old-2', title: 'Old 2'),
      ],
      isComplete: false,
    );
    expect(await store.count(accountId: 'acc-1'), 2);

    // 2. Upgraded data source
    final upgradedDataSource = _TestLocalDataSource(
      entityStore: store,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
      cacheFormatVersion: 2,
    );

    // 3. Online fetch saves page 1 (isComplete: false)
    await upgradedDataSource.saveAll(
      accountId: 'acc-1',
      items: [const _FakeItem(id: 'new-1', title: 'New 1')],
      isComplete: false,
    );

    // Old items should be cleared, only new item remains
    expect(await store.count(accountId: 'acc-1'), 1);
    expect(await upgradedDataSource.getById(accountId: 'acc-1', id: 'new-1'), isNotNull);
    expect(await store.getById(accountId: 'acc-1', id: 'old-1'), isNull);
    expect(await store.getById(accountId: 'acc-1', id: 'old-2'), isNull);
    expect(upgradedDataSource.getMetadata('acc-1')?.cacheFormatVersion, 2);
  });

  test('saveOne invalidates stale cache when cacheFormatVersion is upgraded', () async {
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [const _FakeItem(id: 'old-1', title: 'Old 1')],
    );

    final upgradedDataSource = _TestLocalDataSource(
      entityStore: store,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
      cacheFormatVersion: 2,
    );

    await upgradedDataSource.saveOne(
      accountId: 'acc-1',
      item: const _FakeItem(id: 'new-1', title: 'New 1'),
    );

    expect(await store.count(accountId: 'acc-1'), 1);
    expect(await store.getById(accountId: 'acc-1', id: 'old-1'), isNull);
    expect(await store.getById(accountId: 'acc-1', id: 'new-1'), isNotNull);
    expect(upgradedDataSource.getMetadata('acc-1')?.cacheFormatVersion, 2);
  });

  test('deleteOne invalidates stale cache when cacheFormatVersion is upgraded', () async {
    await dataSource.saveAll(
      accountId: 'acc-1',
      items: [
        const _FakeItem(id: 'old-1', title: 'Old 1'),
        const _FakeItem(id: 'old-2', title: 'Old 2'),
      ],
    );

    final upgradedDataSource = _TestLocalDataSource(
      entityStore: store,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
      cacheFormatVersion: 2,
    );

    await upgradedDataSource.deleteOne(accountId: 'acc-1', id: 'old-1');

    expect(await store.count(accountId: 'acc-1'), 0);
    expect(await store.getById(accountId: 'acc-1', id: 'old-2'), isNull);
  });
}
