import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';

class WorkspaceRemoteDataSource extends BaseService
    implements RemoteCrudDataSource<WorkspaceModel, String> {
  WorkspaceRemoteDataSource({super.client});


  @override
  Future<ApiResponse<PaginationModel<WorkspaceModel>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) {
    return getDataAll<PaginationModel<WorkspaceModel>>(
      '/workspaces',
      queryParameters: queryParameters,
      fromJsonT: (json) {
        if (json is Map<String, dynamic>) {
          return PaginationModel.fromJson(
            json,
            (item) => WorkspaceModel.fromJson(item as Map<String, dynamic>),
          );
        }
        if (json is List) {
          final list = json
              .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return PaginationModel<WorkspaceModel>(
            data: list,
            total: list.length,
            page: 1,
            limit: list.length,
            totalPages: 1,
          );
        }
        return const PaginationModel<WorkspaceModel>(
          data: [],
          total: 0,
          page: 1,
          limit: 20,
          totalPages: 1,
        );
      },
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> getById(String id) {
    return getDataById<WorkspaceModel>(
      '/workspaces',
      id,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> create(
    Map<String, dynamic> data,
  ) {
    return postData<WorkspaceModel>(
      '/workspaces',
      data: data,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<WorkspaceModel>> update(
    String id,
    Map<String, dynamic> data,
  ) {
    return putData<WorkspaceModel>(
      '/workspaces',
      id: id,
      data: data,
      fromJsonT: (json) => WorkspaceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<void>> deleteById(String id) {
    return deleteData(
      '/workspaces',
      id: id,
    );
  }
}
