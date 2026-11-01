import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/workspace/data/workspace_local_datasource.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';

class _FakeDynamicRemote implements RemoteCrudDataSource<WorkspaceModel, String> {
  bool isOffline = false;
  Map<String, List<WorkspaceModel>> queryResponses = {};
  int defaultServerTotal = 250;

  @override
  Future<ApiResponse<PaginationModel<WorkspaceModel>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    if (isOffline) {
      throw const NoInternetException();
    }

    final search = queryParameters?['search'] as String?;
    final status = queryParameters?['status'];

    String queryKey = 'default';
    if (search != null) {
      queryKey = 'search_$search';
    } else if (status != null) {
      queryKey = 'status_$status';
    }

    final data = queryResponses[queryKey] ?? [];
    return ApiResponse(
      data: PaginationModel(
        data: data,
        total: defaultServerTotal, // Backend reports 250 records on server
        page: queryParameters?['page'] as int? ?? 1,
        limit: queryParameters?['limit'] as int? ?? 20,
        totalPages: (defaultServerTotal / 20).ceil(),
      ),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> getById(String id) async {
    if (isOffline) {
      throw const NoInternetException();
    }
    return ApiResponse(
      data: WorkspaceModel(
        id: id,
        userId: 'user-1',
        name: 'Khu trọ số $id',
        area: 100.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 30/4',
        contactName: 'Chủ Trọ',
        contactPhone: '0901',
      ),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> create(Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<WorkspaceModel>> update(
    String id,
    Map<String, dynamic> data,
  ) async =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<void>> deleteById(String id) async =>
      throw UnimplementedError();
}

void main() {
  late Directory directory;
  late CacheBoxes boxes;
  late WorkspaceLocalDataSource localDataSource;
  late _FakeDynamicRemote remote;
  late WorkspaceRepository repository;

  WorkspaceModel createWs(String id, String name, {int status = 1}) {
    return WorkspaceModel(
      id: id,
      userId: 'user-1',
      name: name,
      area: 100.0,
      provinceId: 92,
      wardId: 310,
      address: 'Đường 30/4',
      contactName: 'Chủ Trọ',
      contactPhone: '0901',
      status: status,
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('unified_query_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();

    localDataSource = WorkspaceLocalDataSource.fromBoxes(boxes);
    remote = _FakeDynamicRemote();

    final crudRepo = OfflineCrudRepository<WorkspaceModel, String>(
      remote: remote,
      local: localDataSource,
      getAccountId: () => 'user-1',
    );

    repository = WorkspaceRepository(crudRepository: crudRepo);
  });

  tearDown(() async {
    for (final box in boxes.all) {
      await box.close();
    }
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test(
    'Scenario: Multiple online queries accumulate in cache, and offline query computes independent total without deleting missing items',
    () async {
      // 1. First Query: Unfiltered page 1 -> returns 20 items (ws-1 to ws-20)
      final page1Items = List.generate(
        20,
        (i) => createWs('ws-${i + 1}', 'Khu trọ số ${i + 1}'),
      );
      remote.queryResponses['default'] = page1Items;

      final res1 = await repository.getWorkspaces();
      expect(res1.data.length, 20);
      expect(res1.source, DataSourceKind.remote);
      expect(res1.total, 250); // Server reports 250

      expect(boxes[HiveBoxNames.workspaces].length, 20);

      // 2. Second Query: Search 'Hoa Sen' -> returns 3 items (ws-3, ws-21, ws-22)
      // ws-3 already exists, ws-21 and ws-22 are newly discovered
      final searchItems = [
        createWs('ws-3', 'Nhà trọ Hoa Sen 1'),
        createWs('ws-21', 'Nhà trọ Hoa Sen 2'),
        createWs('ws-22', 'Nhà trọ Hoa Sen 3'),
      ];
      remote.queryResponses['search_hoa sen'] = searchItems;

      final res2 = await repository.getWorkspaces(
        queryParameters: {'search': 'hoa sen'},
      );
      expect(res2.data.length, 3);
      expect(res2.source, DataSourceKind.remote);

      // Cache accumulation: ws-1..20 are NOT deleted! 2 new items added -> total 22 in box
      expect(boxes[HiveBoxNames.workspaces].length, 22);

      // 3. Third Query: Filter status = 0 -> returns 2 items (ws-5 and ws-23 with status 0)
      final status0Items = [
        createWs('ws-5', 'Khu trọ số 5', status: 0),
        createWs('ws-23', 'Khu trọ Tạm Dừng', status: 0),
      ];
      remote.queryResponses['status_0'] = status0Items;

      final res3 = await repository.getWorkspaces(
        queryParameters: {'status': 0},
      );
      expect(res3.data.length, 2);

      // Box now has 23 items total (ws-1 to ws-23, with ws-5 updated to status 0)
      expect(boxes[HiveBoxNames.workspaces].length, 23);

      // -------------------------------------------------------------
      // 4. GO OFFLINE (Network disconnected!)
      // -------------------------------------------------------------
      remote.isOffline = true;

      // A. Query offline for 'Hoa Sen':
      final offlineSearch = await repository.getWorkspaces(
        queryParameters: {'search': 'hoa sen'},
      );
      expect(offlineSearch.source, DataSourceKind.local);
      expect(offlineSearch.data.length, 3);
      // Crucial verification: total reflects local matching records (3), NOT 250!
      expect(offlineSearch.total, 3);
      expect(offlineSearch.totalPages, 1);
      expect(offlineSearch.isComplete, isFalse);

      // B. Query offline for status = 0:
      final offlineStatus0 = await repository.getWorkspaces(
        queryParameters: {'status': 0},
      );
      expect(offlineStatus0.source, DataSourceKind.local);
      expect(offlineStatus0.data.length, 2);
      expect(offlineStatus0.total, 2);

      // C. Query offline unfiltered:
      final offlineAll = await repository.getWorkspaces();
      expect(offlineAll.source, DataSourceKind.local);
      // Total equals all 23 cached items
      expect(offlineAll.total, 23);
      expect(offlineAll.data.length, 20); // page 1 limit 20
      expect(offlineAll.hasReachedMax, isFalse); // 20 < 23 -> page 2 exists offline!

      // D. Verify non-destructive caching: ws-1 was not in search or status=0, but still safe in cache!
      final ws1 = await repository.getWorkspaceById('ws-1');
      expect(ws1.name, 'Khu trọ số 1');
    },
  );
}
