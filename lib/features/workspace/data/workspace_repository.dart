import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/features/auth/data/auth_local_datasource.dart';
import 'package:roomee/features/workspace/data/workspace_local_datasource.dart';
import 'package:roomee/features/workspace/data/workspace_remote_datasource.dart';

abstract class IWorkspaceRepository {
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  });
  Future<WorkspaceModel> getWorkspaceById(String id);
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data);
  Future<WorkspaceModel> updateWorkspace(String id, Map<String, dynamic> data);
  Future<void> deleteWorkspace(String id);
}

class WorkspaceRepository implements IWorkspaceRepository {
  final OfflineCrudRepository<WorkspaceModel, String> _crudRepository;

  WorkspaceRepository({
    WorkspaceRemoteDataSource? remoteDataSource,
    WorkspaceLocalDataSource? localDataSource,
    AuthLocalDataSource? authLocalDataSource,
    OfflineCrudRepository<WorkspaceModel, String>? crudRepository,
  }) : _crudRepository = crudRepository ??
            OfflineCrudRepository<WorkspaceModel, String>(
              remote: remoteDataSource ?? WorkspaceRemoteDataSource(),
              local: localDataSource,
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
  }) {
    return WorkspaceRepository(
      remoteDataSource: remoteDataSource,
      localDataSource: WorkspaceLocalDataSource.fromBoxes(boxes),
      authLocalDataSource: authLocalDataSource,
    );
  }

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
}
