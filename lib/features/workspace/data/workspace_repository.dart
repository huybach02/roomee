import 'package:flutter/foundation.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/datasource/lookup_local_datasource.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/sync_mutation_store.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/auth/data/auth_local_datasource.dart';
import 'package:roomee/features/workspace/data/workspace_local_datasource.dart';
import 'package:roomee/features/workspace/data/workspace_remote_datasource.dart';

abstract class IWorkspaceRepository {
  ValueListenable<bool>? get isSyncingNotifier => null;
  ValueListenable<bool?>? get syncSuccessNotifier => null;

  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  });
  Future<WorkspaceModel> getWorkspaceById(String id);
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data);
  Future<WorkspaceModel> updateWorkspace(String id, Map<String, dynamic> data);
  Future<void> deleteWorkspace(String id);

  Future<int> pendingMutationCount() async => 0;

  Future<void> flushPendingMutations() async {}

  Future<void> syncIfPending() async {}
}

class WorkspaceRepository implements IWorkspaceRepository {
  final OfflineCrudRepository<WorkspaceModel, String> _crudRepository;

  WorkspaceRepository({
    WorkspaceRemoteDataSource? remoteDataSource,
    WorkspaceLocalDataSource? localDataSource,
    AuthLocalDataSource? authLocalDataSource,
    ISyncMutationStore? syncMutationStore,
    NetworkSentinel? networkSentinel,
    ILookupLocalDataSource? lookupLocalDataSource,
    OfflineCrudRepository<WorkspaceModel, String>? crudRepository,
  }) : _crudRepository =
           crudRepository ??
           OfflineCrudRepository<WorkspaceModel, String>(
             remote: remoteDataSource ?? WorkspaceRemoteDataSource(),
             local: localDataSource,
             syncMutationStore: syncMutationStore,
             networkSentinel: networkSentinel,
             lookupLocalDataSource: lookupLocalDataSource,
             toLookupOption: (ws) => LookupOption(id: ws.id, label: ws.name),
             getAccountId: () async {
               final auth = authLocalDataSource ?? AuthLocalDataSource();
               final user = await auth.getUser();
               return user?.id;
             },
           );

  factory WorkspaceRepository.fromBoxes(
    CacheBoxes boxes, {
    WorkspaceRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? authLocalDataSource,
    NetworkSentinel? networkSentinel,
  }) {
    return WorkspaceRepository(
      remoteDataSource: remoteDataSource,
      localDataSource: WorkspaceLocalDataSource.fromBoxes(boxes),
      authLocalDataSource: authLocalDataSource,
      syncMutationStore: HiveSyncMutationStore(
        box: boxes[HiveBoxNames.syncMutations],
      ),
      networkSentinel: networkSentinel ?? NetworkSentinel.instance,
      lookupLocalDataSource: LookupLocalDataSource.fromBoxes(boxes),
    );
  }

  @override
  ValueListenable<bool> get isSyncingNotifier =>
      _crudRepository.isSyncingNotifier;

  @override
  ValueListenable<bool?> get syncSuccessNotifier =>
      _crudRepository.syncSuccessNotifier;

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  }) {
    return _crudRepository.getAll(queryParameters: queryParameters);
  }

  @override
  Future<WorkspaceModel> getWorkspaceById(String id) {
    return _crudRepository.getById(id);
  }

  @override
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data) {
    return _crudRepository.create(data);
  }

  @override
  Future<WorkspaceModel> updateWorkspace(String id, Map<String, dynamic> data) {
    return _crudRepository.update(id, data);
  }

  @override
  Future<void> deleteWorkspace(String id) {
    return _crudRepository.deleteById(id);
  }

  @override
  Future<int> pendingMutationCount() => _crudRepository.pendingMutationCount();

  @override
  Future<void> flushPendingMutations() =>
      _crudRepository.flushPendingMutations();

  @override
  Future<void> syncIfPending() => _crudRepository.syncIfPending();
}
