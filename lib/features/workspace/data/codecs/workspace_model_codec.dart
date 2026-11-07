import 'package:roomee/core/models/workspace_model.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';

class WorkspaceModelCodec extends EntityCodec<WorkspaceModel, String> {
  const WorkspaceModelCodec();

  @override
  String getId(WorkspaceModel entity) => entity.id;

  @override
  Map<String, dynamic> toJson(WorkspaceModel entity) {
    final map = entity.toJson();
    map.remove('province');
    map.remove('ward');
    map.remove('user');
    return map;
  }

  @override
  WorkspaceModel fromJson(Map<String, dynamic> json) =>
      WorkspaceModel.fromJson(json);

  @override
  DateTime? getUpdatedAt(WorkspaceModel entity) => entity.updatedAt;
}
