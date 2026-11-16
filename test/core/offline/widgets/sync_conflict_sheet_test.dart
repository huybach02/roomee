import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/sync_mutation_store.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/core/offline/widgets/sync_conflict_sheet.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

class _FakeItem {
  final String id;
  final String name;
  const _FakeItem(this.id, this.name);
}

class _FakeRemote implements RemoteCrudDataSource<_FakeItem, String> {
  @override
  Future<ApiResponse<PaginationModel<_FakeItem>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async =>
      const ApiResponse(
        data: PaginationModel(data: [], total: 0, page: 1, limit: 20, totalPages: 1),
        success: true,
        message: 'OK',
      );

  @override
  Future<ApiResponse<_FakeItem>> getById(String id) async =>
      ApiResponse(data: _FakeItem(id, 'Item $id'), success: true, message: 'OK');

  @override
  Future<ApiResponse<_FakeItem>> create(Map<String, dynamic> data) async =>
      ApiResponse(data: _FakeItem('new-id', data['name'] ?? ''), success: true, message: 'OK');

  @override
  Future<ApiResponse<_FakeItem>> update(String id, Map<String, dynamic> data) async =>
      ApiResponse(data: _FakeItem(id, data['name'] ?? ''), success: true, message: 'OK');

  @override
  Future<ApiResponse<void>> deleteById(String id) async =>
      const ApiResponse(data: null, success: true, message: 'OK');
}

class _FakeLocal implements LocalCrudDataSource<_FakeItem, String> {
  final Map<String, _FakeItem> itemsById = {};

  @override
  String get entityName => 'workspaces';

  @override
  Future<void> remove({required String accountId, required String id}) async {
    itemsById.remove(id);
  }

  @override
  Future<void> applySyncResult({
    required String accountId,
    required SyncResultDto result,
  }) async {
    for (final id in result.needDelete) {
      itemsById.remove(id);
    }
  }

  @override
  Future<void> applyRelationSync({
    required String accountId,
    required Map<String, SyncResultDto> relationResults,
  }) async {}

  @override
  Future<void> cacheCreated({required String accountId, required _FakeItem item}) async {}
  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<_FakeItem> items,
    bool isComplete = false,
  }) async {}

  @override
  Future<void> cacheUpdated({required String accountId, required _FakeItem item}) async {}
  @override
  Future<void> clearAccount({required String accountId}) async {}
  @override
  Future<_FakeItem?> getById({required String accountId, required String id}) async => itemsById[id];
  @override
  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems({required String accountId}) async => {};
  @override
  Future<List<SyncItemDto>> getSyncItems({required String accountId}) async => [];
  @override
  _FakeItem itemFromJson(Map<String, dynamic> json) => _FakeItem(json['id'], json['name']);
  @override
  Map<String, dynamic> itemToJson(_FakeItem item) => {'id': item.id, 'name': item.name};
  @override
  Future<OfflinePage<_FakeItem>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) async =>
      OfflinePage(
        data: itemsById.values.toList(),
        total: itemsById.length,
        page: 1,
        limit: 20,
        totalPages: 1,
        isComplete: true,
        source: DataSourceKind.local,
      );
}

class _FakeSyncStore implements ISyncMutationStore {
  final List<SyncMutation> mutations = [];

  @override
  Future<void> addMutation({required String accountId, required SyncMutation mutation}) async {
    mutations.add(mutation);
  }

  @override
  Future<List<SyncMutation>> getMutations({required String accountId, String? module, SyncMutationStatus? status}) async {
    return mutations
        .where((m) => (module == null || m.module == module) && (status == null || m.status == status))
        .toList();
  }

  @override
  Future<void> removeMutations({required String accountId, required List<String> mutationIds}) async {
    mutations.removeWhere((m) => mutationIds.contains(m.id));
  }

  @override
  Future<void> markMutationsAsInFlight({required String accountId, required List<String> mutationIds}) async {
    for (var i = 0; i < mutations.length; i++) {
      if (mutationIds.contains(mutations[i].id)) {
        mutations[i] = mutations[i].copyWith(status: SyncMutationStatus.inFlight);
      }
    }
  }

  @override
  Future<void> resetInFlightMutations({String? accountId}) async {
    for (var i = 0; i < mutations.length; i++) {
      if (mutations[i].status == SyncMutationStatus.inFlight) {
        mutations[i] = mutations[i].copyWith(status: SyncMutationStatus.pending);
      }
    }
  }

  @override
  Future<void> markMutationsAsFailed({required String accountId, required List<SyncRejectedMutationDto> failures}) async {
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
  Future<void> resetMutationToPending({required String accountId, required String mutationId, Map<String, dynamic>? updatedData}) async {
    final idx = mutations.indexWhere((m) => m.id == mutationId);
    if (idx != -1) {
      mutations[idx] = mutations[idx].copyWith(
        status: SyncMutationStatus.pending,
        data: updatedData ?? mutations[idx].data,
      );
    }
  }

  @override
  Future<Set<String>> getProtectedCreateEntityIds({required String accountId, String? module}) async {
    return mutations
        .where((m) => m.action == SyncMutationAction.create && (module == null || m.module == module))
        .map((m) => m.entityId)
        .toSet();
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    mutations.clear();
  }

  @override
  Future<int> purgeExpired({required Duration maxAge}) async => 0;
}

class _FakeGeneralRemote extends GeneralRemoteDataSource {
  _FakeGeneralRemote() : super(client: ApiClient(baseUrl: 'http://localhost'));

  @override
  Future<ApiResponse<SyncResponseDto>> sync({
    List<SyncMutation>? mutations = const [],
    Map<String, List<SyncItemDto>> entities = const {},
  }) async {
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: SyncResponseDto(),
    );
  }
}

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations.preload();
  });

  group('SyncConflictSheet Tests', () {
    testWidgets('renders list of failed mutations properly', (tester) async {
      final fakeGeneral = _FakeGeneralRemote();
      final mutationStore = _FakeSyncStore();
      final remote = _FakeRemote();
      final local = _FakeLocal();

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
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          status: SyncMutationStatus.failed,
          errorMessage: 'Tên nhà trọ đã tồn tại',
          statusCode: 400,
        ),
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          SyncConflictSheet(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thay đổi chưa được đồng bộ'), findsOneWidget);
      expect(find.text('Tên nhà trọ đã tồn tại'), findsOneWidget);
      expect(find.text('(400)'), findsOneWidget);
      expect(find.text('Tạo mới: workspaces'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('retry button calls retryFailedMutation', (tester) async {
      final fakeGeneral = _FakeGeneralRemote();
      final mutationStore = _FakeSyncStore();
      final remote = _FakeRemote();
      final local = _FakeLocal();

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
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          status: SyncMutationStatus.failed,
          errorMessage: 'Tên nhà trọ đã tồn tại',
          statusCode: 400,
        ),
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          SyncConflictSheet(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Thử lại'));
      await tester.pumpAndSettle();

      // Sau khi thử lại, phiếu chuyển sang pending nên không còn trong failed
      expect(await repo.failedMutationCount(), 0);
      expect(await repo.pendingMutationCount(), 1);
    });
  });
}
