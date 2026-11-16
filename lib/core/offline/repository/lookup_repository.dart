import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/datasource/lookup_local_datasource.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

abstract class ILookupRepository {
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
    bool forceRefresh = false,
  });

  Future<void> refreshAll({
    required String accountId,
    List<String>? modules,
  });

  Future<void> addOption({
    required String accountId,
    required String module,
    required LookupOption option,
  });

  Future<void> updateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  });

  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  });
}

class LookupRepository implements ILookupRepository {
  final ILookupLocalDataSource local;
  final GeneralRemoteDataSource _remote;
  final NetworkSentinel? networkSentinel;

  LookupRepository({
    required this.local,
    GeneralRemoteDataSource? remote,
    this.networkSentinel,
  }) : _remote = remote ?? GeneralRemoteDataSource();

  factory LookupRepository.fromBoxes(
    CacheBoxes boxes, {
    GeneralRemoteDataSource? remote,
    NetworkSentinel? networkSentinel,
  }) {
    return LookupRepository(
      local: LookupLocalDataSource.fromBoxes(boxes),
      remote: remote,
      networkSentinel: networkSentinel ?? NetworkSentinel.instance,
    );
  }

  bool get _isOnline => networkSentinel?.isOnline ?? true;

  @override
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
    bool forceRefresh = false,
  }) async {
    final cached = await local.getOptions(
      accountId: accountId,
      module: module,
      parentId: parentId,
    );

    // Stale-While-Revalidate: Nếu đã có cache và không yêu cầu ép làm mới:
    // Trả về ngay lập tức để UI mượt mà, đồng thời kích hoạt làm tươi ngầm nếu đang có mạng.
    if (cached.isNotEmpty && !forceRefresh) {
      if (_isOnline) {
        unawaited(_refreshModule(accountId, module));
      }
      return cached;
    }

    // Nếu cache rỗng hoặc yêu cầu forceRefresh:
    if (_isOnline) {
      try {
        await _refreshModule(accountId, module);
        return await local.getOptions(
          accountId: accountId,
          module: module,
          parentId: parentId,
        );
      } catch (e) {
        debugPrint('[LookupRepository] Refresh error: $e');
      }
    }

    return cached;
  }

  Future<void> _refreshModule(String accountId, String module) async {
    try {
      final response = await _remote.getLookups(modules: [module]);
      final data = response.data;
      if (data != null && data.containsKey(module)) {
        await local.saveOptions(
          accountId: accountId,
          module: module,
          options: data[module] ?? const [],
        );
      }
    } catch (e) {
      debugPrint('[LookupRepository] Refresh error: $e');
    }
  }

  @override
  Future<void> refreshAll({
    required String accountId,
    List<String>? modules,
  }) async {
    if (!_isOnline) return;

    try {
      final response = await _remote.getLookups(modules: modules);
      final data = response.data;
      if (data != null) {
        for (final entry in data.entries) {
          await local.saveOptions(
            accountId: accountId,
            module: entry.key,
            options: entry.value,
          );
        }
      }
    } catch (e) {
      debugPrint('[LookupRepository] refreshAll error: $e');
    }
  }

  @override
  Future<void> addOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {
    await local.addOrUpdateOption(
      accountId: accountId,
      module: module,
      option: option,
    );
  }

  @override
  Future<void> updateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {
    await local.addOrUpdateOption(
      accountId: accountId,
      module: module,
      option: option,
    );
  }

  @override
  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  }) async {
    await local.removeOption(
      accountId: accountId,
      module: module,
      id: id,
    );
  }
}
