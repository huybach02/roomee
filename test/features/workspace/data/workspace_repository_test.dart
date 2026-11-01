import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';

class _FakeWorkspaceRemote implements RemoteCrudDataSource<WorkspaceModel, String> {
  Object? errorToThrow;
  List<WorkspaceModel> workspaces = [];

  @override
  Future<ApiResponse<PaginationModel<WorkspaceModel>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: PaginationModel(
        data: workspaces,
        total: workspaces.length,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> getById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: workspaces.firstWhere((w) => w.id == id),
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> create(Map<String, dynamic> data) async {
    if (errorToThrow != null) throw errorToThrow!;
    final ws = WorkspaceModel(
      id: 'ws-new',
      userId: 'user-1',
      name: data['name'] as String,
      area: 100.0,
      provinceId: 92,
      wardId: 310,
      address: 'Đường mới',
      contactName: 'A',
      contactPhone: '0901',
    );
    return ApiResponse(data: ws, success: true, message: 'Created');
  }

  @override
  Future<ApiResponse<WorkspaceModel>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    final existing = workspaces.where((w) => w.id == id).firstOrNull;
    final ws = WorkspaceModel(
      id: id,
      userId: 'user-1',
      name: data['name'] as String? ?? existing?.name ?? 'Default',
      area: (data['area'] as num?)?.toDouble() ?? existing?.area ?? 100.0,
      status: (data['status'] as num?)?.toInt() ?? existing?.status ?? 1,
      provinceId: 92,
      wardId: 310,
      address: 'Đường sửa',
      contactName: 'A',
      contactPhone: '0901',
    );
    return ApiResponse(data: ws, success: true, message: 'Updated');
  }

  @override
  Future<ApiResponse<void>> deleteById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return const ApiResponse(data: null, success: true, message: 'Deleted');
  }
}

class _FakeWorkspaceLocal implements LocalCrudDataSource<WorkspaceModel, String> {
  List<WorkspaceModel> cached = [];

  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<WorkspaceModel> items,
    bool isComplete = false,
  }) async {
    cached.addAll(items);
  }

  @override
  Future<OfflinePage<WorkspaceModel>> queryPage({
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
  Future<WorkspaceModel?> getById({
    required String accountId,
    required String id,
  }) async => cached.firstWhere((w) => w.id == id);

  @override
  Future<void> cacheCreated({
    required String accountId,
    required WorkspaceModel item,
  }) async {
    cached.add(item);
  }

  @override
  Future<void> cacheUpdated({
    required String accountId,
    required WorkspaceModel item,
  }) async {
    final idx = cached.indexWhere((w) => w.id == item.id);
    if (idx >= 0) cached[idx] = item;
  }

  @override
  Future<void> remove({
    required String accountId,
    required String id,
  }) async {
    cached.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    cached.clear();
  }
}

void main() {
  late _FakeWorkspaceRemote remote;
  late _FakeWorkspaceLocal local;
  late WorkspaceRepository repository;

  final sampleWs = WorkspaceModel(
    id: 'ws-1',
    userId: 'user-1',
    name: 'Khu Trọ Hoa Sen',
    area: 120.0,
    provinceId: 92,
    wardId: 310,
    address: 'Đường 30/4',
    contactName: 'Chủ Trọ A',
    contactPhone: '0901',
  );

  setUp(() {
    remote = _FakeWorkspaceRemote();
    local = _FakeWorkspaceLocal();
    final crudRepo = OfflineCrudRepository<WorkspaceModel, String>(
      remote: remote,
      local: local,
      getAccountId: () => 'user-1',
    );
    repository = WorkspaceRepository(crudRepository: crudRepo);
  });

  test('getWorkspaces returns online data and syncs to local cache', () async {
    remote.workspaces = [sampleWs];

    final result = await repository.getWorkspaces();

    expect(result.data.length, 1);
    expect(result.data.first.name, 'Khu Trọ Hoa Sen');
    expect(local.cached.length, 1);
  });

  test('getWorkspaces falls back to local cache on NoInternetException', () async {
    local.cached = [sampleWs];
    remote.errorToThrow = const NoInternetException();

    final result = await repository.getWorkspaces();

    expect(result.data.length, 1);
    expect(result.data.first.name, 'Khu Trọ Hoa Sen');
  });

  test('createWorkspace delegates to crud repository and caches result', () async {
    final created = await repository.createWorkspace({'name': 'Khu Trọ Mới'});

    expect(created.name, 'Khu Trọ Mới');
    expect(local.cached.any((w) => w.id == 'ws-new'), isTrue);
  });

  test('updateWorkspace delegates to crud repository and updates cache', () async {
    local.cached = [sampleWs];

    final updated = await repository.updateWorkspace('ws-1', {'name': 'Khu Trọ Đã Đổi Tên'});

    expect(updated.name, 'Khu Trọ Đã Đổi Tên');
    expect(local.cached.first.name, 'Khu Trọ Đã Đổi Tên');
  });

  test('deleteWorkspace delegates to crud repository and removes from cache', () async {
    local.cached = [sampleWs];

    await repository.deleteWorkspace('ws-1');

    expect(local.cached.isEmpty, isTrue);
  });

  test('toggle status success updates local cache with authoritative status', () async {
    local.cached = [sampleWs];

    final updated = await repository.updateWorkspace('ws-1', {'status': 0});

    expect(updated.status, 0);
    expect(local.cached.first.status, 0);
  });

  test('toggle status failure leaves local cache untouched with original status', () async {
    local.cached = [sampleWs];
    remote.errorToThrow = const ServerException(statusCode: 500);

    expect(
      () => repository.updateWorkspace('ws-1', {'status': 0}),
      throwsA(isA<ServerException>()),
    );

    // Local cache still retains status 1 (not corrupted with status 0!)
    expect(local.cached.first.status, 1);
  });
}
