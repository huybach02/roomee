import 'dart:async';

import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/policy/offline_error_policy.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

class OfflineCrudRepository<T, ID> {
  final RemoteCrudDataSource<T, ID> remote;
  final LocalCrudDataSource<T, ID>? local;
  final OfflineErrorPolicy errorPolicy;
  final FutureOr<String?> Function()? getAccountId;
  final GeneralRemoteDataSource generalRemote;

  OfflineCrudRepository({
    required this.remote,
    this.local,
    this.errorPolicy = const DefaultOfflineErrorPolicy(),
    this.getAccountId,
    GeneralRemoteDataSource? generalRemote,
  }) : generalRemote = generalRemote ?? GeneralRemoteDataSource();

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

            // Tự động đối soát ngầm (Reconcile / Sync) không block UI
            unawaited(_reconcile(accountId));
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
  }

  Future<T> update(ID id, Map<String, dynamic> data) async {
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
  }

  Future<void> deleteById(ID id) async {
    await remote.deleteById(id);

    if (local != null && getAccountId != null) {
      try {
        final accountId = await getAccountId!();
        if (accountId != null && accountId.isNotEmpty) {
          await local!.remove(accountId: accountId, id: id);
        }
      } catch (_) {}
    }
  }

  Future<void> _reconcile(String accountId) async {
    if (local == null) return;
    try {
      final mainItems = await local!.getSyncItems(accountId: accountId);
      final relationItems =
          await local!.getRelationSyncItems(accountId: accountId);

      if (mainItems.isEmpty && relationItems.isEmpty) return;

      final payload = <String, List<SyncItemDto>>{
        if (mainItems.isNotEmpty) local!.entityName: mainItems,
        ...relationItems,
      };

      final response = await generalRemote.sync(payload);
      if (response.success && response.data != null) {
        final results = response.data!;

        final mainResult =
            results[local!.entityName] ?? results['${local!.entityName}s'];
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
      }
    } catch (_) {
      // Reconciliation chạy nền, không gây ảnh hưởng đến luồng chính
    }
  }
}

