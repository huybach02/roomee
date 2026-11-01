import 'package:roomee/core/offline/query/offline_page.dart';

abstract interface class LocalCrudDataSource<T, ID> {
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
}
