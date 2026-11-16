import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';
import 'package:roomee/core/offline/contracts/entity_store.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/datasource/lookup_local_datasource.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/lookup_repository.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';
import 'package:roomee/features/general/data/general_repository.dart';

class _MockBox<E> implements Box<E> {
  final Map<dynamic, E> _data = {};

  @override
  E? get(dynamic key, {E? defaultValue}) => _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, E value) async {
    _data[key] = value;
  }

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final k in keys) {
      _data.remove(k);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeItem {
  final String id;
  final String name;

  const _FakeItem(this.id, this.name);
}

class _FakeRemote implements RemoteCrudDataSource<_FakeItem, String> {
  Object? errorToThrow;

  @override
  Future<ApiResponse<PaginationModel<_FakeItem>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<_FakeItem>> getById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<_FakeItem>> create(Map<String, dynamic> data) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: _FakeItem(data['id'] as String? ?? 'remote-id', data['name'] as String),
      success: true,
      message: 'Created',
    );
  }

  @override
  Future<ApiResponse<_FakeItem>> update(String id, Map<String, dynamic> data) async {
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
  final Map<String, _FakeItem> items = {};

  @override
  String get entityName => 'fake_items';

  @override
  Future<void> cacheCreated({required String accountId, required _FakeItem item}) async {
    items[item.id] = item;
  }

  @override
  Future<void> cacheUpdated({required String accountId, required _FakeItem item}) async {
    items[item.id] = item;
  }

  @override
  Future<void> remove({required String accountId, required String id}) async {
    items.remove(id);
  }

  @override
  _FakeItem itemFromJson(Map<String, dynamic> json) =>
      _FakeItem(json['id'] as String, json['name'] as String);

  @override
  Map<String, dynamic> itemToJson(_FakeItem item) => {
        'id': item.id,
        'name': item.name,
      };

  @override
  Future<_FakeItem?> getById({required String accountId, required String id}) async =>
      items[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGeneralRemote extends GeneralRemoteDataSource {
  Object? errorToThrow;
  Map<String, List<LookupOption>> lookupsToReturn = {};
  List<ProvinceModel> provincesToReturn = [];
  List<WardModel> wardsToReturn = [];

  @override
  Future<ApiResponse<Map<String, List<LookupOption>>>> getLookups({
    List<String>? modules,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: lookupsToReturn,
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<List<ProvinceModel>>> getProvinces() async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: provincesToReturn,
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<List<WardModel>>> getWardsByProvince(int provinceId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ApiResponse(
      data: wardsToReturn,
      success: true,
      message: 'OK',
    );
  }
}

class _FakeEntityStore<T, ID> implements EntityStore<T, ID> {
  final Map<String, T> data = {};

  @override
  EntityCodec<T, ID> get codec => throw UnimplementedError();

  @override
  Future<void> put({required String accountId, required T entity}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> putMany({
    required String accountId,
    required List<T> entities,
    bool force = false,
  }) async {
    for (var i = 0; i < entities.length; i++) {
      data['$accountId:$i'] = entities[i];
    }
  }

  @override
  Future<List<T>> getAll({required String accountId}) async {
    final prefix = '$accountId:';
    return data.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LookupOption model tests', () {
    test('serialization and equality', () {
      final opt = const LookupOption(
        id: 'ws-1',
        label: 'Workspace 1',
        parentId: 'parent-1',
        extra: {'status': 'active'},
      );

      final json = opt.toJson();
      expect(json['id'], 'ws-1');
      expect(json['label'], 'Workspace 1');
      expect(json['parentId'], 'parent-1');
      expect(json['extra'], {'status': 'active'});

      final fromJson = LookupOption.fromJson(json);
      expect(fromJson, equals(opt));
    });
  });

  group('LookupLocalDataSource tests', () {
    late _MockBox<Map> mockBox;
    late LookupLocalDataSource dataSource;

    setUp(() {
      mockBox = _MockBox<Map>();
      dataSource = LookupLocalDataSource(box: mockBox);
    });

    test('saveOptions and getOptions with parentId filtering', () async {
      await dataSource.saveOptions(
        accountId: 'user-1',
        module: 'rooms',
        options: const [
          LookupOption(id: 'r1', label: 'Room 1', parentId: 'ws-1'),
          LookupOption(id: 'r2', label: 'Room 2', parentId: 'ws-1'),
          LookupOption(id: 'r3', label: 'Room 3', parentId: 'ws-2'),
        ],
      );

      final allRooms = await dataSource.getOptions(
        accountId: 'user-1',
        module: 'rooms',
      );
      expect(allRooms.length, 3);

      final ws1Rooms = await dataSource.getOptions(
        accountId: 'user-1',
        module: 'rooms',
        parentId: 'ws-1',
      );
      expect(ws1Rooms.length, 2);
      expect(ws1Rooms.map((r) => r.id), containsAll(['r1', 'r2']));
    });

    test('addOrUpdateOption and removeOption', () async {
      await dataSource.saveOptions(
        accountId: 'user-1',
        module: 'workspaces',
        options: const [
          LookupOption(id: 'w1', label: 'W1'),
        ],
      );

      await dataSource.addOrUpdateOption(
        accountId: 'user-1',
        module: 'workspaces',
        option: const LookupOption(id: 'w2', label: 'W2'),
      );

      var options = await dataSource.getOptions(
        accountId: 'user-1',
        module: 'workspaces',
      );
      expect(options.length, 2);

      await dataSource.removeOption(
        accountId: 'user-1',
        module: 'workspaces',
        id: 'w1',
      );

      options = await dataSource.getOptions(
        accountId: 'user-1',
        module: 'workspaces',
      );
      expect(options.length, 1);
      expect(options.first.id, 'w2');
    });

    test('data isolation: clearAccount only deletes matching account data', () async {
      await dataSource.saveOptions(
        accountId: 'user-A',
        module: 'workspaces',
        options: const [LookupOption(id: 'a1', label: 'A1')],
      );
      await dataSource.saveOptions(
        accountId: 'user-B',
        module: 'workspaces',
        options: const [LookupOption(id: 'b1', label: 'B1')],
      );

      await dataSource.clearAccount(accountId: 'user-A');

      final userAOptions = await dataSource.getOptions(
        accountId: 'user-A',
        module: 'workspaces',
      );
      final userBOptions = await dataSource.getOptions(
        accountId: 'user-B',
        module: 'workspaces',
      );

      expect(userAOptions, isEmpty);
      expect(userBOptions.length, 1);
      expect(userBOptions.first.id, 'b1');
    });
  });

  group('LookupRepository tests', () {
    late _MockBox<Map> mockBox;
    late LookupLocalDataSource localDataSource;
    late _FakeGeneralRemote remoteDataSource;
    late LookupRepository repository;

    setUp(() {
      mockBox = _MockBox<Map>();
      localDataSource = LookupLocalDataSource(box: mockBox);
      remoteDataSource = _FakeGeneralRemote();
      repository = LookupRepository(
        local: localDataSource,
        remote: remoteDataSource,
      );
    });

    test('getOptions fetches from remote and caches when local is empty', () async {
      remoteDataSource.lookupsToReturn = {
        'workspaces': const [
          LookupOption(id: 'ws-1', label: 'Workspace One'),
        ],
      };

      final options = await repository.getOptions(
        accountId: 'user-1',
        module: 'workspaces',
      );

      expect(options.length, 1);
      expect(options.first.label, 'Workspace One');

      // Verify cached in local
      final localOpts = await localDataSource.getOptions(
        accountId: 'user-1',
        module: 'workspaces',
      );
      expect(localOpts.length, 1);
    });

    test('getOptions returns cached immediately and does not fail when offline', () async {
      await localDataSource.saveOptions(
        accountId: 'user-1',
        module: 'workspaces',
        options: const [
          LookupOption(id: 'cached-1', label: 'Cached Workspace'),
        ],
      );

      remoteDataSource.errorToThrow = const NoInternetException();

      final options = await repository.getOptions(
        accountId: 'user-1',
        module: 'workspaces',
      );

      expect(options.length, 1);
      expect(options.first.id, 'cached-1');
    });
  });

  group('OfflineCrudRepository Optimistic Lookup Updates', () {
    late _FakeRemote remote;
    late _FakeLocal local;
    late _MockBox<Map> lookupBox;
    late LookupLocalDataSource lookupLocal;
    late OfflineCrudRepository<_FakeItem, String> crudRepo;

    setUp(() {
      remote = _FakeRemote();
      local = _FakeLocal();
      lookupBox = _MockBox<Map>();
      lookupLocal = LookupLocalDataSource(box: lookupBox);

      crudRepo = OfflineCrudRepository<_FakeItem, String>(
        remote: remote,
        local: local,
        getAccountId: () => 'test-user',
        lookupLocalDataSource: lookupLocal,
        toLookupOption: (item) => LookupOption(id: item.id, label: item.name),
      );
    });

    test('creating offline immediately updates lookup option', () async {
      remote.errorToThrow = const NoInternetException();

      final created = await crudRepo.create({'name': 'Offline Created Room'});

      final lookups = await lookupLocal.getOptions(
        accountId: 'test-user',
        module: 'fake_items',
      );

      expect(lookups.length, 1);
      expect(lookups.first.id, created.id);
      expect(lookups.first.label, 'Offline Created Room');
    });

    test('updating offline immediately updates lookup option', () async {
      remote.errorToThrow = const NoInternetException();

      final created = await crudRepo.create({'name': 'Initial Room'});
      await crudRepo.update(created.id, {'name': 'Renamed Room'});

      final lookups = await lookupLocal.getOptions(
        accountId: 'test-user',
        module: 'fake_items',
      );

      expect(lookups.length, 1);
      expect(lookups.first.id, created.id);
      expect(lookups.first.label, 'Renamed Room');
    });

    test('deleting offline immediately removes lookup option', () async {
      remote.errorToThrow = const NoInternetException();

      final created = await crudRepo.create({'name': 'To Delete'});
      var lookups = await lookupLocal.getOptions(
        accountId: 'test-user',
        module: 'fake_items',
      );
      expect(lookups.length, 1);

      await crudRepo.deleteById(created.id);

      lookups = await lookupLocal.getOptions(
        accountId: 'test-user',
        module: 'fake_items',
      );
      expect(lookups, isEmpty);
    });
  });

  group('GeneralRepository local preloaded tests', () {
    late _FakeEntityStore<ProvinceModel, int> provinceStore;
    late _FakeEntityStore<WardModel, int> wardStore;
    late GeneralRepository generalRepo;

    setUp(() {
      provinceStore = _FakeEntityStore<ProvinceModel, int>();
      wardStore = _FakeEntityStore<WardModel, int>();

      generalRepo = GeneralRepository(
        provinceStore: provinceStore,
        wardStore: wardStore,
      );
    });

    test('getProvinces reads from provinceStore and returns sorted list', () async {
      await provinceStore.putMany(
        accountId: GeneralRepository.globalAccountId,
        entities: const [
          ProvinceModel(id: 2, fullName: 'Đà Nẵng', code: 2, codeName: 'da_nang'),
          ProvinceModel(id: 1, fullName: 'Hà Nội', code: 1, codeName: 'ha_noi'),
        ],
      );

      final provinces = await generalRepo.getProvinces();
      expect(provinces.length, 2);
      expect(provinces[0].fullName, 'Hà Nội');
      expect(provinces[1].fullName, 'Đà Nẵng');
    });

    test('getWardsByProvince reads from wardStore, filters by provinceId and returns sorted list', () async {
      await wardStore.putMany(
        accountId: GeneralRepository.globalAccountId,
        entities: const [
          WardModel(id: 11, fullName: 'Phường B', code: 11, codeName: 'phuong_b', provinceId: 1),
          WardModel(id: 10, fullName: 'Phường A', code: 10, codeName: 'phuong_a', provinceId: 1),
          WardModel(id: 20, fullName: 'Phường C', code: 20, codeName: 'phuong_c', provinceId: 2),
        ],
      );

      final wards = await generalRepo.getWardsByProvince(1);
      expect(wards.length, 2);
      expect(wards[0].fullName, 'Phường A');
      expect(wards[1].fullName, 'Phường B');
    });
  });
}
