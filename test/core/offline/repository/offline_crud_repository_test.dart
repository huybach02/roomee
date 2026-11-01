import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';

class _FakeItem {
  final String id;
  final String name;

  const _FakeItem(this.id, this.name);
}

class _FakeRemote implements RemoteCrudDataSource<_FakeItem, String> {
  Object? errorToThrow;
  List<_FakeItem> items = [];
  _FakeItem? singleItem;

  @override
  Future<ApiResponse<PaginationModel<_FakeItem>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: PaginationModel(
        data: items,
        total: items.length,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<_FakeItem>> getById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: singleItem ?? _FakeItem(id, 'Item $id'),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<_FakeItem>> create(Map<String, dynamic> data) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: _FakeItem('new-id', data['name'] as String),
      success: true,
      message: 'Created',
    );
  }

  @override
  Future<ApiResponse<_FakeItem>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: _FakeItem(id, data['name'] as String),
      success: true,
      message: 'Updated',
    );
  }

  @override
  Future<ApiResponse<void>> deleteById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return const ApiResponse(data: null, success: true, message: 'Deleted');
  }
}

class _FakeLocal implements LocalCrudDataSource<_FakeItem, String> {
  bool throwOnCache = false;
  List<_FakeItem> cached = [];
  final Map<String, _FakeItem> itemsById = {};

  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<_FakeItem> items,
    bool isComplete = false,
  }) async {
    if (throwOnCache) throw Exception('Disk full');
    cached.addAll(items);
    for (final it in items) {
      itemsById[it.id] = it;
    }
  }

  @override
  Future<OfflinePage<_FakeItem>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) async {
    return OfflinePage(
      data: cached,
      total: cached.length,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: true,
      source: DataSourceKind.local,
    );
  }

  @override
  Future<_FakeItem?> getById({
    required String accountId,
    required String id,
  }) async => itemsById[id];

  @override
  Future<void> cacheCreated({
    required String accountId,
    required _FakeItem item,
  }) async {
    if (throwOnCache) throw Exception('Disk full');
    cached.add(item);
    itemsById[item.id] = item;
  }

  @override
  Future<void> cacheUpdated({
    required String accountId,
    required _FakeItem item,
  }) async {
    if (throwOnCache) throw Exception('Disk full');
    itemsById[item.id] = item;
  }

  @override
  Future<void> remove({
    required String accountId,
    required String id,
  }) async {
    if (throwOnCache) throw Exception('Disk full');
    cached.removeWhere((i) => i.id == id);
    itemsById.remove(id);
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    cached.clear();
    itemsById.clear();
  }
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late OfflineCrudRepository<_FakeItem, String> repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = OfflineCrudRepository(
      remote: remote,
      local: local,
      getAccountId: () => 'acc-1',
    );
  });

  group('OfflineCrudRepository.getAll', () {
    test('online success returns remote page and caches items', () async {
      remote.items = [const _FakeItem('1', 'Online Item')];

      final page = await repository.getAll();

      expect(page.source, DataSourceKind.remote);
      expect(page.data.first.name, 'Online Item');
      expect(local.cached.length, 1);
    });

    test('online success is fault-tolerant when cache write fails', () async {
      remote.items = [const _FakeItem('1', 'Online Item')];
      local.throwOnCache = true; // Simulating disk full or cache lock

      final page = await repository.getAll();

      expect(page.source, DataSourceKind.remote);
      expect(page.data.first.name, 'Online Item');
    });

    test('offline with NoInternetException fallbacks to local when cache has data', () async {
      local.cached = [const _FakeItem('1', 'Cached Item')];
      remote.errorToThrow = const NoInternetException();

      final page = await repository.getAll();

      expect(page.source, DataSourceKind.local);
      expect(page.data.first.name, 'Cached Item');
    });

    test('offline with empty cache rethrows network exception', () async {
      local.cached = []; // Empty cache!
      remote.errorToThrow = const NoInternetException();

      expect(
        () => repository.getAll(),
        throwsA(isA<NoInternetException>()),
      );
    });

    test('rethrows 401 Unauthorized without falling back to local', () async {
      local.cached = [const _FakeItem('1', 'Cached Item')];
      remote.errorToThrow = const UnauthorizedException();

      expect(
        () => repository.getAll(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('OfflineCrudRepository CRUD sync', () {
    test('create stores in local cache on success', () async {
      final created = await repository.create({'name': 'Created'});

      expect(created.name, 'Created');
      expect(local.itemsById['new-id']?.name, 'Created');
    });

    test('update stores in local cache on success', () async {
      await repository.create({'name': 'Initial'});
      final updated = await repository.update('new-id', {'name': 'Modified'});

      expect(updated.name, 'Modified');
      expect(local.itemsById['new-id']?.name, 'Modified');
    });

    test('deleteById removes from local cache on success', () async {
      await repository.create({'name': 'To Delete'});
      expect(local.itemsById.containsKey('new-id'), isTrue);

      await repository.deleteById('new-id');
      expect(local.itemsById.containsKey('new-id'), isFalse);
    });
  });
}
