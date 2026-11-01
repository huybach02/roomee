import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/contracts/entity_store.dart';
import 'package:roomee/core/offline/contracts/relation_adapter.dart';

class WorkspaceRelationAdapter extends RelationAdapter<WorkspaceModel> {
  static const String globalAccountId = 'global';

  final EntityStore<ProvinceModel, int> provinceStore;
  final EntityStore<WardModel, int> wardStore;
  final EntityStore<UserModel, String> userStore;

  WorkspaceRelationAdapter({
    required this.provinceStore,
    required this.wardStore,
    required this.userStore,
  });

  @override
  Future<void> saveRelations(
    String accountId,
    List<WorkspaceModel> entities,
  ) async {
    final provinces = <int, ProvinceModel>{};
    final wards = <int, WardModel>{};
    final users = <String, UserModel>{};

    for (final ws in entities) {
      if (ws.province != null) {
        provinces[ws.province!.id] = ws.province!;
      }
      if (ws.ward != null) {
        wards[ws.ward!.id] = ws.ward!;
      }
      if (ws.user != null) {
        users[ws.user!.id] = ws.user!;
      }
    }

    await Future.wait([
      if (provinces.isNotEmpty)
        provinceStore.putMany(
          accountId: globalAccountId,
          entities: provinces.values.toList(),
        ),
      if (wards.isNotEmpty)
        wardStore.putMany(
          accountId: globalAccountId,
          entities: wards.values.toList(),
        ),
      if (users.isNotEmpty)
        userStore.putMany(
          accountId: accountId,
          entities: users.values.toList(),
        ),
    ]);
  }

  @override
  Future<List<WorkspaceModel>> hydrate(
    String accountId,
    List<WorkspaceModel> entities,
  ) async {
    final provinceIds = entities.map((ws) => ws.provinceId).toSet();
    final wardIds = entities.map((ws) => ws.wardId).toSet();
    final userIds = entities
        .map((ws) => ws.userId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final results = await Future.wait([
      Future.wait(
        provinceIds.map(
          (id) => provinceStore.getById(accountId: globalAccountId, id: id),
        ),
      ),
      Future.wait(
        wardIds.map(
          (id) => wardStore.getById(accountId: globalAccountId, id: id),
        ),
      ),
      Future.wait(
        userIds.map(
          (id) => userStore.getById(accountId: accountId, id: id),
        ),
      ),
    ]);

    final provinceMap = {
      for (final p in results[0].whereType<ProvinceModel>()) p.id: p,
    };
    final wardMap = {
      for (final w in results[1].whereType<WardModel>()) w.id: w,
    };
    final userMap = {
      for (final u in results[2].whereType<UserModel>()) u.id: u,
    };

    return entities.map((ws) {
      return ws.copyWith(
        province: provinceMap[ws.provinceId] ?? ws.province,
        ward: wardMap[ws.wardId] ?? ws.ward,
        user: userMap[ws.userId] ?? ws.user,
      );
    }).toList();
  }

  @override
  Future<void> clearRelations(String accountId) async {
    await userStore.clearAccount(accountId: accountId);
  }
}
