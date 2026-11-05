import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/offline/contracts/entity_store.dart';
import 'package:roomee/core/offline/contracts/relation_adapter.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';
import 'package:roomee/core/offline/hive/cache_metadata.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

abstract class BaseLocalDataSource<T, ID>
    implements LocalCrudDataSource<T, ID> {
  final EntityStore<T, ID> entityStore;
  final Box<Map> metadataBox;
  @override
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

  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<T> items,
    bool isComplete = false,
  }) =>
      saveAll(accountId: accountId, items: items, isComplete: isComplete);

  @override
  Future<void> cacheCreated({
    required String accountId,
    required T item,
  }) =>
      saveOne(accountId: accountId, item: item);

  @override
  Future<void> cacheUpdated({
    required String accountId,
    required T item,
  }) =>
      saveOne(accountId: accountId, item: item);

  @override
  Future<void> remove({
    required String accountId,
    required ID id,
  }) =>
      deleteOne(accountId: accountId, id: id);

  Future<void> saveAll({
    required String accountId,
    required List<T> items,
    bool isComplete = false,
  }) async {
    await _checkFormatVersion(accountId);

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

  Future<void> saveOne({
    required String accountId,
    required T item,
  }) async {
    await _checkFormatVersion(accountId);

    if (relationAdapter != null) {
      await relationAdapter!.saveRelations(accountId, [item]);
    }

    await entityStore.put(accountId: accountId, entity: item);

    final count = await entityStore.count(accountId: accountId);
    final prevMetadata = getMetadata(accountId);
    final now = DateTime.now();

    final newMetadata = CacheMetadata(
      entityName: entityName,
      accountId: accountId,
      cacheFormatVersion: cacheFormatVersion,
      isComplete: prevMetadata?.isComplete ?? false,
      cachedCount: count,
      lastFetchedAt: now,
      lastFullSyncAt: prevMetadata?.lastFullSyncAt,
    );

    await metadataBox.put(_metadataKey(accountId), newMetadata.toJson());
  }

  Future<void> deleteOne({
    required String accountId,
    required ID id,
  }) async {
    await _checkFormatVersion(accountId);

    await entityStore.delete(accountId: accountId, id: id);

    final count = await entityStore.count(accountId: accountId);
    final prevMetadata = getMetadata(accountId);

    final newMetadata = CacheMetadata(
      entityName: entityName,
      accountId: accountId,
      cacheFormatVersion: cacheFormatVersion,
      isComplete: prevMetadata?.isComplete ?? false,
      cachedCount: count,
      lastFetchedAt: prevMetadata?.lastFetchedAt,
      lastFullSyncAt: prevMetadata?.lastFullSyncAt,
    );

    await metadataBox.put(_metadataKey(accountId), newMetadata.toJson());
  }

  Future<void> _checkFormatVersion(String accountId) async {
    final metadata = getMetadata(accountId);
    if (metadata != null && metadata.cacheFormatVersion < cacheFormatVersion) {
      await clearAccount(accountId: accountId);
    }
  }

  @override
  Future<T?> getById({required String accountId, required ID id}) async {
    await _checkFormatVersion(accountId);
    final item = await entityStore.getById(accountId: accountId, id: id);
    if (item == null) return null;

    if (relationAdapter == null) return item;

    final hydrated = await relationAdapter!.hydrate(accountId, [item]);
    return hydrated.isEmpty ? item : hydrated.first;
  }

  @override
  Future<OfflinePage<T>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) async {
    await _checkFormatVersion(accountId);
    final allItems = await entityStore.getAll(accountId: accountId);
    final metadata = getMetadata(accountId);

    final itemsToQuery = relationAdapter != null && allItems.isNotEmpty
        ? await relationAdapter!.hydrate(accountId, allItems)
        : allItems;

    return queryEngine.query(
      items: itemsToQuery,
      queryParameters: queryParameters,
      schema: querySchema,
      metadata: metadata,
    );
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    await entityStore.clearAccount(accountId: accountId);
    if (relationAdapter != null) {
      await relationAdapter!.clearRelations(accountId);
    }
    await metadataBox.delete(_metadataKey(accountId));
  }

  @override
  Future<List<SyncItemDto>> getSyncItems({required String accountId}) =>
      entityStore.getSyncItems(accountId: accountId);

  @override
  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems({
    required String accountId,
  }) =>
      relationAdapter?.getRelationSyncItems(accountId) ??
      Future.value(const {});

  @override
  Future<void> applySyncResult({
    required String accountId,
    required SyncResultDto result,
  }) async {
    final updatedEntities =
        await entityStore.applySync(accountId: accountId, result: result);
    if (relationAdapter != null && updatedEntities.isNotEmpty) {
      await relationAdapter!.saveRelations(accountId, updatedEntities);
    }
  }

  @override
  Future<void> applyRelationSync({
    required String accountId,
    required Map<String, SyncResultDto> relationResults,
  }) async {
    if (relationAdapter != null) {
      await relationAdapter!.applyRelationSync(accountId, relationResults);
    }
  }
}
