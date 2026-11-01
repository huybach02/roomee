import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/entity_store.dart';
import 'package:roomee/core/offline/contracts/relation_adapter.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';
import 'package:roomee/core/offline/hive/cache_metadata.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

abstract class BaseLocalDataSource<T, ID> {
  final EntityStore<T, ID> entityStore;
  final Box<Map> metadataBox;
  final String entityName;
  final LocalQueryEngine<T> queryEngine;
  final LocalQuerySchema<T> querySchema;
  final RelationAdapter<T>? relationAdapter;
  final int cacheFormatVersion;

  BaseLocalDataSource({
    required this.entityStore,
    required this.metadataBox,
    required this.entityName,
    required this.queryEngine,
    required this.querySchema,
    this.relationAdapter,
    this.cacheFormatVersion = 1,
  });

  String _metadataKey(String accountId) =>
      CacheKeyBuilder.metadata(accountId, entityName);

  CacheMetadata? getMetadata(String accountId) {
    final raw = metadataBox.get(_metadataKey(accountId));
    if (raw == null) return null;
    return CacheMetadata.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveAll({
    required String accountId,
    required List<T> items,
    bool isComplete = false,
  }) async {
    if (relationAdapter != null) {
      await relationAdapter!.saveRelations(accountId, items);
    }

    if (isComplete) {
      await entityStore.clearAccount(accountId: accountId);
    }

    await entityStore.putMany(accountId: accountId, entities: items);

    final count = await entityStore.count(accountId: accountId);
    final prevMetadata = getMetadata(accountId);
    final now = DateTime.now();

    final newMetadata = CacheMetadata(
      entityName: entityName,
      accountId: accountId,
      cacheFormatVersion: cacheFormatVersion,
      isComplete: isComplete,
      cachedCount: count,
      lastFetchedAt: now,
      lastFullSyncAt: isComplete ? now : prevMetadata?.lastFullSyncAt,
    );

    await metadataBox.put(_metadataKey(accountId), newMetadata.toJson());
  }

  Future<T?> getById({required String accountId, required ID id}) async {
    final item = await entityStore.getById(accountId: accountId, id: id);
    if (item == null) return null;

    if (relationAdapter == null) return item;

    final hydrated = await relationAdapter!.hydrate(accountId, [item]);
    return hydrated.isEmpty ? item : hydrated.first;
  }

  Future<OfflinePage<T>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) async {
    final allItems = await entityStore.getAll(accountId: accountId);
    final metadata = getMetadata(accountId);

    final rawPage = queryEngine.query(
      items: allItems,
      queryParameters: queryParameters,
      schema: querySchema,
      metadata: metadata,
    );

    if (relationAdapter == null || rawPage.data.isEmpty) {
      return rawPage;
    }

    final hydratedData = await relationAdapter!.hydrate(
      accountId,
      rawPage.data,
    );
    return rawPage.copyWith(data: hydratedData);
  }

  Future<void> clearAccount({required String accountId}) async {
    await entityStore.clearAccount(accountId: accountId);
    if (relationAdapter != null) {
      await relationAdapter!.clearRelations(accountId);
    }
    await metadataBox.delete(_metadataKey(accountId));
  }
}
