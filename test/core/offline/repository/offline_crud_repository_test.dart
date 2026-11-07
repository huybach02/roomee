import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/sync_mutation_store.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

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
  @override
  String get entityName => 'fake_items';

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

  List<SyncItemDto> syncItemsToReturn = [];
  SyncResultDto? appliedSyncResult;

  @override
  Future<void> clearAccount({required String accountId}) async {
    cached.clear();
    itemsById.clear();
  }

  @override
  Future<List<SyncItemDto>> getSyncItems({required String accountId}) async =>
      syncItemsToReturn;

  @override
  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems({
    required String accountId,
  }) async =>
      const {};

  @override
  Future<void> applySyncResult({
    required String accountId,
    required SyncResultDto result,
  }) async {
    appliedSyncResult = result;
    for (final id in result.needDelete) {
      itemsById.remove(id);
      cached.removeWhere((i) => i.id == id);
    }
  }

  @override
  Future<void> applyRelationSync({
    required String accountId,
    required Map<String, SyncResultDto> relationResults,
  }) async {}

  @override
  _FakeItem itemFromJson(Map<String, dynamic> json) =>
      _FakeItem(json['id'].toString(), json['name']?.toString() ?? '');

  @override
  Map<String, dynamic> itemToJson(_FakeItem item) =>
      {'id': item.id, 'name': item.name};
}

class _FakeGeneralRemote extends GeneralRemoteDataSource {
  Map<String, List<SyncItemDto>>? lastSyncEntities;
  List<SyncMutation>? lastMutations;
  int syncCallCount = 0;
  Duration delay = Duration.zero;
  ApiResponse<SyncResponseDto> syncResponse = const ApiResponse(
    success: true,
    message: 'OK',
    data: SyncResponseDto(appliedMutationIds: [], entities: {}),
  );

  @override
  Future<ApiResponse<SyncResponseDto>> sync({
    List<SyncMutation>? mutations,
    required Map<String, List<SyncItemDto>> entities,
  }) async {
    syncCallCount++;
    lastMutations = mutations;
    lastSyncEntities = entities;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return syncResponse;
  }
}

class _FakeSyncMutationStore implements ISyncMutationStore {
  final List<SyncMutation> mutations = [];

  @override
  Future<void> addMutation({
    required String accountId,
    required SyncMutation mutation,
  }) async {
    mutations.add(mutation);
  }

  @override
  Future<List<SyncMutation>> getMutations({
    required String accountId,
    String? module,
  }) async {
    return List.from(mutations);
  }

