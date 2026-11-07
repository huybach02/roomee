import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/core/offline/contracts/app_uuid.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/sync_mutation_store.dart';
import 'package:roomee/core/offline/policy/offline_error_policy.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

class OfflineCrudRepository<T, ID> {
  final RemoteCrudDataSource<T, ID> remote;
  final LocalCrudDataSource<T, ID>? local;
  final OfflineErrorPolicy errorPolicy;
  final FutureOr<String?> Function()? getAccountId;
  final GeneralRemoteDataSource generalRemote;
  final Duration reconcileCooldown;
  final ISyncMutationStore? syncMutationStore;
  final NetworkSentinel? networkSentinel;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool?> syncSuccessNotifier = ValueNotifier<bool?>(null);

  bool get isSyncing => isSyncingNotifier.value;

  bool _isReconciling = false;
  bool _hasPendingReconcile = false;
  DateTime? _lastReconciledAt;
  String? _activeAccountId;

  OfflineCrudRepository({
    required this.remote,
    this.local,
    this.errorPolicy = const DefaultOfflineErrorPolicy(),
    this.getAccountId,
    this.syncMutationStore,
    GeneralRemoteDataSource? generalRemote,
    this.reconcileCooldown = const Duration(seconds: 15),
    this.networkSentinel,
  }) : generalRemote = generalRemote ?? GeneralRemoteDataSource() {
    networkSentinel?.registerSyncCallback(_onNetworkRestored);
  }

  Future<void> _onNetworkRestored() async {
    final accountId = await getAccountId?.call();
    if (accountId != null && accountId.isNotEmpty) {
      _scheduleReconcile(accountId);
    }
  }

  void dispose() {
    networkSentinel?.unregisterSyncCallback(_onNetworkRestored);
    isSyncingNotifier.dispose();
    syncSuccessNotifier.dispose();
  }

  Future<OfflinePage<T>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await remote.getAll(queryParameters: queryParameters);
      final data = response.data;
      if (data == null) {
        throw ServerException(message: t('errors.invalidServerResponse'));
      }

      final page = OfflinePage.fromPaginationModel(data);

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.cacheRemotePage(
              accountId: accountId,
              items: data.data,
              isComplete: false,
            );

