import 'package:roomee/core/models/workspace_model.dart';
import 'package:roomee/core/offline/query/local_filter_rule.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';
import 'package:roomee/utils/constanst.dart';

final workspaceQuerySchema = LocalQuerySchema<WorkspaceModel>(
  searchFields: [
    (ws) => ws.name,
    (ws) => ws.address,
    (ws) => ws.contactName,
    (ws) => ws.contactPhone,
    (ws) => ws.province?.fullName,
    (ws) => ws.ward?.fullName,
  ],
  filterFields: {
    'status': LocalFilterField(
      valueOf: (ws) => ws.status,
      operators: const {LocalFilterOperator.equals},
      accepts: (v) => v is int,
    ),
    'type': LocalFilterField(
      valueOf: (ws) => ws.type.value,
      operators: const {LocalFilterOperator.equals},
      accepts: (v) =>
          v is String && WorkspaceType.values.any((t) => t.value == v),
    ),
    'provinceId': LocalFilterField(
      valueOf: (ws) => ws.provinceId,
      operators: const {LocalFilterOperator.equals},
      accepts: (v) => v is int,
    ),
    'wardId': LocalFilterField(
      valueOf: (ws) => ws.wardId,
      operators: const {LocalFilterOperator.equals},
      accepts: (v) => v is int,
    ),
    'areaMin': LocalFilterField(
      valueOf: (ws) => ws.area,
      operators: const {LocalFilterOperator.greaterThanOrEquals},
      accepts: (v) => v is num,
      defaultOperator: LocalFilterOperator.greaterThanOrEquals,
    ),
    'areaMax': LocalFilterField(
      valueOf: (ws) => ws.area,
      operators: const {LocalFilterOperator.lessThanOrEquals},
      accepts: (v) => v is num,
      defaultOperator: LocalFilterOperator.lessThanOrEquals,
    ),
  },
  sortFields: {
    'name': (ws) => ws.name,
    'area': (ws) => ws.area,
    'createdAt': (ws) => ws.createdAt,
    'status': (ws) => ws.status,
    'numberOfRooms': (ws) => ws.numberOfRooms,
  },
  uniqueId: (ws) => ws.id,
);
