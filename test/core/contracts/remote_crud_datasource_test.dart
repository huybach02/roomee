import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';

class _FakeRemoteCrudDataSource
    implements RemoteCrudDataSource<String, String> {
  @override
  Future<ApiResponse<PaginationModel<String>>> getAll({
    Map<String, dynamic>? queryParameters,
  }) async {
    return const ApiResponse(
      data: PaginationModel(
        data: ['item-1'],
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
      ),
      success: true,
      message: 'Success',
    );
  }

  @override
  Future<ApiResponse<String>> getById(String id) async {
    return ApiResponse(
      data: 'item-$id',
      success: true,
      message: 'Success',
    );
  }

  @override
  Future<ApiResponse<String>> create(Map<String, dynamic> data) async {
    return ApiResponse(
      data: data['name'] as String? ?? '',
      success: true,
      message: 'Created',
    );
  }

  @override
  Future<ApiResponse<String>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    return ApiResponse(
      data: 'updated-$id',
      success: true,
      message: 'Updated',
    );
  }

  @override
  Future<ApiResponse<void>> deleteById(String id) async {
    return const ApiResponse(
      data: null,
      success: true,
      message: 'Deleted',
    );
  }
}

void main() {
  test('RemoteCrudDataSource defines CRUD contract returning ApiResponse', () async {
    final RemoteCrudDataSource<String, String> ds = _FakeRemoteCrudDataSource();

    final pageRes = await ds.getAll(queryParameters: {'page': 1});
    expect(pageRes.success, isTrue);
    expect(pageRes.data?.data, ['item-1']);

    final singleRes = await ds.getById('123');
    expect(singleRes.data, 'item-123');

    final createRes = await ds.create({'name': 'New Item'});
    expect(createRes.data, 'New Item');

    final updateRes = await ds.update('123', {'name': 'Updated'});
    expect(updateRes.data, 'updated-123');

    final deleteRes = await ds.deleteById('123');
    expect(deleteRes.success, isTrue);
  });
}
