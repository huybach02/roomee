import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/user_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/datasource/base_local_datasource.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/workspace/data/codecs/workspace_model_codec.dart';
import 'package:roomee/features/workspace/data/workspace_query_schema.dart';
import 'package:roomee/features/workspace/data/workspace_relation_adapter.dart';

abstract interface class IWorkspaceLocalDataSource {
  Future<void> cacheRemotePage({
    required String accountId,
    required List<WorkspaceModel> items,
    bool isComplete = false,
  });

  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  });

  Future<WorkspaceModel?> getWorkspaceById({
    required String accountId,
    required String id,
  });

  Future<void> cacheCreatedWorkspace({
    required String accountId,
    required WorkspaceModel workspace,
  });

  Future<void> cacheUpdatedWorkspace({
    required String accountId,
    required WorkspaceModel workspace,
  });

  Future<void> removeWorkspace({
    required String accountId,
    required String id,
  });

  Future<void> clearAccount({
    required String accountId,
  });
}

class WorkspaceLocalDataSource
    extends BaseLocalDataSource<WorkspaceModel, String>
    implements IWorkspaceLocalDataSource {
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
    final workspaceStore = HiveEntityStore<WorkspaceModel, String>(
      box: boxes[HiveBoxNames.workspaces],
      codec: const WorkspaceModelCodec(),
    );
    final provinceStore = HiveEntityStore<ProvinceModel, int>(
      box: boxes[HiveBoxNames.provinces],
      codec: const ProvinceModelCodec(),
    );
    final wardStore = HiveEntityStore<WardModel, int>(
      box: boxes[HiveBoxNames.wards],
      codec: const WardModelCodec(),
    );
    final userStore = HiveEntityStore<UserModel, String>(
      box: boxes[HiveBoxNames.users],
      codec: const UserModelCodec(),
    );

    final adapter = WorkspaceRelationAdapter(
      provinceStore: provinceStore,
      wardStore: wardStore,
      userStore: userStore,
    );

    return WorkspaceLocalDataSource(
      entityStore: workspaceStore,
      metadataBox: boxes[HiveBoxNames.metadata],
      relationAdapter: adapter,
    );
  }

  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<WorkspaceModel> items,
    bool isComplete = false,
  }) {
    return saveAll(
      accountId: accountId,
      items: items,
      isComplete: isComplete,
    );
  }

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) {
    return queryPage(
      accountId: accountId,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<WorkspaceModel?> getWorkspaceById({
    required String accountId,
    required String id,
  }) {
    return getById(
      accountId: accountId,
      id: id,
    );
  }

  @override
  Future<void> cacheCreatedWorkspace({
    required String accountId,
    required WorkspaceModel workspace,
  }) {
    return saveOne(
      accountId: accountId,
      item: workspace,
    );
  }

  @override
  Future<void> cacheUpdatedWorkspace({
    required String accountId,
    required WorkspaceModel workspace,
  }) {
    return saveOne(
      accountId: accountId,
      item: workspace,
    );
  }

  @override
  Future<void> removeWorkspace({
    required String accountId,
    required String id,
  }) {
    return deleteOne(
      accountId: accountId,
      id: id,
    );
  }
}
