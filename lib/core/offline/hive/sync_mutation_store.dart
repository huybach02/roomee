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
    SyncMutationStatus? status,
  });

  Future<void> removeMutations({
    required String accountId,
    required List<String> mutationIds,
  });

  Future<void> markMutationsAsInFlight({
    required String accountId,
    required List<String> mutationIds,
  });

  Future<void> resetInFlightMutations({
    String? accountId,
  });

  Future<void> markMutationsAsFailed({
    required String accountId,
    required List<SyncRejectedMutationDto> failures,
  });

  Future<void> resetMutationToPending({
    required String accountId,
    required String mutationId,
    Map<String, dynamic>? updatedData,
  });

  Future<Set<String>> getProtectedCreateEntityIds({
    required String accountId,
    String? module,
  });

  Future<void> clearAccount({
    required String accountId,
  });

  /// Xóa các phiếu chờ đồng bộ đã cũ hơn [maxAge] (tính từ lúc tạo).
  /// Trả về số phiếu đã xóa.
  Future<int> purgeExpired({required Duration maxAge});
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
    // CHÚ Ý: Chỉ gộp vào mutation đang ở trạng thái pending!
    // Tuyệt đối KHÔNG gộp vào mutation đang inFlight (vì payload cũ đang/đã được gửi lên server).
    final existingIndex = existingList.lastIndexWhere(
      (m) =>
          m.entityId == mutation.entityId &&
          m.status == SyncMutationStatus.pending,
    );

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
            status: SyncMutationStatus.pending,
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
            status: SyncMutationStatus.pending,
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
    SyncMutationStatus? status,
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
            if ((module == null || mutation.module == module) &&
                (status == null || mutation.status == status)) {
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
  Future<void> markMutationsAsInFlight({
    required String accountId,
    required List<String> mutationIds,
  }) async {
    if (mutationIds.isEmpty) return;
    for (final id in mutationIds) {
      final key = _mutationKey(accountId, id);
      final raw = box.get(key);
      if (raw != null) {
        try {
          final current =
              SyncMutation.fromJson(Map<String, dynamic>.from(raw));
          if (current.status == SyncMutationStatus.pending) {
            final updated =
                current.copyWith(status: SyncMutationStatus.inFlight);
            await box.put(key, updated.toJson());
          }
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> resetInFlightMutations({String? accountId}) async {
    final prefix = accountId != null ? _accountPrefix(accountId) : 'account:';
    for (final key in box.keys) {
      if (key is String &&
          key.startsWith(prefix) &&
          key.contains(':mutation:')) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final current =
                SyncMutation.fromJson(Map<String, dynamic>.from(raw));
            if (current.status == SyncMutationStatus.inFlight) {
              final updated =
                  current.copyWith(status: SyncMutationStatus.pending);
              await box.put(key, updated.toJson());
            }
          } catch (_) {}
        }
      }
    }
  }

  @override
  Future<void> markMutationsAsFailed({
    required String accountId,
    required List<SyncRejectedMutationDto> failures,
  }) async {
    if (failures.isEmpty) return;
    final now = DateTime.now();

    for (final failure in failures) {
      final key = _mutationKey(accountId, failure.id);
      final raw = box.get(key);
      if (raw != null) {
        try {
          final current =
              SyncMutation.fromJson(Map<String, dynamic>.from(raw));
          final updated = current.copyWith(
            status: SyncMutationStatus.failed,
            errorMessage: failure.reason,
            statusCode: failure.statusCode,
            errorDetails: failure.details,
            failedAt: now,
          );
          await box.put(key, updated.toJson());
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> resetMutationToPending({
    required String accountId,
    required String mutationId,
    Map<String, dynamic>? updatedData,
  }) async {
    final key = _mutationKey(accountId, mutationId);
    final raw = box.get(key);
    if (raw != null) {
      final current =
          SyncMutation.fromJson(Map<String, dynamic>.from(raw));
      final updated = current.copyWith(
        status: SyncMutationStatus.pending,
        data: updatedData ?? current.data,
      );
      await box.put(key, updated.toJson());
    }
  }

  @override
  Future<Set<String>> getProtectedCreateEntityIds({
    required String accountId,
    String? module,
  }) async {
    final prefix = _accountPrefix(accountId);
    final protectedIds = <String>{};

    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final mutation =
                SyncMutation.fromJson(Map<String, dynamic>.from(raw));
            if (mutation.action == SyncMutationAction.create &&
                (module == null || mutation.module == module)) {
              protectedIds.add(mutation.entityId);
            }
          } catch (_) {}
        }
      }
    }
    return protectedIds;
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

  @override
  Future<int> purgeExpired({required Duration maxAge}) async {
    // Khôi phục mọi phiếu inFlight mồ côi (từ phiên trước bị crash) về pending
    await resetInFlightMutations();

    final cutoff = DateTime.now().subtract(maxAge);
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final mutation = SyncMutation.fromJson(Map<String, dynamic>.from(raw));
        if (mutation.createdAt.isBefore(cutoff)) {
          keysToDelete.add(key);
        }
      } catch (_) {
        // Phiếu hỏng không đọc được -> dọn luôn để không kẹt vĩnh viễn
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
    return keysToDelete.length;
  }
}
