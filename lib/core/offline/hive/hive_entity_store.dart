import 'package:hive_ce_flutter/hive_flutter.dart';

import '../contracts/entity_codec.dart';
import '../contracts/entity_store.dart';
import 'cache_key_builder.dart';

class HiveEntityStore<T, ID> implements EntityStore<T, ID> {
  final Box<Map> box;
  final EntityCodec<T, ID> codec;

  HiveEntityStore({required this.box, required this.codec});

  String _key(String accountId, ID id) {
    return CacheKeyBuilder.entity(accountId, id.toString());
  }

  @override
  Future<void> put({required String accountId, required T entity}) async {
    await box.put(_key(accountId, codec.getId(entity)), codec.toJson(entity));
  }

  @override
  Future<void> putMany({
    required String accountId,
    required List<T> entities,
  }) async {
    final entries = <String, Map>{};

    for (final entity in entities) {
      entries[_key(accountId, codec.getId(entity))] = codec.toJson(entity);
    }

    await box.putAll(entries);
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
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    final prefix = 'account:$accountId:';
    final keys = box.keys
        .where((key) => key is String && key.startsWith(prefix))
        .toList();

    await box.deleteAll(keys);
  }
}
