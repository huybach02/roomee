import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/user_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/datasource/base_local_datasource.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/features/workspace/data/codecs/workspace_model_codec.dart';
import 'package:roomee/features/workspace/data/workspace_query_schema.dart';
import 'package:roomee/features/workspace/data/workspace_relation_adapter.dart';

class WorkspaceLocalDataSource
    extends BaseLocalDataSource<WorkspaceModel, String> {
  WorkspaceLocalDataSource({
    required super.entityStore,
    required super.metadataBox,
    super.relationAdapter,
  }) : super(
         entityName: 'workspaces',
         queryEngine: const LocalQueryEngine<WorkspaceModel>(),
         querySchema: workspaceQuerySchema,
       );

  factory WorkspaceLocalDataSource.fromBoxes(CacheBoxes boxes) {
    return WorkspaceLocalDataSource(
      entityStore: HiveEntityStore<WorkspaceModel, String>(
        box: boxes[HiveBoxNames.workspaces],
        codec: const WorkspaceModelCodec(),
      ),
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: WorkspaceRelationAdapter(
        provinceStore: HiveEntityStore<ProvinceModel, int>(
          box: boxes[HiveBoxNames.provinces],
          codec: const ProvinceModelCodec(),
        ),
        wardStore: HiveEntityStore<WardModel, int>(
          box: boxes[HiveBoxNames.wards],
          codec: const WardModelCodec(),
        ),
        userStore: HiveEntityStore<UserModel, String>(
          box: boxes[HiveBoxNames.users],
          codec: const UserModelCodec(),
        ),
      ),
    );
  }
}
