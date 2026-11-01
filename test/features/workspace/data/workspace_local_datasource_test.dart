import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/workspace/data/workspace_local_datasource.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  late Directory directory;
  late CacheBoxes boxes;
  late WorkspaceLocalDataSource localDataSource;

  const testProvince = ProvinceModel(
    id: 92,
    code: 92,
    fullName: 'Thành phố Cần Thơ',
    codeName: 'can_tho',
  );

  const testWard = WardModel(
    id: 310,
    code: 310,
    provinceId: 92,
    fullName: 'Phường Ninh Kiều',
    codeName: 'ninh_kieu',
  );

  const testUser = UserModel(
    id: 'user-1',
    email: 'landlord@roomee.vn',
    fullName: 'Chủ Trọ A',
    phoneNumber: '0900000001',
    role: UserRole.landlord,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workspace_local_ds_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();

    localDataSource = WorkspaceLocalDataSource.fromBoxes(boxes);
  });

  tearDown(() async {
    for (final box in boxes.all) {
      await box.close();
    }
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('saveAll and queryPage search, filter, sort and hydrate workspaces', () async {
    final workspaces = [
      WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Hoa Sen',
        area: 120.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 30/4',
        contactName: 'Chủ Trọ A',
        contactPhone: '0900000001',
        status: 1,
        createdAt: DateTime(2026, 1, 1),
        province: testProvince,
        ward: testWard,
        user: testUser,
      ),
      WorkspaceModel(
        id: 'ws-2',
        userId: 'user-1',
        name: 'Khu trọ Hướng Dương',
        area: 250.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường Nguyễn Văn Cừ',
        contactName: 'Chủ Trọ A',
        contactPhone: '0900000001',
        status: 0,
        createdAt: DateTime(2026, 2, 1),
        province: testProvince,
        ward: testWard,
        user: testUser,
      ),
      WorkspaceModel(
        id: 'ws-3',
        userId: 'user-1',
        name: 'Phòng trọ Lan Rừng',
        area: 80.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 3/2',
        contactName: 'Chủ Trọ A',
        contactPhone: '0900000001',
        status: 1,
        createdAt: DateTime(2026, 3, 1),
        province: testProvince,
        ward: testWard,
        user: testUser,
      ),
    ];

    await localDataSource.saveAll(
      accountId: 'account-1',
      items: workspaces,
      isComplete: true,
    );

    // 1. Search Vietnamese accent-insensitive: 'hoa sen' -> matches 'Nhà trọ Hoa Sen'
    final searchPage = await localDataSource.queryPage(
      accountId: 'account-1',
      queryParameters: {'search': 'hoa sen'},
    );
    expect(searchPage.data.length, 1);
    expect(searchPage.data.first.name, 'Nhà trọ Hoa Sen');
    expect(searchPage.data.first.province?.fullName, 'Thành phố Cần Thơ');
    expect(searchPage.data.first.ward?.fullName, 'Phường Ninh Kiều');
    expect(searchPage.data.first.user?.fullName, 'Chủ Trọ A');

    // 2. Filter: status = 1 (active) -> ws-1 and ws-3
    final filterPage = await localDataSource.queryPage(
      accountId: 'account-1',
      queryParameters: {'status': 1, 'sort': 'area:desc'},
    );
    expect(filterPage.data.length, 2);
    expect(filterPage.data.map((w) => w.id), ['ws-1', 'ws-3']); // 120.0 > 80.0
    expect(filterPage.source, DataSourceKind.local);
    expect(filterPage.isComplete, isTrue);

    // 3. getById single entity
    final single = await localDataSource.getById(
      accountId: 'account-1',
      id: 'ws-2',
    );
    expect(single, isNotNull);
    expect(single?.name, 'Khu trọ Hướng Dương');
    expect(single?.province?.fullName, 'Thành phố Cần Thơ');
    expect(single?.user?.fullName, 'Chủ Trọ A');
  });

  test('IWorkspaceLocalDataSource methods and search by province/ward name', () async {
    final IWorkspaceLocalDataSource ds = localDataSource;

    final workspaces = [
      WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Hoa Sen',
        area: 120.0,
        numberOfRooms: 10,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 30/4',
        contactName: 'Chủ Trọ A',
        contactPhone: '0900000001',
        status: 1,
        province: testProvince,
        ward: testWard,
        user: testUser,
      ),
      WorkspaceModel(
        id: 'ws-2',
        userId: 'user-1',
        name: 'Khu trọ Hướng Dương',
        area: 250.0,
        numberOfRooms: 25,
        provinceId: 92,
        wardId: 310,
        address: 'Đường Nguyễn Văn Cừ',
        contactName: 'Chủ Trọ B',
        contactPhone: '0900000002',
        status: 1,
        province: testProvince,
        ward: testWard,
        user: testUser,
      ),
    ];

    // cacheRemotePage
    await ds.cacheRemotePage(
      accountId: 'account-1',
      items: workspaces,
      isComplete: true,
    );

    // Search by province name: 'Cần Thơ' -> matches both
    final provinceSearch = await ds.getWorkspaces(
      accountId: 'account-1',
      queryParameters: {'search': 'cần thơ', 'sort': 'numberOfRooms:desc'},
    );
    expect(provinceSearch.data.length, 2);
    expect(provinceSearch.data.first.id, 'ws-2'); // 25 > 10
    expect(provinceSearch.data.first.province?.fullName, 'Thành phố Cần Thơ');

    // Search by ward name: 'ninh kiều' -> matches both
    final wardSearch = await ds.getWorkspaces(
      accountId: 'account-1',
      queryParameters: {'search': 'ninh kieu'},
    );
    expect(wardSearch.data.length, 2);

    // getWorkspaceById
    final item = await ds.getWorkspaceById(accountId: 'account-1', id: 'ws-1');
    expect(item?.name, 'Nhà trọ Hoa Sen');
    expect(item?.user?.fullName, 'Chủ Trọ A');

    // cacheCreatedWorkspace
    final newWs = WorkspaceModel(
      id: 'ws-new',
      userId: 'user-1',
      name: 'Khu trọ Mới',
      area: 90.0,
      numberOfRooms: 5,
      provinceId: 92,
      wardId: 310,
      address: 'Đường Mới',
      contactName: 'Chủ Trọ C',
      contactPhone: '0900000003',
      province: testProvince,
      ward: testWard,
      user: testUser,
    );
    await ds.cacheCreatedWorkspace(accountId: 'account-1', workspace: newWs);

    final retrievedNew = await ds.getWorkspaceById(accountId: 'account-1', id: 'ws-new');
    expect(retrievedNew?.name, 'Khu trọ Mới');
    expect(retrievedNew?.province?.fullName, 'Thành phố Cần Thơ');

    // cacheUpdatedWorkspace
    final updatedWs = newWs.copyWith(name: 'Khu trọ Đã Sửa');
    await ds.cacheUpdatedWorkspace(accountId: 'account-1', workspace: updatedWs);

    final retrievedUpdated = await ds.getWorkspaceById(accountId: 'account-1', id: 'ws-new');
    expect(retrievedUpdated?.name, 'Khu trọ Đã Sửa');

    // removeWorkspace
    await ds.removeWorkspace(accountId: 'account-1', id: 'ws-new');
    expect(await ds.getWorkspaceById(accountId: 'account-1', id: 'ws-new'), isNull);
  });
}
