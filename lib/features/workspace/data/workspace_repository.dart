import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/workspace/data/workspace_remote_datasource.dart';

abstract class IWorkspaceRepository {
  Future<PaginationModel<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  });
  Future<WorkspaceModel> getWorkspaceById(int id);
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data);
  Future<WorkspaceModel> updateWorkspace(int id, Map<String, dynamic> data);
  Future<void> deleteWorkspace(int id);
}

class WorkspaceRepository implements IWorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;

  WorkspaceRepository({WorkspaceRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? WorkspaceRemoteDataSource();

  @override
  Future<PaginationModel<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _remoteDataSource.getWorkspaces(
      queryParameters: queryParameters,
    );
    final data = response.data;
    if (data == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }
    return data;
  }

  @override
  Future<WorkspaceModel> getWorkspaceById(int id) async {
    final response = await _remoteDataSource.getWorkspaceById(id);
    final data = response.data;
    if (data == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }
    return data;
  }

  @override
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data) async {
    final response = await _remoteDataSource.createWorkspace(data);
    final responseData = response.data;
    if (responseData == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }
    return responseData;
  }

  @override
  Future<WorkspaceModel> updateWorkspace(int id, Map<String, dynamic> data) async {
    final response = await _remoteDataSource.updateWorkspace(id, data);
    final responseData = response.data;
    if (responseData == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }
    return responseData;
  }

  @override
  Future<void> deleteWorkspace(int id) async {
    await _remoteDataSource.deleteWorkspace(id);
  }
}
