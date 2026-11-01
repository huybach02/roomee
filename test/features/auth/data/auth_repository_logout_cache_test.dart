import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';
import 'package:roomee/features/auth/data/auth_local_datasource.dart';
import 'package:roomee/features/auth/data/auth_remote_datasource.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';

class _FakeAuthRemote extends AuthRemoteDataSource {
  bool logoutCalled = false;

  @override
  Future<ApiResponse<void>> logout() async {
    logoutCalled = true;
    return const ApiResponse(data: null, success: true, message: 'OK');
  }
}

void main() {
  late Directory directory;
  late CacheBoxes boxes;
  late AuthLocalDataSource localDataSource;
  late _FakeAuthRemote remoteDataSource;
  late AuthRepository repository;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    localDataSource = AuthLocalDataSource(storage: const FlutterSecureStorage());
    remoteDataSource = _FakeAuthRemote();
    directory = await Directory.systemTemp.createTemp('auth_repo_logout_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();

    repository = AuthRepository(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      cacheBoxes: boxes,
    );
  });

  tearDown(() async {
    for (final box in boxes.all) {
      await box.close();
    }
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('logout clears account Hive cache and session storage for the logged in user', () async {
    // 1. Populate session and cache
    const user = UserModel(id: 'user-123', email: 'test@roomee.vn');
    await localDataSource.saveUser(user);
    await localDataSource.saveToken('token-123');

    await boxes[HiveBoxNames.workspaces].put(CacheKeyBuilder.entity('user-123', 'ws-1'), {'name': 'Ws 1'});
    await boxes[HiveBoxNames.users].put(CacheKeyBuilder.entity('user-123', 'u-1'), {'name': 'User 1'});
    await boxes[HiveBoxNames.metadata].put(CacheKeyBuilder.metadata('user-123', 'workspaces'), {'count': 1});

    // Also populate another user and global data
    await boxes[HiveBoxNames.workspaces].put(CacheKeyBuilder.entity('other-user', 'ws-2'), {'name': 'Ws 2'});
    await boxes[HiveBoxNames.provinces].put(CacheKeyBuilder.entity('global', '92'), {'name': 'Cần Thơ'});

    // 2. Perform logout
    await repository.logout();

    // 3. User session must be cleared
    expect(await localDataSource.getUser(), isNull);
    expect(await localDataSource.getToken(), isNull);

    // 4. User-123 cache in Hive must be cleared
    expect(boxes[HiveBoxNames.workspaces].get(CacheKeyBuilder.entity('user-123', 'ws-1')), isNull);
    expect(boxes[HiveBoxNames.users].get(CacheKeyBuilder.entity('user-123', 'u-1')), isNull);
    expect(boxes[HiveBoxNames.metadata].get(CacheKeyBuilder.metadata('user-123', 'workspaces')), isNull);

    // 5. Other user and global data must be preserved
    expect(boxes[HiveBoxNames.workspaces].get(CacheKeyBuilder.entity('other-user', 'ws-2')), isNotNull);
    expect(boxes[HiveBoxNames.provinces].get(CacheKeyBuilder.entity('global', '92')), isNotNull);
  });
}
