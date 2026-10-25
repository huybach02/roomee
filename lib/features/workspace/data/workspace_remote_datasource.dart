import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';

class WorkspaceRemoteDataSource extends BaseService {
  WorkspaceRemoteDataSource({super.client});

  Future<ApiResponse<List<WorkspaceModel>>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  }) {
    return getDataAll<List<WorkspaceModel>>(
      '/workspaces',
      queryParameters: queryParameters,
      fromJsonT: (json) {
        if (json is Map<String, dynamic> && json['data'] is List) {
          return (json['data'] as List)
              .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (json is List) {
          return json
              .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <WorkspaceModel>[];
      },
    );
  }

  Future<ApiResponse<WorkspaceModel>> getWorkspaceById(int id) {
    return getDataById<WorkspaceModel>(
      '/workspaces',
      id,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<WorkspaceModel>> createWorkspace(
    Map<String, dynamic> data,
  ) {
    return postData<WorkspaceModel>(
      '/workspaces',
      data: data,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<WorkspaceModel>> updateWorkspace(
    int id,
    Map<String, dynamic> data,
  ) {
    return putData<WorkspaceModel>(
      '/workspaces',
      id: id,
      data: data,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteWorkspace(int id) {
    return deleteData(
      '/workspaces',
      id: id,
    );
  }
}