            // Tự động đối soát ngầm (Reconcile / 2-Way Sync) có coalescing + cooldown
            _scheduleReconcile(accountId);
          }
        } catch (_) {
          // Fault-tolerant caching: log and do not fail online API request
        }
      }

      return page;
    } catch (error) {
      if (!errorPolicy.shouldFallback(error) ||
          local == null ||
          getAccountId == null) {
        rethrow;
      }

      final accountId = await getAccountId!();
      if (accountId == null || accountId.isEmpty) {
        rethrow;
      }

      final localResult = await local!.queryPage(
        accountId: accountId,
        queryParameters: queryParameters ?? const {},
      );

      if (localResult.total == 0) {
        final hasAny = await local!.queryPage(
          accountId: accountId,
          queryParameters: const {'limit': 1},
        );
        if (hasAny.total == 0) {
          rethrow;
        }
      }

      return localResult;
    }
  }

  Future<T> getById(ID id) async {
    try {
      final response = await remote.getById(id);
      final data = response.data;
      if (data == null) {
        throw ServerException(message: t('errors.invalidServerResponse'));
      }

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.cacheUpdated(accountId: accountId, item: data);
          }
        } catch (_) {}
      }

      return data;
    } catch (error) {
      if (!errorPolicy.shouldFallback(error) ||
          local == null ||
          getAccountId == null) {
        rethrow;
      }

      final accountId = await getAccountId!();
      if (accountId == null || accountId.isEmpty) {
        rethrow;
      }

      final localItem = await local!.getById(accountId: accountId, id: id);
      if (localItem != null) {
        return localItem;
      }

      rethrow;
    }
  }

  Future<T> create(Map<String, dynamic> data) async {
    try {
      final response = await remote.create(data);
      final responseData = response.data;
      if (responseData == null) {
        throw ServerException(message: t('errors.invalidServerResponse'));
      }

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.cacheCreated(accountId: accountId, item: responseData);
          }
        } catch (_) {}
      }

      return responseData;
    } catch (error) {
      if (!errorPolicy.shouldFallback(error) ||
          local == null ||
          getAccountId == null) {
        rethrow;
      }

      final accountId = await getAccountId!();
      if (accountId == null || accountId.isEmpty) {
        rethrow;
      }

      // Xử lý tạo mới khi offline
      final entityId = data['id']?.toString() ?? AppUuid.v4();
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final offlineData = <String, dynamic>{
        ...data,
        'id': entityId,
        'createdAt': data['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
      };

      final offlineItem = local!.itemFromJson(offlineData);
      await local!.cacheCreated(accountId: accountId, item: offlineItem);

      if (syncMutationStore != null) {
        await syncMutationStore!.addMutation(
          accountId: accountId,
          mutation: SyncMutation(
            id: AppUuid.v4(),
            module: local!.entityName,
            action: SyncMutationAction.create,
            entityId: entityId,
            data: offlineData,
          ),
        );
      }

      return offlineItem;
    }
  }

  Future<T> update(ID id, Map<String, dynamic> data) async {
    try {
      final response = await remote.update(id, data);
      final responseData = response.data;
      if (responseData == null) {
        throw ServerException(message: t('errors.invalidServerResponse'));
      }

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.cacheUpdated(accountId: accountId, item: responseData);
          }
        } catch (_) {}
      }

      return responseData;
    } catch (error) {
      if (!errorPolicy.shouldFallback(error) ||
          local == null ||
          getAccountId == null) {
        rethrow;
      }

      final accountId = await getAccountId!();
      if (accountId == null || accountId.isEmpty) {
        rethrow;
      }

      // Xử lý cập nhật khi offline
      final currentItem = await local!.getById(accountId: accountId, id: id);
      if (currentItem == null) {
        rethrow;
      }

      final currentJson = local!.itemToJson(currentItem);
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updatedData = <String, dynamic>{
        ...currentJson,
        ...data,
        'id': id.toString(),
        'updatedAt': nowIso,
      };

      final updatedItem = local!.itemFromJson(updatedData);
      await local!.cacheUpdated(accountId: accountId, item: updatedItem);

      if (syncMutationStore != null) {
        await syncMutationStore!.addMutation(
          accountId: accountId,
          mutation: SyncMutation(
            id: AppUuid.v4(),
            module: local!.entityName,
            action: SyncMutationAction.update,
            entityId: id.toString(),
            data: data,
          ),
        );
      }

      return updatedItem;
    }
  }

  Future<void> deleteById(ID id) async {
    try {
      await remote.deleteById(id);

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.remove(accountId: accountId, id: id);
          }
        } catch (_) {}
      }
    } catch (error) {
      if (!errorPolicy.shouldFallback(error) ||
          local == null ||
          getAccountId == null) {
        rethrow;
      }

      final accountId = await getAccountId!();
      if (accountId == null || accountId.isEmpty) {
        rethrow;
      }

      // Xử lý xóa khi offline
      await local!.remove(accountId: accountId, id: id);

      if (syncMutationStore != null) {
        await syncMutationStore!.addMutation(
          accountId: accountId,
          mutation: SyncMutation(
            id: AppUuid.v4(),
            module: local!.entityName,
            action: SyncMutationAction.delete,
            entityId: id.toString(),
          ),
        );
      }
    }
  }

  Future<void> syncNow() async {
    final accountId = await getAccountId?.call();
    if (accountId != null && accountId.isNotEmpty) {
      await _runReconcileLoop(accountId);
    }
  }

  void _scheduleReconcile(String accountId) {
    if (local == null) return;
    _activeAccountId = accountId;

    if (_isReconciling) {
      _hasPendingReconcile = true;
      return;
    }

    final now = DateTime.now();
    if (_lastReconciledAt != null &&
        now.difference(_lastReconciledAt!) < reconcileCooldown) {
      return;
    }

    unawaited(_runReconcileLoop(accountId));
  }

  Future<void> _runReconcileLoop(String initialAccountId) async {
    _isReconciling = true;
    isSyncingNotifier.value = true;
    try {
      do {
        _hasPendingReconcile = false;
        final targetAccountId = _activeAccountId ?? initialAccountId;
        await _reconcile(targetAccountId);
        _lastReconciledAt = DateTime.now();
      } while (_hasPendingReconcile);
    } finally {
      _isReconciling = false;
      _hasPendingReconcile = false;
      isSyncingNotifier.value = false;
    }
  }

  Future<void> _reconcile(String accountId) async {
    if (local == null) return;
    try {
      final pendingMutations =
          await syncMutationStore?.getMutations(accountId: accountId) ??
              const [];

      final mainItems = await local!.getSyncItems(accountId: accountId);
      final relationItems =
          await local!.getRelationSyncItems(accountId: accountId);

      if (pendingMutations.isEmpty &&
          mainItems.isEmpty &&
          relationItems.isEmpty) {
        return;
      }

      final payload = <String, List<SyncItemDto>>{
        if (mainItems.isNotEmpty) local!.entityName: mainItems,
        ...relationItems,
      };

      final response = await generalRemote.sync(
        mutations: pendingMutations,
        entities: payload,
      );

      if (response.success && response.data != null) {
        syncSuccessNotifier.value = true;
        final syncData = response.data!;

        // 1. Dọn dẹp mutations đã áp dụng thành công
        if (syncData.appliedMutationIds.isNotEmpty &&
            syncMutationStore != null) {
          await syncMutationStore!.removeMutations(
            accountId: accountId,
            mutationIds: syncData.appliedMutationIds,
          );
        }

        // 2. Áp dụng kết quả đối soát vào local store
        final results = syncData.entities;
        final mainResult = results[local!.entityName];
        if (mainResult != null) {
          await local!.applySyncResult(
            accountId: accountId,
            result: mainResult,
          );
        }

        await local!.applyRelationSync(
          accountId: accountId,
          relationResults: results,
        );
      } else {
        syncSuccessNotifier.value = false;
      }
    } catch (e, s) {
      syncSuccessNotifier.value = false;
      debugPrint('[OfflineCrudRepository] Reconciliation error: $e\n$s');
    }
  }
}
