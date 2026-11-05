import 'entity_codec.dart';
import 'sync_dtos.dart';

abstract interface class EntityStore<T, ID> {
  EntityCodec<T, ID> get codec;

  Future<void> put({required String accountId, required T entity});

  Future<void> putMany({required String accountId, required List<T> entities});

  Future<T?> getById({required String accountId, required ID id});

  Future<List<T>> getAll({required String accountId});

  Future<int> count({required String accountId});

  Future<void> delete({required String accountId, required ID id});

  Future<void> clearAccount({required String accountId});

  Future<List<SyncItemDto>> getSyncItems({required String accountId});

  Future<List<T>> applySync({
    required String accountId,
    required SyncResultDto result,
  });
}

