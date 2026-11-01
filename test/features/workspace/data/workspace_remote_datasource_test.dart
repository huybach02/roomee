import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/remote_crud_datasource.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/features/workspace/data/workspace_remote_datasource.dart';

void main() {
  test('WorkspaceRemoteDataSource implements RemoteCrudDataSource<WorkspaceModel, String>', () {
    final ds = WorkspaceRemoteDataSource();

    expect(ds, isA<RemoteCrudDataSource<WorkspaceModel, String>>());
  });
}
