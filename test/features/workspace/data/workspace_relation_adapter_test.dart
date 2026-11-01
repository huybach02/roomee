import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/user_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';
import 'package:roomee/features/workspace/data/codecs/workspace_model_codec.dart';
import 'package:roomee/features/workspace/data/workspace_relation_adapter.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  late Directory directory;
  late CacheBoxes boxes;
  late HiveEntityStore<ProvinceModel, int> provinceStore;
  late HiveEntityStore<WardModel, int> wardStore;
  late HiveEntityStore<UserModel, String> userStore;
  late WorkspaceRelationAdapter adapter;

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
    directory = await Directory.systemTemp.createTemp('workspace_adapter_test');
    Hive.init(directory.path);
    boxes = await CacheBoxes.open();

    provinceStore = HiveEntityStore(
      box: boxes.provinces,
      codec: const ProvinceModelCodec(),
    );
    wardStore = HiveEntityStore(
      box: boxes.wards,
      codec: const WardModelCodec(),
    );
    userStore = HiveEntityStore(
      box: boxes.users,
      codec: const UserModelCodec(),
    );

    adapter = WorkspaceRelationAdapter(
      provinceStore: provinceStore,
      wardStore: wardStore,
      userStore: userStore,
    );
  });

  tearDown(() async {
    await boxes.metadata.close();
    await boxes.workspaces.close();
    await boxes.users.close();
    await boxes.provinces.close();
    await boxes.wards.close();
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  group('WorkspaceModelCodec', () {
    const codec = WorkspaceModelCodec();

    test('toJson strips nested relation objects, keeping foreign keys', () {
      const ws = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Khu Trọ 1',
        area: 150.0,
        provinceId: 92,
        wardId: 310,
        address: '123 Đường 30/4',
        contactName: 'Chủ Trọ A',
        contactPhone: '0900000001',
        province: testProvince,
        ward: testWard,
        user: testUser,
      );

      final json = codec.toJson(ws);

      expect(json['id'], 'ws-1');
      expect(json['userId'], 'user-1');
      expect(json['provinceId'], 92);
      expect(json['wardId'], 310);
      expect(json.containsKey('province'), isFalse);
      expect(json.containsKey('ward'), isFalse);
      expect(json.containsKey('user'), isFalse);
    });

    test('fromJson restores WorkspaceModel with null relations ready for hydration', () {
      final json = {
        'id': 'ws-1',
        'userId': 'user-1',
        'name': 'Khu Trọ 1',
        'area': 150.0,
        'provinceId': 92,
        'wardId': 310,
        'address': '123 Đường 30/4',
        'contactName': 'Chủ Trọ A',
        'contactPhone': '0900000001',
      };

      final ws = codec.fromJson(json);

      expect(ws.id, 'ws-1');
      expect(ws.provinceId, 92);
      expect(ws.province, isNull);
      expect(ws.wardId, 310);
      expect(ws.ward, isNull);
      expect(ws.userId, 'user-1');
      expect(ws.user, isNull);
    });
  });

  group('WorkspaceRelationAdapter', () {
    test(
      'saveRelations deduplicates and saves Province & Ward globally and User by account',
      () async {
      // 2 workspaces referencing the SAME user, province, and ward
      final workspaces = [
        const WorkspaceModel(
          id: 'ws-1',
          userId: 'user-1',
          name: 'Khu Trọ 1',
          area: 100.0,
          provinceId: 92,
          wardId: 310,
          address: 'Địa chỉ 1',
          contactName: 'A',
          contactPhone: '0901',
          province: testProvince,
          ward: testWard,
          user: testUser,
        ),
        const WorkspaceModel(
          id: 'ws-2',
          userId: 'user-1',
          name: 'Khu Trọ 2',
          area: 200.0,
          provinceId: 92,
          wardId: 310,
          address: 'Địa chỉ 2',
          contactName: 'A',
          contactPhone: '0901',
          province: testProvince,
          ward: testWard,
          user: testUser,
        ),
      ];

      await adapter.saveRelations('account-1', workspaces);

      // Verify global scope for province and ward
      expect(
        await provinceStore.getById(accountId: 'global', id: 92),
        isNotNull,
      );
      expect(await wardStore.getById(accountId: 'global', id: 310), isNotNull);
      expect(await provinceStore.count(accountId: 'global'), 1);
      expect(await wardStore.count(accountId: 'global'), 1);

      // Verify account scope for user
      expect(
        await userStore.getById(accountId: 'account-1', id: 'user-1'),
        isNotNull,
      );
      expect(
        await userStore.getById(accountId: 'account-2', id: 'user-1'),
        isNull,
      );
      expect(await userStore.count(accountId: 'account-1'), 1);
    });

    test('hydrate populates relations from cache gracefully', () async {
      // Pre-populate stores
      await provinceStore.put(accountId: 'global', entity: testProvince);
      await wardStore.put(accountId: 'global', entity: testWard);
      await userStore.put(accountId: 'account-1', entity: testUser);

      // Workspaces with raw IDs only
      final rawWorkspaces = [
        const WorkspaceModel(
          id: 'ws-1',
          userId: 'user-1',
          name: 'Khu Trọ 1',
          area: 100.0,
          provinceId: 92,
          wardId: 310,
          address: 'Địa chỉ 1',
          contactName: 'A',
          contactPhone: '0901',
        ),
        // Workspace with missing user
        const WorkspaceModel(
          id: 'ws-2',
          userId: 'user-non-existent',
          name: 'Khu Trọ 2',
          area: 200.0,
          provinceId: 92,
          wardId: 310,
          address: 'Địa chỉ 2',
          contactName: 'B',
          contactPhone: '0902',
        ),
      ];

      final hydrated = await adapter.hydrate('account-1', rawWorkspaces);

      expect(hydrated.length, 2);
      expect(hydrated[0].province?.fullName, 'Thành phố Cần Thơ');
      expect(hydrated[0].ward?.fullName, 'Phường Ninh Kiều');
      expect(hydrated[0].user?.fullName, 'Chủ Trọ A');

      // Second workspace has valid province/ward, but user remains null without throwing
      expect(hydrated[1].province?.fullName, 'Thành phố Cần Thơ');
      expect(hydrated[1].ward?.fullName, 'Phường Ninh Kiều');
      expect(hydrated[1].user, isNull);
    });

    test('clearRelations purges account user but preserves global province and ward', () async {
      await provinceStore.put(accountId: 'global', entity: testProvince);
      await wardStore.put(accountId: 'global', entity: testWard);
      await userStore.put(accountId: 'account-1', entity: testUser);

      await adapter.clearRelations('account-1');

      expect(await userStore.getById(accountId: 'account-1', id: 'user-1'), isNull);
      expect(await provinceStore.getById(accountId: 'global', id: 92), isNotNull);
      expect(await wardStore.getById(accountId: 'global', id: 310), isNotNull);
    });
  });
}
