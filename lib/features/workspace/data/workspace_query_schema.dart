import 'package:roomee/core/models/workspace_model.dart';
import 'package:roomee/core/offline/query/local_filter_rule.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';

final workspaceQuerySchema = LocalQuerySchema<WorkspaceModel>(
  searchFields: [
    (ws) => ws.name,
    (ws) => ws.address,
    (ws) => ws.contactName,
    (ws) => ws.contactPhone,
  ],
  filterFields: {
    'status': LocalFilterField(
      valueOf: (ws) => ws.status,
      operators: const {
        LocalFilterOperator.equals,
        LocalFilterOperator.notEquals,
        LocalFilterOperator.inList,
      },
    ),
    'type': LocalFilterField(
      valueOf: (ws) => ws.type.value,
      operators: const {
        LocalFilterOperator.equals,
        LocalFilterOperator.inList,
      },
    ),
    'provinceId': LocalFilterField(
      valueOf: (ws) => ws.provinceId,
      operators: const {
        LocalFilterOperator.equals,
        LocalFilterOperator.inList,
      },
    ),
    'wardId': LocalFilterField(
      valueOf: (ws) => ws.wardId,
      operators: const {
        LocalFilterOperator.equals,
        LocalFilterOperator.inList,
      },
    ),
    'area': LocalFilterField(
      valueOf: (ws) => ws.area,
      operators: const {
        LocalFilterOperator.equals,
        LocalFilterOperator.greaterThan,
        LocalFilterOperator.lessThan,
        LocalFilterOperator.between,
      },
    ),
  },
  sortFields: {
    'name': (ws) => ws.name,
    'area': (ws) => ws.area,
    'createdAt': (ws) => ws.createdAt,
    'status': (ws) => ws.status,
  },
  uniqueId: (ws) => ws.id,
);
