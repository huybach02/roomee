import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/core/offline/contracts/app_uuid.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/datasource/lookup_local_datasource.dart';
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
  final Duration syncTimeout;
  final ISyncMutationStore? syncMutationStore;
  final NetworkSentinel? networkSentinel;
  final ILookupLocalDataSource? lookupLocalDataSource;
  final LookupOption Function(T entity)? toLookupOption;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool?> syncSuccessNotifier = ValueNotifier<bool?>(null);
  final ValueNotifier<int> failedCountNotifier = ValueNotifier<int>(0);

  bool get isSyncing => isSyncingNotifier.value;

  bool _isReconciling = false;
  bool _hasPendingReconcile = false;
  DateTime? _lastSuccessfulSyncAt;
  Timer? _trailingCooldownTimer;
  Timer? _backoffRetryTimer;
  int _consecutiveFailures = 0;
  String? _activeAccountId;
  Completer<void>? _activeReconcileCompleter;

  OfflineCrudRepository({
    required this.remote,
    this.local,
    this.errorPolicy = const DefaultOfflineErrorPolicy(),
    this.getAccountId,
    this.syncMutationStore,
    GeneralRemoteDataSource? generalRemote,
    this.reconcileCooldown = const Duration(seconds: 15),
    this.syncTimeout = const Duration(seconds: 10),
    this.networkSentinel,
    this.lookupLocalDataSource,
    this.toLookupOption,
  }) : generalRemote = generalRemote ?? GeneralRemoteDataSource() {
    networkSentinel?.registerSyncCallback(_onNetworkRestored);
  }

  /// Kiểm tra nếu trong sổ còn phiếu tồn đọng và đang có mạng thì chủ động gọi syncNow()
  /// thay vì trông vào chuông của lính canh hay chờ người dùng mở màn hình tải dữ liệu.
  Future<void> syncIfPending() async {
    try {
      final isOnline = networkSentinel?.isOnline ?? true;
      if (!isOnline) return;
      final count = await pendingMutationCount();
      if (count > 0) {
        final accountId = await getAccountId?.call();
        if (accountId != null && accountId.isNotEmpty) {
          await syncNow().timeout(syncTimeout);
        }
      }
    } catch (_) {}
  }

  Future<void> _onNetworkRestored() async {
    final accountId = await getAccountId?.call();
    if (accountId != null && accountId.isNotEmpty) {
      // Khi mạng thực sự hồi phục, hủy backoff retry timer cũ
      _backoffRetryTimer?.cancel();
      _backoffRetryTimer = null;
      _scheduleReconcile(accountId);
    }
  }

  void dispose() {
    networkSentinel?.unregisterSyncCallback(_onNetworkRestored);
    _trailingCooldownTimer?.cancel();
    _trailingCooldownTimer = null;
    _backoffRetryTimer?.cancel();
    _backoffRetryTimer = null;
    _activeReconcileCompleter?.complete();
    _activeReconcileCompleter = null;
    isSyncingNotifier.dispose();
    syncSuccessNotifier.dispose();
    failedCountNotifier.dispose();
  }

  Future<OfflinePage<T>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    // Nếu sổ đang còn phiếu chờ đồng bộ:
    // Chờ một lượt đồng bộ hoàn tất để máy chủ cập nhật dữ liệu mới nhất trước khi tải danh sách online,
    // tránh trường hợp trang online đầu tiên che mất thay đổi vừa sửa offline.
    if (syncMutationStore != null && getAccountId != null) {
      try {
        final pendingCount = await pendingMutationCount();
        if (pendingCount > 0) {
          await syncNow().timeout(syncTimeout);
        }
      } catch (_) {
        // Nếu timeout hoặc lỗi mạng, tiếp tục luồng bên dưới để fallback về local cache
      }
    }

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
    final id = data['id']?.toString();
    final entityId = (id == null || id.isEmpty) ? AppUuid.v4() : id;
    final requestData = <String, dynamic>{...data, 'id': entityId};

    try {
      final response = await remote.create(requestData);
      final responseData = response.data;
      if (responseData == null) {
        throw ServerException(message: t('errors.invalidServerResponse'));
      }

      if (local != null && getAccountId != null) {
        try {
          final accountId = await getAccountId!();
          if (accountId != null && accountId.isNotEmpty) {
            await local!.cacheCreated(accountId: accountId, item: responseData);
            if (lookupLocalDataSource != null && toLookupOption != null) {
              await lookupLocalDataSource!.addOrUpdateOption(
                accountId: accountId,
                module: local!.entityName,
                option: toLookupOption!(responseData),
              );
            }
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

      // Xử lý tạo mới khi offline — dùng lại đúng entityId đã gửi ở nhánh online
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final offlineData = <String, dynamic>{
        ...requestData,
        if (data['userId'] == null ||
            (data['userId'] is String && (data['userId'] as String).isEmpty))
          'userId': accountId,
        'createdAt': data['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
      };

      final offlineItem = local!.itemFromJson(offlineData);
      await local!.cacheCreated(accountId: accountId, item: offlineItem);

      if (lookupLocalDataSource != null && toLookupOption != null) {
        try {
          await lookupLocalDataSource!.addOrUpdateOption(
            accountId: accountId,
            module: local!.entityName,
            option: toLookupOption!(offlineItem),
          );
        } catch (_) {}
      }

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
            if (lookupLocalDataSource != null && toLookupOption != null) {
              await lookupLocalDataSource!.addOrUpdateOption(
                accountId: accountId,
                module: local!.entityName,
                option: toLookupOption!(responseData),
              );
            }
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
        if ((currentJson['userId'] == null ||
                (currentJson['userId'] is String &&
                    (currentJson['userId'] as String).isEmpty)) &&
            (data['userId'] == null ||
                (data['userId'] is String &&
                    (data['userId'] as String).isEmpty)))
          'userId': accountId,
        'updatedAt': nowIso,
      };

      final updatedItem = local!.itemFromJson(updatedData);
      await local!.cacheUpdated(accountId: accountId, item: updatedItem);

      if (lookupLocalDataSource != null && toLookupOption != null) {
        try {
          await lookupLocalDataSource!.addOrUpdateOption(
            accountId: accountId,
            module: local!.entityName,
            option: toLookupOption!(updatedItem),
          );
        } catch (_) {}
      }

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
            if (lookupLocalDataSource != null) {
              await lookupLocalDataSource!.removeOption(
                accountId: accountId,
                module: local!.entityName,
                id: id,
              );
            }
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
      if (lookupLocalDataSource != null) {
        try {
          await lookupLocalDataSource!.removeOption(
            accountId: accountId,
            module: local!.entityName,
            id: id,
          );
        } catch (_) {}
      }

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
      _trailingCooldownTimer?.cancel();
      _trailingCooldownTimer = null;
      _backoffRetryTimer?.cancel();
      _backoffRetryTimer = null;

      if (_isReconciling) {
        _hasPendingReconcile = true;
        await (_activeReconcileCompleter?.future ?? Future.value());
        return;
      }

      await _runReconcileLoop(accountId);
    }
  }

  /// Số phiếu đồng bộ đang chờ của tài khoản hiện tại (bao gồm cả phiếu đang gửi).
  Future<int> pendingMutationCount() async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return 0;
    final all = await store.getMutations(accountId: accountId);
    return all
        .where(
          (m) =>
              m.status == SyncMutationStatus.pending ||
              m.status == SyncMutationStatus.inFlight,
        )
        .length;
  }

  /// Số phiếu bị từ chối / lỗi đồng bộ của tài khoản hiện tại.
  Future<int> failedMutationCount() async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return 0;
    return (await store.getMutations(
      accountId: accountId,
      status: SyncMutationStatus.failed,
    ))
        .length;
  }

  /// Danh sách các phiếu bị từ chối / lỗi đồng bộ của tài khoản hiện tại.
  Future<List<SyncMutation>> getFailedMutations() async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) {
      return const [];
    }
    return store.getMutations(
      accountId: accountId,
      status: SyncMutationStatus.failed,
    );
  }

  /// Xoá 1 phiếu lỗi hoặc đang chờ cụ thể.
  /// Nếu [removeLocalRecord] là true và đó là phiếu create, đồng thời xoá bản ghi trong local cache.
  Future<void> discardMutation({
    required String mutationId,
    bool removeLocalRecord = true,
  }) async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return;

    final mutations = await store.getMutations(accountId: accountId);
    final target = mutations.where((m) => m.id == mutationId).firstOrNull;

    await store.removeMutations(
      accountId: accountId,
      mutationIds: [mutationId],
    );

    if (removeLocalRecord &&
        target != null &&
        target.action == SyncMutationAction.create &&
        local != null &&
        target.module == local!.entityName &&
        target.entityId is ID) {
      await local!.remove(accountId: accountId, id: target.entityId as ID);
      if (lookupLocalDataSource != null) {
        try {
          await lookupLocalDataSource!.removeOption(
            accountId: accountId,
            module: local!.entityName,
            id: target.entityId,
          );
        } catch (_) {}
      }
    }

    final remainingFailed = await failedMutationCount();
    failedCountNotifier.value = remainingFailed;
  }

  /// Thử gửi lại một phiếu đang bị lỗi (chuyển trạng thái về pending).
  Future<void> retryFailedMutation({
    required String mutationId,
    Map<String, dynamic>? updatedData,
  }) async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return;

    await store.resetMutationToPending(
      accountId: accountId,
      mutationId: mutationId,
      updatedData: updatedData,
    );
    final remainingFailed = await failedMutationCount();
    failedCountNotifier.value = remainingFailed;
    _scheduleReconcile(accountId);
  }

  /// Đẩy các phiếu đang chờ lên server (chỉ push, không kéo/đối soát dữ liệu).
  /// Dùng trước khi đăng xuất để không mất thay đổi chưa gửi.
  Future<void> flushPendingMutations() async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return;

    final pending = await store.getMutations(
      accountId: accountId,
      status: SyncMutationStatus.pending,
    );
    if (pending.isEmpty) return;

    try {
      await store.markMutationsAsInFlight(
        accountId: accountId,
        mutationIds: pending.map((m) => m.id).toList(),
      );

      final response = await generalRemote.sync(
        mutations: pending,
        entities: const {},
      );
      final applied = response.data?.appliedMutationIds ?? const <String>[];
      if (applied.isNotEmpty) {
        await store.removeMutations(
          accountId: accountId,
          mutationIds: applied,
        );
      }
      final rejected =
          response.data?.rejectedMutations ?? const <SyncRejectedMutationDto>[];
      if (rejected.isNotEmpty) {
        await store.markMutationsAsFailed(
          accountId: accountId,
          failures: rejected,
        );
      }
      await store.resetInFlightMutations(accountId: accountId);
    } catch (e) {
      await store.resetInFlightMutations(accountId: accountId);
      debugPrint('[OfflineCrudRepository] Flush mutations error: $e');
    }
  }

  /// Xoá toàn bộ phiếu đang chờ của tài khoản hiện tại.
  Future<void> discardPendingMutations() async {
    final store = syncMutationStore;
    final accountId = await getAccountId?.call();
    if (store == null || accountId == null || accountId.isEmpty) return;
    await store.clearAccount(accountId: accountId);
  }

  void _scheduleReconcile(String accountId) {
    if (local == null) return;
    _activeAccountId = accountId;

    if (_isReconciling) {
      _hasPendingReconcile = true;
      return;
    }

    // Nếu vừa có lượt thành công và vẫn trong thời gian cooldown:
    // Đặt Trailing Timer để tự động chạy bù ngay khi hết khoảng nghỉ, không bỏ rơi request
    final now = DateTime.now();
    if (_lastSuccessfulSyncAt != null &&
        reconcileCooldown > Duration.zero &&
        now.difference(_lastSuccessfulSyncAt!) < reconcileCooldown) {
      final remaining =
          reconcileCooldown - now.difference(_lastSuccessfulSyncAt!);
      _trailingCooldownTimer ??= Timer(remaining, () {
        _trailingCooldownTimer = null;
        final target = _activeAccountId ?? accountId;
        _scheduleReconcile(target);
      });
      return;
    }

    // Đủ điều kiện chạy ngay: hủy trailing timer nếu có
    _trailingCooldownTimer?.cancel();
    _trailingCooldownTimer = null;

    unawaited(_runReconcileLoop(accountId));
  }

  Future<void> _runReconcileLoop(String initialAccountId) async {
    _isReconciling = true;
    _activeReconcileCompleter = Completer<void>();
    syncSuccessNotifier.value = null;
    isSyncingNotifier.value = true;
    try {
      do {
        _hasPendingReconcile = false;
        final targetAccountId = _activeAccountId ?? initialAccountId;
        final success = await _reconcile(targetAccountId);
        if (success) {
          _lastSuccessfulSyncAt = DateTime.now();
          _consecutiveFailures = 0;
          _backoffRetryTimer?.cancel();
          _backoffRetryTimer = null;
        } else {
          _handleReconcileFailure(targetAccountId);
        }
      } while (_hasPendingReconcile);
    } finally {
      _isReconciling = false;
      _hasPendingReconcile = false;
      isSyncingNotifier.value = false;
      _activeReconcileCompleter?.complete();
      _activeReconcileCompleter = null;
    }
  }

  void _handleReconcileFailure(String accountId) {
    _consecutiveFailures++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s, tối đa 60s
    final delaySeconds = math.min(
      2 * math.pow(2, _consecutiveFailures - 1).toInt(),
      60,
    );
    _backoffRetryTimer?.cancel();
    _backoffRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _backoffRetryTimer = null;
      final target = _activeAccountId ?? accountId;
      _scheduleReconcile(target);
    });
  }

  Future<bool> _reconcile(String accountId) async {
    if (local == null) return true;
    try {
      final pendingMutations = await syncMutationStore?.getMutations(
            accountId: accountId,
            status: SyncMutationStatus.pending,
          ) ??
          const [];

      final mainItems = await local!.getSyncItems(accountId: accountId);
      final relationItems =
          await local!.getRelationSyncItems(accountId: accountId);

      if (pendingMutations.isEmpty &&
          mainItems.isEmpty &&
          relationItems.isEmpty) {
        return true;
      }

      if (pendingMutations.isNotEmpty && syncMutationStore != null) {
        await syncMutationStore!.markMutationsAsInFlight(
          accountId: accountId,
          mutationIds: pendingMutations.map((m) => m.id).toList(),
        );
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
        final syncData = response.data!;

        // 1. Dọn dẹp mutations đã áp dụng thành công
        if (syncData.appliedMutationIds.isNotEmpty &&
            syncMutationStore != null) {
          await syncMutationStore!.removeMutations(
            accountId: accountId,
            mutationIds: syncData.appliedMutationIds,
          );
        }

        // 2. Chuyển các phiếu bị từ chối sang trạng thái failed để không gửi lại
        if (syncData.rejectedMutations.isNotEmpty &&
            syncMutationStore != null) {
          await syncMutationStore!.markMutationsAsFailed(
            accountId: accountId,
            failures: syncData.rejectedMutations,
          );
        }

        // 3. Khôi phục các phiếu inFlight còn sót lại (nếu có) về pending
        if (syncMutationStore != null) {
          await syncMutationStore!.resetInFlightMutations(
            accountId: accountId,
          );
        }

        // 4. Chỉ báo thành công: chỉ true khi không có mutation nào bị từ chối
        syncSuccessNotifier.value = syncData.rejectedMutations.isEmpty;

        // 5. Lấy danh sách entityId đang có phiếu create (cả pending lẫn failed)
        // để bảo vệ không bị xóa nhầm khỏi local cache qua needDelete
        final protectedCreateIds = await syncMutationStore
                ?.getProtectedCreateEntityIds(accountId: accountId) ??
            const <String>{};

        // Lấy danh sách entityId đang có phiếu pending (ví dụ vừa sửa trong lúc sync đang chạy)
        // để bảo vệ thay đổi cục bộ mới hơn không bị bản ghi cũ hơn từ server đè lên
        final remainingPending = await syncMutationStore?.getMutations(
              accountId: accountId,
              status: SyncMutationStatus.pending,
            ) ??
            const [];
        final pendingEntityIds =
            remainingPending.map((m) => m.entityId).toSet();

        // 6. Áp dụng kết quả đối soát vào local store (có bảo vệ needDelete Guard và needUpdate Guard)
        final results = syncData.entities;
        final mainResult = results[local!.entityName];
        if (mainResult != null) {
          final safeNeedDelete = protectedCreateIds.isEmpty
              ? mainResult.needDelete
              : mainResult.needDelete
                  .where((id) => !protectedCreateIds.contains(id))
                  .toList();

          final safeNeedUpdate = pendingEntityIds.isEmpty
              ? mainResult.needUpdate
              : mainResult.needUpdate
                  .where((item) =>
                      !pendingEntityIds.contains(item['id']?.toString()))
                  .toList();

          final safeMainResult = SyncResultDto(
            needUpdate: safeNeedUpdate,
            needDelete: safeNeedDelete,
          );

          await local!.applySyncResult(
            accountId: accountId,
            result: safeMainResult,
          );

          if (lookupLocalDataSource != null) {
            for (final id in safeNeedDelete) {
              try {
                await lookupLocalDataSource!.removeOption(
                  accountId: accountId,
                  module: local!.entityName,
                  id: id,
                );
              } catch (_) {}
            }
            if (toLookupOption != null) {
              for (final raw in safeNeedUpdate) {
                try {
                  final item = local!.itemFromJson(raw);
                  await lookupLocalDataSource!.addOrUpdateOption(
                    accountId: accountId,
                    module: local!.entityName,
                    option: toLookupOption!(item),
                  );
                } catch (_) {}
              }
            }
          }
        }

        final safeResults = <String, SyncResultDto>{};
        results.forEach((key, resultDto) {
          if (key == local!.entityName) return;
          final safeDelete = protectedCreateIds.isNotEmpty &&
                  resultDto.needDelete.isNotEmpty
              ? resultDto.needDelete
                  .where((id) => !protectedCreateIds.contains(id))
                  .toList()
              : resultDto.needDelete;

          final safeUpdate = pendingEntityIds.isNotEmpty &&
                  resultDto.needUpdate.isNotEmpty
              ? resultDto.needUpdate
                  .where((item) =>
                      !pendingEntityIds.contains(item['id']?.toString()))
                  .toList()
              : resultDto.needUpdate;

          safeResults[key] = SyncResultDto(
            needUpdate: safeUpdate,
            needDelete: safeDelete,
          );
        });

        await local!.applyRelationSync(
          accountId: accountId,
          relationResults: safeResults,
        );
        return true;
      } else {
        if (syncMutationStore != null) {
          await syncMutationStore!.resetInFlightMutations(
            accountId: accountId,
          );
        }
        syncSuccessNotifier.value = false;
        return false;
      }
    } catch (e, s) {
      if (syncMutationStore != null) {
        await syncMutationStore!.resetInFlightMutations(
          accountId: accountId,
        );
      }
      syncSuccessNotifier.value = false;
      debugPrint('[OfflineCrudRepository] Reconciliation error: $e\n$s');
      return false;
    } finally {
      final remainingFailed = await failedMutationCount();
      failedCountNotifier.value = remainingFailed;
    }
  }
}
