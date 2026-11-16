import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/datasource/lookup_local_datasource.dart';
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
  Map<String, dynamic>? lastCreateData;

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
    lastCreateData = data;
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
  Object? errorToThrow;
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
    if (errorToThrow != null) throw errorToThrow!;
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
    SyncMutationStatus? status,
  }) async {
    return mutations
        .where((m) =>
            (module == null || m.module == module) &&
            (status == null || m.status == status))
        .toList();
  }

  @override
  Future<void> removeMutations({
    required String accountId,
    required List<String> mutationIds,
  }) async {
    mutations.removeWhere((m) => mutationIds.contains(m.id));
  }

  @override
  Future<void> markMutationsAsInFlight({
    required String accountId,
    required List<String> mutationIds,
  }) async {
    for (var i = 0; i < mutations.length; i++) {
      if (mutationIds.contains(mutations[i].id)) {
        mutations[i] =
            mutations[i].copyWith(status: SyncMutationStatus.inFlight);
      }
    }
  }

  @override
  Future<void> resetInFlightMutations({String? accountId}) async {
    for (var i = 0; i < mutations.length; i++) {
      if (mutations[i].status == SyncMutationStatus.inFlight) {
        mutations[i] =
            mutations[i].copyWith(status: SyncMutationStatus.pending);
      }
    }
  }

  @override
  Future<void> markMutationsAsFailed({
    required String accountId,
    required List<SyncRejectedMutationDto> failures,
  }) async {
    for (final f in failures) {
      final idx = mutations.indexWhere((m) => m.id == f.id);
      if (idx != -1) {
        mutations[idx] = mutations[idx].copyWith(
          status: SyncMutationStatus.failed,
          errorMessage: f.reason,
          statusCode: f.statusCode,
          errorDetails: f.details,
          failedAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> resetMutationToPending({
    required String accountId,
    required String mutationId,
    Map<String, dynamic>? updatedData,
  }) async {
    final idx = mutations.indexWhere((m) => m.id == mutationId);
    if (idx != -1) {
      mutations[idx] = mutations[idx].copyWith(
        status: SyncMutationStatus.pending,
        data: updatedData ?? mutations[idx].data,
      );
    }
  }

  @override
  Future<Set<String>> getProtectedCreateEntityIds({
    required String accountId,
    String? module,
  }) async {
    return mutations
        .where((m) =>
            m.action == SyncMutationAction.create &&
            (module == null || m.module == module))
        .map((m) => m.entityId)
        .toSet();
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    mutations.clear();
  }

  @override
  Future<int> purgeExpired({required Duration maxAge}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final before = mutations.length;
    mutations.removeWhere((m) => m.createdAt.isBefore(cutoff));
    return before - mutations.length;
  }
}

class _FakeLookupLocalDataSource implements ILookupLocalDataSource {
  final Map<String, List<LookupOption>> optionsByModule = {};

  @override
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
  }) async =>
      optionsByModule[module] ?? [];

  @override
  Future<void> saveOptions({
    required String accountId,
    required String module,
    required List<LookupOption> options,
  }) async {
    optionsByModule[module] = List.from(options);
  }

  @override
  Future<void> addOrUpdateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {
    final list = optionsByModule.putIfAbsent(module, () => []);
    list.removeWhere((o) => o.id.toString() == option.id.toString());
    list.add(option);
  }

  @override
  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  }) async {
    final list = optionsByModule[module];
    list?.removeWhere((o) => o.id.toString() == id.toString());
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    optionsByModule.clear();
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

    test('create sends generated id online and reuses it on offline fallback',
        () async {
      remote.errorToThrow = const TimeoutException();

      final created = await repository.create({'name': 'Timed Out'});

      // ID được sinh trước khi gọi online và gửi kèm request -> server tạo
      // đúng bản ghi đó, lần sync lại sau chỉ gặp 23505 thay vì tạo bản trùng.
      expect(remote.lastCreateData?['id'], isNotNull);
      expect(remote.lastCreateData!['id'], created.id);
      expect(mutationStore.mutations.first.entityId, created.id);
    });

    test('create uses id provided by caller instead of generating a new one',
        () async {
      remote.errorToThrow = const TimeoutException();

      final created =
          await repository.create({'id': 'caller-id', 'name': 'Given Id'});

      expect(remote.lastCreateData!['id'], 'caller-id');
      expect(created.id, 'caller-id');
      expect(mutationStore.mutations.first.entityId, 'caller-id');
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

    test('pendingMutationCount reports queued mutations', () async {
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-1',
        ),
      );

      expect(await repository.pendingMutationCount(), 1);
    });

    test('flushPendingMutations pushes only mutations and drops applied ones',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(appliedMutationIds: ['mut-1'], entities: {}),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-1',
          data: {'name': 'Offline Item'},
        ),
      );

      await repo.flushPendingMutations();

      expect(fakeGeneral.syncCallCount, 1);
      expect(fakeGeneral.lastMutations?.single.id, 'mut-1');
      // Chỉ push, không gửi entities để đối soát
      expect(fakeGeneral.lastSyncEntities, isEmpty);
      expect(mutationStore.mutations, isEmpty);
    });

    test('flushPendingMutations keeps mutations when server call fails',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.errorToThrow = const NoInternetException();

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-1',
        ),
      );

      await repo.flushPendingMutations();

      // Không mất phiếu khi gửi thất bại
      expect(mutationStore.mutations.length, 1);
    });

    test(
        'marks rejected mutations as failed and does not resend them on subsequent reconcile',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: [],
          rejectedMutations: [
            SyncRejectedMutationDto(
              id: 'mut-fail',
              module: 'fake_items',
              action: 'create',
              entityId: 'item-fail',
              statusCode: 400,
              reason: 'Validation failed: Name already exists',
            ),
          ],
          entities: {},
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
        reconcileCooldown: Duration.zero,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-fail',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-fail',
          data: {'name': 'Duplicate'},
        ),
      );

      await repo.syncNow();

      // Phiếu được chuyển sang failed kèm mã lỗi và lý do
      final failedList = await repo.getFailedMutations();
      expect(failedList.length, 1);
      expect(failedList.first.id, 'mut-fail');
      expect(failedList.first.status, SyncMutationStatus.failed);
      expect(failedList.first.statusCode, 400);
      expect(failedList.first.errorMessage, contains('Validation failed'));
      expect(await repo.pendingMutationCount(), 0);
      expect(repo.syncSuccessNotifier.value, isFalse);

      // Lần reconcile tiếp theo: không gửi lại phiếu failed
      fakeGeneral.lastMutations = null;
      fakeGeneral.syncCallCount = 0;
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: [],
          rejectedMutations: [],
          entities: {},
        ),
      );

      await repo.syncNow();
      // Vì không còn phiếu pending và local rỗng nên không gửi request sync thừa
      expect(fakeGeneral.syncCallCount, 0);
      expect(fakeGeneral.lastMutations, isNull);
    });

    test(
        'protects offline created records from needDelete when mutation is pending or failed',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: [],
          rejectedMutations: [],
          entities: {
            'fake_items': SyncResultDto(
              needDelete: ['offline-draft-id', 'server-deleted-id'],
              needUpdate: [],
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
        reconcileCooldown: Duration.zero,
      );

      // Cả 2 item đều đang có ở local
      local.itemsById['offline-draft-id'] =
          const _FakeItem('offline-draft-id', 'Draft');
      local.itemsById['server-deleted-id'] =
          const _FakeItem('server-deleted-id', 'Old Item');

      // mutationStore có phiếu create cho offline-draft-id
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-draft',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'offline-draft-id',
        ),
      );

      await repo.syncNow();

      // Bản ghi offline-draft-id ĐƯỢC BẢO VỆ, KHÔNG BỊ XÓA!
      expect(local.itemsById.containsKey('offline-draft-id'), isTrue);
      // Bản ghi thực sự bị xóa trên server vẫn được dọn dẹp bình thường
      expect(local.itemsById.containsKey('server-deleted-id'), isFalse);
    });

    test('discardMutation removes mutation and deletes local record for create',
        () async {
      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: _FakeGeneralRemote(),
        syncMutationStore: mutationStore,
      );

      local.itemsById['item-discard'] =
          const _FakeItem('item-discard', 'To discard');

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-discard',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-discard',
        ),
      );

      await repo.discardMutation(mutationId: 'mut-discard');

      // Cả phiếu và bản ghi cục bộ đều bị xóa
      expect(mutationStore.mutations, isEmpty);
      expect(local.itemsById.containsKey('item-discard'), isFalse);
    });

    test('retryFailedMutation resets status to pending and re-queues', () async {
      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: _FakeGeneralRemote(),
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-edit',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-edit',
          status: SyncMutationStatus.failed,
          errorMessage: 'Name error',
          data: {'name': 'Bad Name'},
        ),
      );

      expect(await repo.failedMutationCount(), 1);

      await repo.retryFailedMutation(
        mutationId: 'mut-edit',
        updatedData: {'name': 'Good Name'},
      );

      expect(await repo.failedMutationCount(), 0);
      expect(await repo.pendingMutationCount(), 1);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final pending = await mutationStore.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.single.data?['name'], 'Good Name');
    });

    test(
        'schedules trailing sync when called during cooldown instead of dropping',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        reconcileCooldown: const Duration(milliseconds: 80),
      );

      local.syncItemsToReturn = [const SyncItemDto(id: '1')];
      remote.items = [const _FakeItem('1', 'Item 1')];

      // Lượt 1: thành công ngay
      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeGeneral.syncCallCount, 1);

      // Lượt 2: gọi trong lúc đang cooldown
      local.syncItemsToReturn = [
        const SyncItemDto(id: '1'),
        const SyncItemDto(id: '2'),
      ];
      await repo.getAll();

      // Tại thời điểm 20ms (< 80ms): Lượt 2 chưa chạy vì đang trong khoảng nghỉ
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeGeneral.syncCallCount, 1);

      // Chờ hết khoảng nghỉ 80ms (chờ thêm 100ms)
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Lượt 2 ĐÃ TỰ ĐỘNG CHẠY BÙ bởi Trailing Timer!
      expect(fakeGeneral.syncCallCount, 2);
    });

    test(
        'does not apply cooldown when previous sync failed, allowing immediate retry',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.errorToThrow = const NoInternetException();

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        reconcileCooldown: const Duration(seconds: 30),
      );

      local.syncItemsToReturn = [const SyncItemDto(id: '1')];
      remote.items = [const _FakeItem('1', 'Item 1')];

      // Lượt 1: Thất bại do lỗi mạng
      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeGeneral.syncCallCount, 1);
      expect(repo.syncSuccessNotifier.value, isFalse);

      // Mạng hồi phục (sửa fakeGeneral thành công)
      fakeGeneral.errorToThrow = null;

      // Gọi lại ngay (e.g. lính canh báo mạng về)
      await repo.getAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Không bị chặn bởi cooldown 30s vì lượt trước thất bại!
      expect(fakeGeneral.syncCallCount, 2);
      expect(repo.syncSuccessNotifier.value, isTrue);
    });

    test(
        'marks pending mutations as inFlight during reconcile and resets to pending on failure',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.errorToThrow = const NoInternetException();

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-fail',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-fail',
        ),
      );

      await repo.syncNow();

      // Sau khi lỗi mạng, phiếu phải được khôi phục về pending
      final pending = await mutationStore.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.length, 1);
      expect(pending.first.id, 'mut-fail');
      expect(pending.first.status, SyncMutationStatus.pending);
    });

    test(
        'in-flight mutations are removed on ACK while concurrent edits remain pending',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.delay = const Duration(milliseconds: 50);
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: ['mut-inflight'],
          entities: {},
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-inflight',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-race',
          data: {'name': 'Hoa Lan'},
        ),
      );

      // Bắt đầu đồng bộ chạy nền
      final syncFuture = repo.syncNow();

      // Chờ một chút để sync chuyển mut-inflight sang inFlight
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final inFlight = await mutationStore.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.inFlight,
      );
      expect(inFlight.length, 1);
      expect(inFlight.first.id, 'mut-inflight');

      // Người dùng chỉnh sửa bản ghi offline trong lúc sync đang in-flight
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-concurrent',
          module: 'fake_items',
          action: SyncMutationAction.update,
          entityId: 'item-race',
          data: {'name': 'Hoa Sứ'},
        ),
      );

      // Đợi sync hoàn tất
      await syncFuture;

      // mut-inflight đã được xóa do server ACK, nhưng mut-concurrent vẫn còn nguyên trong sổ!
      final allMutations =
          await mutationStore.getMutations(accountId: 'acc-1');
      expect(allMutations.length, 1);
      expect(allMutations.first.id, 'mut-concurrent');
      expect(allMutations.first.status, SyncMutationStatus.pending);
      expect(allMutations.first.data?['name'], 'Hoa Sứ');
    });

    test(
        'protects uncommitted pending edits from being overwritten by older needUpdate response',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.delay = const Duration(milliseconds: 40);
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: ['mut-1'],
          entities: {
            'fake_items': SyncResultDto(
              needUpdate: [
                {'id': 'item-concurrent', 'name': 'Old Name From Server'},
                {'id': 'item-synced', 'name': 'Synced Record Canonical'},
              ],
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

      // mut-1 đang được gửi lên
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-synced',
        ),
      );

      final syncFuture = repo.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Người dùng chỉnh sửa item-concurrent trong lúc sync đang chạy -> sinh mut-concurrent (pending)
      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-concurrent',
          module: 'fake_items',
          action: SyncMutationAction.update,
          entityId: 'item-concurrent',
          data: {'name': 'New Uncommitted Edit'},
        ),
      );

      await syncFuture;

      // needUpdate chỉ áp dụng item-synced, còn item-concurrent được bảo vệ (không bị đè)
      expect(local.appliedSyncResult?.needUpdate.length, 1);
      expect(local.appliedSyncResult?.needUpdate.first['id'], 'item-synced');
    });

    test(
        'getAll flushes pending mutations before querying remote server',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: ['mut-pending'],
          entities: {},
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-pending',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-pending',
          data: {'name': 'Created Offline'},
        ),
      );

      expect(await repo.pendingMutationCount(), 1);

      remote.items = [
        const _FakeItem('item-pending', 'Created Offline From Remote'),
      ];

      final page = await repo.getAll();

      // Trước khi remote.getAll() trả về, syncNow đã được gọi và áp dụng thành công mut-pending
      expect(fakeGeneral.syncCallCount, 1);
      expect(await repo.pendingMutationCount(), 0);
      expect(page.data.first.name, 'Created Offline From Remote');
    });

    test(
        'getAll proceeds when syncNow exceeds syncTimeout without hanging',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.delay = const Duration(milliseconds: 150);

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
        syncTimeout: const Duration(milliseconds: 20),
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-slow',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-slow',
        ),
      );

      remote.items = [const _FakeItem('1', 'Remote Item')];

      // Dù syncNow bị timeout sau 20ms, getAll vẫn không bị chặn chết và tiếp tục thực hiện
      final page = await repo.getAll();
      expect(page.data.first.name, 'Remote Item');
    });

    test(
        'syncIfPending automatically triggers syncNow when pending mutations exist and online',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: ['mut-init'],
          entities: {},
        ),
      );

      await mutationStore.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-init',
          module: 'fake_items',
          action: SyncMutationAction.create,
          entityId: 'item-init',
        ),
      );

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
      );

      await repo.syncIfPending();

      expect(fakeGeneral.syncCallCount, 1);
      final remaining = await repo.pendingMutationCount();
      expect(remaining, 0);
    });

    test(
        '_reconcile updates lookupLocalDataSource with safeNeedDelete and safeNeedUpdate',
        () async {
      final fakeGeneral = _FakeGeneralRemote();
      fakeGeneral.syncResponse = const ApiResponse(
        success: true,
        message: 'OK',
        data: SyncResponseDto(
          appliedMutationIds: [],
          entities: {
            'fake_items': SyncResultDto(
              needDelete: ['item-del'],
              needUpdate: [
                {'id': 'item-1', 'name': 'Updated via Sync'},
              ],
            ),
          },
        ),
      );

      final lookupLocal = _FakeLookupLocalDataSource();
      lookupLocal.optionsByModule['fake_items'] = [
        const LookupOption(id: 'item-del', label: 'Item To Delete'),
        const LookupOption(id: 'item-1', label: 'Old Name'),
      ];

      local.syncItemsToReturn = [
        const SyncItemDto(id: 'item-1', updatedAt: '2026-01-01T00:00:00Z'),
      ];

      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        generalRemote: fakeGeneral,
        syncMutationStore: mutationStore,
        lookupLocalDataSource: lookupLocal,
        toLookupOption: (item) => LookupOption(id: item.id, label: item.name),
      );

      await repo.syncNow();

      final options = lookupLocal.optionsByModule['fake_items']!;
      expect(options.any((o) => o.id == 'item-del'), isFalse);
      final updatedOption = options.firstWhere((o) => o.id == 'item-1');
      expect(updatedOption.label, 'Updated via Sync');
    });

    test('create, update, deleteById update lookupLocalDataSource', () async {
      final lookupLocal = _FakeLookupLocalDataSource();
      final repo = OfflineCrudRepository(
        remote: remote,
        local: local,
        getAccountId: () => 'acc-1',
        syncMutationStore: mutationStore,
        lookupLocalDataSource: lookupLocal,
        toLookupOption: (item) => LookupOption(id: item.id, label: item.name),
      );

      // Create
      final created = await repo.create({'name': 'Created Item'});
      expect(created.name, 'Created Item');
      var options = lookupLocal.optionsByModule['fake_items']!;
      expect(options.length, 1);
      expect(options.first.label, 'Created Item');

      // Update
      await repo.update('new-id', {'name': 'Updated Item'});
      options = lookupLocal.optionsByModule['fake_items']!;
      expect(options.length, 1);
      expect(options.first.label, 'Updated Item');

      // Delete
      await repo.deleteById('new-id');
      options = lookupLocal.optionsByModule['fake_items']!;
      expect(options.isEmpty, isTrue);
    });
  });
}
