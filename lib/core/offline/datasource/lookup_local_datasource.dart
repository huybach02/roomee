import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';

abstract class ILookupLocalDataSource {
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
  });

  Future<void> saveOptions({
    required String accountId,
    required String module,
    required List<LookupOption> options,
  });

  Future<void> addOrUpdateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  });

  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  });

  Future<void> clearAccount({required String accountId});
}

class LookupLocalDataSource implements ILookupLocalDataSource {
  final Box<Map> box;

  LookupLocalDataSource({required this.box});

  factory LookupLocalDataSource.fromBoxes(CacheBoxes boxes) {
    return LookupLocalDataSource(box: boxes[HiveBoxNames.lookups]);
  }

  String _buildKey(String accountId, String module) {
    return 'account:$accountId:lookups:$module';
  }

  @override
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
  }) async {
    final key = _buildKey(accountId, module);
    final rawMap = box.get(key);
    if (rawMap == null) return const [];

    final rawList = rawMap['options'];
    if (rawList is! List) return const [];

    final options = rawList
        .whereType<Map>()
        .map((m) => LookupOption.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    if (parentId != null) {
      final pStr = parentId.toString();
      return options.where((o) => o.parentId?.toString() == pStr).toList();
    }

    return options;
  }

  @override
  Future<void> saveOptions({
    required String accountId,
    required String module,
    required List<LookupOption> options,
  }) async {
    final key = _buildKey(accountId, module);
    await box.put(key, {
      'options': options.map((o) => o.toJson()).toList(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> addOrUpdateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {
    final current = await getOptions(accountId: accountId, module: module);
    final idStr = option.id.toString();

    final updated = current.where((o) => o.id.toString() != idStr).toList();
    updated.add(option);
    updated.sort((a, b) => a.label.compareTo(b.label));

    await saveOptions(
      accountId: accountId,
      module: module,
      options: updated,
    );
  }

  @override
  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  }) async {
    final current = await getOptions(accountId: accountId, module: module);
    final idStr = id.toString();

    final updated = current.where((o) => o.id.toString() != idStr).toList();

    await saveOptions(
      accountId: accountId,
      module: module,
      options: updated,
    );
  }

  @override
  Future<void> clearAccount({required String accountId}) async {
    final prefix = 'account:$accountId:';
    final keysToDelete = box.keys
        .where((k) => k is String && k.startsWith(prefix))
        .toList();

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }
}
