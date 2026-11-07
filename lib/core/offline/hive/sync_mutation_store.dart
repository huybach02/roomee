import 'package:hive_ce/hive.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';

abstract interface class ISyncMutationStore {
  Future<void> addMutation({
    required String accountId,
    required SyncMutation mutation,
  });

  Future<List<SyncMutation>> getMutations({
    required String accountId,
    String? module,
  });

  Future<void> removeMutations({
    required String accountId,
    required List<String> mutationIds,
  });

  Future<void> clearAccount({
    required String accountId,
  });
}

class HiveSyncMutationStore implements ISyncMutationStore {
  final Box<Map> box;

  const HiveSyncMutationStore({required this.box});

  String _mutationKey(String accountId, String mutationId) =>
      'account:$accountId:mutation:$mutationId';

  String _accountPrefix(String accountId) => 'account:$accountId:mutation:';

  @override
  Future<void> addMutation({
    required String accountId,
    required SyncMutation mutation,
  }) async {
    final existingList = await getMutations(
      accountId: accountId,
      module: mutation.module,
    );

    // Tìm mutation trước đó của cùng entityId nếu có (Coalescing)
    final existingIndex =
        existingList.indexWhere((m) => m.entityId == mutation.entityId);

    if (existingIndex != -1) {
      final existing = existingList[existingIndex];

      // Trường hợp 1: Đã có 'create' offline
      if (existing.action == SyncMutationAction.create) {
        if (mutation.action == SyncMutationAction.update) {
          // Gộp data mới vào create mutation ban đầu
          final mergedData = {
            ...?existing.data,
            ...?mutation.data,
          };
          final mergedMutation = SyncMutation(
            id: existing.id,
            module: existing.module,
            action: SyncMutationAction.create,
            entityId: existing.entityId,
            data: mergedData,
            createdAt: existing.createdAt,
          );
          await box.put(
            _mutationKey(accountId, existing.id),
            mergedMutation.toJson(),
          );
          return;
        } else if (mutation.action == SyncMutationAction.delete) {
          // Tạo rồi xóa offline khi chưa gửi lên server -> Hủy luôn mutation
          await box.delete(_mutationKey(accountId, existing.id));
          return;
        }
      }

      // Trường hợp 2: Đã có 'update' offline
      if (existing.action == SyncMutationAction.update) {
        if (mutation.action == SyncMutationAction.update) {
          // Gộp các lần update liên tiếp
          final mergedData = {
            ...?existing.data,
            ...?mutation.data,
          };
          final mergedMutation = SyncMutation(
            id: existing.id,
            module: existing.module,
            action: SyncMutationAction.update,
            entityId: existing.entityId,
            data: mergedData,
            createdAt: existing.createdAt,
          );
          await box.put(
            _mutationKey(accountId, existing.id),
            mergedMutation.toJson(),
          );
          return;
        } else if (mutation.action == SyncMutationAction.delete) {
          // Update rồi xóa -> Thay bằng delete mutation
          await box.delete(_mutationKey(accountId, existing.id));
          await box.put(
            _mutationKey(accountId, mutation.id),
            mutation.toJson(),
          );
          return;
        }
      }
    }

    // Không có xung đột trước đó -> Thêm mới mutation
    await box.put(_mutationKey(accountId, mutation.id), mutation.toJson());
  }

  @override
  Future<List<SyncMutation>> getMutations({
    required String accountId,
    String? module,
  }) async {
    final prefix = _accountPrefix(accountId);
    final mutations = <SyncMutation>[];

    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final mutation =
                SyncMutation.fromJson(Map<String, dynamic>.from(raw));
            if (module == null || mutation.module == module) {
              mutations.add(mutation);
            }
          } catch (_) {}
        }
      }
    }

    // Sắp xếp theo thời gian tạo tăng dần (FIFO)
    mutations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return mutations;
  }

  @override
  Future<void> removeMutations({
    required String accountId,
    required List<String> mutationIds,
  }) async {
    final keys = mutationIds.map((id) => _mutationKey(accountId, id)).toList();
    await box.deleteAll(keys);
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    final prefix = _accountPrefix(accountId);
    final keysToDelete =
        box.keys.where((k) => k is String && k.startsWith(prefix)).toList();
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }
}
