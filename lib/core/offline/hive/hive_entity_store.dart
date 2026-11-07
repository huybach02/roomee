import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../contracts/entity_codec.dart';
import '../contracts/entity_store.dart';
import '../contracts/sync_dtos.dart';
import 'cache_key_builder.dart';

class HiveEntityStore<T, ID> implements EntityStore<T, ID> {
  final Box<Map> box;
  @override
  final EntityCodec<T, ID> codec;

  HiveEntityStore({required this.box, required this.codec});

  String _key(String accountId, ID id) {
    return CacheKeyBuilder.entity(accountId, id.toString());
  }

  String _tombstoneKey(String accountId, Object id) {
    return CacheKeyBuilder.tombstone(accountId, id);
  }

  @override
  Future<void> put({required String accountId, required T entity}) async {
    await putMany(accountId: accountId, entities: [entity]);
  }

  @override
  Future<void> putMany({
    required String accountId,
    required List<T> entities,
  }) async {
    if (entities.isEmpty) return;

    final entries = <String, Map>{};
    final tombstonesToDelete = <String>[];

    for (final entity in entities) {
      final id = codec.getId(entity);
      final key = _key(accountId, id);
      final tombstoneKey = _tombstoneKey(accountId, id.toString());

      final incomingJson = codec.toJson(entity);
      final incomingUpdatedAt = codec.getUpdatedAt(entity) ??
          codec.extractUpdatedAtFromJson(incomingJson);

      // 1. Kiểm tra Tombstone (Bảo vệ bản ghi đã xóa không bị hồi sinh bởi response cũ)
      final tombstone = box.get(tombstoneKey);
      if (tombstone != null) {
        final deletedAt =
            DateTime.tryParse(tombstone['deletedAt']?.toString() ?? '');
        if (incomingUpdatedAt == null ||
            deletedAt == null ||
            !incomingUpdatedAt.isAfter(deletedAt)) {
          // Bỏ qua vì bản ghi đã bị xóa và dữ liệu đến không mới hơn thời điểm xóa
          continue;
        }
        // Dữ liệu đến mới hơn thời điểm xóa -> Cho phép khôi phục và dọn tombstone
        tombstonesToDelete.add(tombstoneKey);
      }

      // 2. So sánh với dữ liệu hiện tại trong local box (Chống ghi đè dữ liệu mới bằng dữ liệu cũ)
      final currentJson = box.get(key);
      if (currentJson != null && incomingUpdatedAt != null) {
        final currentUpdatedAt = codec.extractUpdatedAtFromJson(currentJson);
        if (currentUpdatedAt != null &&
            incomingUpdatedAt.isBefore(currentUpdatedAt)) {
          // Dữ liệu local mới hơn incoming -> Bỏ qua không ghi đè
          continue;
        }
      }

      entries[key] = incomingJson;
    }

    if (tombstonesToDelete.isNotEmpty) {
      await box.deleteAll(tombstonesToDelete);
    }

    if (entries.isNotEmpty) {
      await box.putAll(entries);
    }
  }

  @override
  Future<T?> getById({required String accountId, required ID id}) async {
    final json = box.get(_key(accountId, id));
    if (json == null) return null;

    return codec.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<List<T>> getAll({required String accountId}) async {
    final prefix = 'account:$accountId:';
    final result = <T>[];

    for (final key in box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;

      final json = box.get(key);
      if (json != null) {
        result.add(codec.fromJson(Map<String, dynamic>.from(json)));
      }
    }

    return result;
  }

  @override
  Future<int> count({required String accountId}) async {
    final prefix = 'account:$accountId:';
    var count = 0;
    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<void> delete({required String accountId, required ID id}) async {
    await box.delete(_key(accountId, id));
    await box.put(
      _tombstoneKey(accountId, id.toString()),
      {'deletedAt': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    final prefix = 'account:$accountId:';
    final tombstonePrefix = '$accountId:tombstone:';
    final keys = box.keys
        .where((key) =>
            key is String &&
            (key.startsWith(prefix) || key.startsWith(tombstonePrefix)))
        .toList();

    await box.deleteAll(keys);
  }

  @override
  Future<List<SyncItemDto>> getSyncItems({required String accountId}) async {
    final prefix = 'account:$accountId:';
    final result = <SyncItemDto>[];

    for (final key in box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;

      final json = box.get(key);
      if (json != null) {
        final id = json['id']?.toString();
        final updatedAt =
            json['updatedAt']?.toString() ?? json['updated_at']?.toString();
        if (id != null && id.isNotEmpty) {
          result.add(SyncItemDto(id: id, updatedAt: updatedAt));
        }
      }
    }

    return result;
  }

  @override
  Future<List<T>> applySync({
    required String accountId,
    required SyncResultDto result,
  }) async {
    // -----------------------------------------------------------------
    // Giai đoạn 1: Parse toàn bộ needUpdate trước (Chưa chạm vào Box)
    // Nếu có bất kỳ bản ghi nào không parse được -> dừng ngay lập tức,
    // giữ nguyên vẹn dữ liệu cũ để tránh partial / corrupted mutation.
    // -----------------------------------------------------------------
    final updatedEntities = <T>[];

    if (result.needUpdate.isNotEmpty) {
      for (final json in result.needUpdate) {
        try {
          updatedEntities.add(codec.fromJson(json));
        } catch (error, stackTrace) {
          final id = json['id'] ?? 'unknown';
          debugPrint(
            '[HiveEntityStore] ❌ Failed to parse sync item: '
            'box="${box.name}", id="$id", error=$error\n$stackTrace',
          );
          throw FormatException(
            'Failed to parse sync entity in "${box.name}" for id "$id": $error',
          );
        }
      }
    }

    // -----------------------------------------------------------------
    // Giai đoạn 2: Thực hiện Mutation khi toàn bộ dữ liệu hợp lệ
    // -----------------------------------------------------------------
    if (updatedEntities.isNotEmpty) {
      await putMany(accountId: accountId, entities: updatedEntities);
    }

    if (result.needDelete.isNotEmpty) {
      final keysToDelete = result.needDelete
          .map((id) => CacheKeyBuilder.entity(accountId, id))
          .toList();
      await box.deleteAll(keysToDelete);

      final nowIso = DateTime.now().toIso8601String();
      final tombstoneEntries = <String, Map>{};
      for (final id in result.needDelete) {
        tombstoneEntries[_tombstoneKey(accountId, id)] = {
          'deletedAt': nowIso,
        };
      }
      await box.putAll(tombstoneEntries);
    }

    return updatedEntities;
  }
}
