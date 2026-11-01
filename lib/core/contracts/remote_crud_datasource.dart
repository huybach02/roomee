import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';

abstract interface class RemoteCrudDataSource<T, ID> {
  Future<ApiResponse<PaginationModel<T>>> getAll({
    Map<String, dynamic>? queryParameters,
  });

  Future<ApiResponse<T>> getById(ID id);

  Future<ApiResponse<T>> create(Map<String, dynamic> data);

  Future<ApiResponse<T>> update(ID id, Map<String, dynamic> data);

  Future<ApiResponse<void>> deleteById(ID id);
}