  @override
  Future<void> removeMutations({
    required String accountId,
    required List<String> mutationIds,
  }) async {
    mutations.removeWhere((m) => mutationIds.contains(m.id));
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    mutations.clear();
  }
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late _FakeSyncMutationStore mutationStore;
  late OfflineCrudRepository<_FakeItem, String> repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    mutationStore = _FakeSyncMutationStore();
    repository = OfflineCrudRepository(
      remote: remote,
      local: local,
      getAccountId: () => 'acc-1',
      syncMutationStore: mutationStore,
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

    test('online success triggers background reconciliation and applies result', () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          entities: {
            'fake_items': SyncResultDto(
              needDelete: ['old-zombie-id'],
            ),
          },
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
      );

      local.itemsById['old-zombie-id'] =
          const _FakeItem('old-zombie-id', 'Zombie');
      local.syncItemsToReturn = [const SyncItemDto(id: 'old-zombie-id')];

      remote.items = [const _FakeItem('1', 'Online Item')];

      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeGeneral.lastSyncEntities, isNotNull);
      expect(
        fakeGeneral.lastSyncEntities!['fake_items']?.first.id,
        'old-zombie-id',
      );
      expect(local.appliedSyncResult?.needDelete, contains('old-zombie-id'));
      expect(local.itemsById.containsKey('old-zombie-id'), isFalse);
    });

    test('cooldown prevents redundant background sync calls on rapid getAll',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        reconcileCooldown: const Duration(seconds: 30),
      );

      local.syncItemsToReturn = [const SyncItemDto(id: '1')];
      remote.items = [const _FakeItem('1', 'Item 1')];

      // Lần 1: kích hoạt sync
      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeGeneral.syncCallCount, 1);

      // Lần 2 (ngay sau đó, e.g. load more): bị chặn bởi cooldown 30s
      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeGeneral.syncCallCount, 1);
    });

    test(
      'coalesces multiple rapid getAll calls into at most one pending trailing sync',
      () async {
        final fakeGeneral = _FakeGeneralRemote();
        fakeGeneral.delay = const Duration(milliseconds: 40);

        final repo = OfflineCrudRepository(
          remote: remote,
          local: local,
          getAccountId: () => 'acc-1',
          generalRemote: fakeGeneral,
          reconcileCooldown: Duration.zero,
        );

        local.syncItemsToReturn = [const SyncItemDto(id: '1')];
        remote.items = [const _FakeItem('1', 'Item 1')];

        // Bắn 3 cuộc gọi getAll() đồng thời
        await Future.wait([
          repo.getAll(),
          repo.getAll(),
          repo.getAll(),
        ]);

        // Chờ sync đầu tiên (40ms) và sync trailing tiếp theo (40ms) hoàn tất
        await Future<void>.delayed(const Duration(milliseconds: 120));

        // Dù gọi 3 lần, tổng số lần sync chỉ là 2 (1 in-flight + 1 trailing)!
        expect(fakeGeneral.syncCallCount, 2);
      },
    );

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

    test('offline create fallback stores in local cache and records create mutation',
        () async {
      remote.errorToThrow = const NoInternetException();

      final created = await repository.create({'name': 'Offline Created'});

      expect(created.name, 'Offline Created');
      expect(created.id, isNotEmpty);
      expect(local.itemsById[created.id]?.name, 'Offline Created');
      expect(mutationStore.mutations.length, 1);
      expect(mutationStore.mutations.first.action, SyncMutationAction.create);
      expect(mutationStore.mutations.first.entityId, created.id);
    });

    test('offline update fallback updates local cache and records update mutation',
        () async {
      // First populate local cache
      local.itemsById['item-1'] = const _FakeItem('item-1', 'Original Name');

      remote.errorToThrow = const NoInternetException();

      final updated =
          await repository.update('item-1', {'name': 'Updated Offline'});

      expect(updated.name, 'Updated Offline');
      expect(local.itemsById['item-1']?.name, 'Updated Offline');
      expect(mutationStore.mutations.length, 1);
      expect(mutationStore.mutations.first.action, SyncMutationAction.update);
      expect(mutationStore.mutations.first.entityId, 'item-1');
    });

    test('offline delete fallback removes from local cache and records delete mutation',
        () async {
      local.itemsById['item-1'] = const _FakeItem('item-1', 'To Delete');

      remote.errorToThrow = const NoInternetException();

      await repository.deleteById('item-1');

      expect(local.itemsById.containsKey('item-1'), isFalse);
      expect(mutationStore.mutations.length, 1);
      expect(mutationStore.mutations.first.action, SyncMutationAction.delete);
      expect(mutationStore.mutations.first.entityId, 'item-1');
    });

    test('syncNow sends pending mutations and removes applied ones on success',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: ['mut-1'],
          entities: {
            'fake_items': SyncResultDto(
              needDelete: ['deleted-server-id'],
            ),
          },
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      // Thêm 1 mutation chờ sync
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-offline-1',
          data: {'name': 'Offline Name'},
        ),
      );

      local.itemsById['deleted-server-id'] =
          const _FakeItem('deleted-server-id', 'Server Deleted');
      local.syncItemsToReturn = [const SyncItemDto(id: 'deleted-server-id')];

      // Kích hoạt sync
      await repo.syncNow();

      expect(fakeGeneral.syncCallCount, 1);
      expect(fakeGeneral.lastMutations?.length, 1);
      expect(fakeGeneral.lastMutations?.first.id, 'mut-1');
      // Mutation mut-1 đã được server xác nhận nên bị xóa khỏi store
      expect(mutationStore.mutations, isEmpty);
      // Kết quả reconcile needDelete đã xóa item tương ứng ở local
      expect(local.itemsById.containsKey('deleted-server-id'), isFalse);
    });
  });
}
