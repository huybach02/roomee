import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

abstract interface class LocalCrudDataSource<T, ID> {
  String get entityName;

  Future<void> cacheRemotePage({
    required String accountId,
    required List<T> items,
    bool isComplete = false,
  });

  Future<OfflinePage<T>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  });

  Future<T?> getById({
    required String accountId,
    required ID id,
  });

  Future<void> cacheCreated({
    required String accountId,
    required T item,
  });

  Future<void> cacheUpdated({
    required String accountId,
    required T item,
  });

  Future<void> remove({
    required String accountId,
    required ID id,
  });

  Future<void> clearAccount({
    required String accountId,
  });

  Future<List<SyncItemDto>> getSyncItems({
    required String accountId,
  });

  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems({
    required String accountId,
  });

  Future<void> applySyncResult({
    required String accountId,
    required SyncResultDto result,
  });

  Future<void> applyRelationSync({
    required String accountId,
    required Map<String, SyncResultDto> relationResults,
  });

  T itemFromJson(Map<String, dynamic> json);
  Map<String, dynamic> itemToJson(T item);
}

