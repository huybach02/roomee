import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/hive/cache_metadata.dart';
import 'package:roomee/core/offline/query/local_filter_rule.dart';
import 'package:roomee/core/offline/query/local_query_engine.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

class _Workspace {
  final String id;
  final String name;
  final String? address;
  final int status;
  final int provinceId;
  final num? area;
  final DateTime? createdAt;

  const _Workspace({
    required this.id,
    required this.name,
    this.address,
    required this.status,
    required this.provinceId,
    required this.area,
    this.createdAt,
  });
}

final _schema = LocalQuerySchema<_Workspace>(
  searchFields: [
    (workspace) => workspace.name,
    (workspace) => workspace.address,
  ],
  filterFields: {
    'status': LocalFilterField(
      valueOf: (workspace) => workspace.status,
      operators: {
        LocalFilterOperator.equals,
        LocalFilterOperator.notEquals,
        LocalFilterOperator.inList,
      },
      accepts: (v) => v is int || (v is num && v == v.round()),
    ),
    'provinceId': LocalFilterField(
      valueOf: (workspace) => workspace.provinceId,
      operators: {LocalFilterOperator.equals},
      accepts: (v) => v is int,
    ),
    'area': LocalFilterField(
      valueOf: (workspace) => workspace.area,
      operators: {
        LocalFilterOperator.equals,
        LocalFilterOperator.greaterThan,
        LocalFilterOperator.greaterThanOrEquals,
        LocalFilterOperator.lessThan,
        LocalFilterOperator.lessThanOrEquals,
        LocalFilterOperator.between,
      },
      accepts: (v) => v is num,
    ),
    'name': LocalFilterField(
      valueOf: (workspace) => workspace.name,
      operators: {
        LocalFilterOperator.contains,
        LocalFilterOperator.equals,
        LocalFilterOperator.notEquals,
      },
      accepts: (v) => v is String,
    ),
    'areaMin': LocalFilterField(
      valueOf: (workspace) => workspace.area,
      operators: {LocalFilterOperator.greaterThanOrEquals},
      accepts: (v) => v is num,
      defaultOperator: LocalFilterOperator.greaterThanOrEquals,
    ),
    'areaMax': LocalFilterField(
      valueOf: (workspace) => workspace.area,
      operators: {LocalFilterOperator.lessThanOrEquals},
      accepts: (v) => v is num,
      defaultOperator: LocalFilterOperator.lessThanOrEquals,
    ),
    'address': LocalFilterField(
      valueOf: (workspace) => workspace.address,
      operators: {
        LocalFilterOperator.isNull,
        LocalFilterOperator.equals,
        LocalFilterOperator.contains,
      },
      accepts: (v) => v is String,
    ),
  },
  sortFields: {
    'area': (workspace) => workspace.area,
    'name': (workspace) => workspace.name,
    'createdAt': (workspace) => workspace.createdAt,
  },
  uniqueId: (workspace) => workspace.id,
);

final _workspaces = [
  _Workspace(
    id: 'w3',
    name: 'Khu trọ C',
    address: 'Đường Ba',
    status: 1,
    provinceId: 92,
    area: 50,
    createdAt: DateTime(2026, 1, 3),
  ),
  _Workspace(
    id: 'w2',
    name: 'Khu trọ B',
    address: null,
    status: 0,
    provinceId: 79,
    area: 100,
    createdAt: DateTime(2026, 1, 2),
  ),
  _Workspace(
    id: 'w1',
    name: 'Khu trọ A',
    address: 'Đường Một',
    status: 1,
    provinceId: 92,
    area: 100,
    createdAt: null,
  ),
  _Workspace(
    id: 'w4',
    name: 'Nhà riêng',
    address: 'Đường Tư',
    status: 0,
    provinceId: 79,
    area: 20,
    createdAt: DateTime(2026, 1, 4),
  ),
];

void main() {
  const engine = LocalQueryEngine<_Workspace>();

  test('searches and filters all records before sorting and pagination', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {
        'search': '  KHU TRO ',
        'status': 1,
        'provinceId': 92,
        'sort': 'area:desc,name:asc',
        'page': 2,
        'limit': 1,
      },
      schema: _schema,
    );

    expect(page.total, 2);
    expect(page.data.single.id, 'w3');
    expect(page.totalPages, 2);
    expect(page.page, 2);
  });

  test('applies all whitelisted filter operators', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {
        'status': {'operator': 'notEquals', 'value': 0},
        'area': {
          'operator': 'between',
          'value': [50, 100],
        },
        'name': {'operator': 'contains', 'value': 'khu tro'},
      },
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id).toSet(), {'w1', 'w3'});

    final inList = engine.query(
      items: _workspaces,
      queryParameters: {
        'status': {
          'operator': 'inList',
          'value': [1],
        },
      },
      schema: _schema,
    );
    expect(inList.total, 2);

    final greater = engine.query(
      items: _workspaces,
      queryParameters: {
        'area': {'operator': 'greaterThan', 'value': 50.5},
      },
      schema: _schema,
    );
    expect(greater.data.map((workspace) => workspace.id).toSet(), {'w1', 'w2'});

    final less = engine.query(
      items: _workspaces,
      queryParameters: {
        'area': {'operator': 'lessThan', 'value': 50.5},
      },
      schema: _schema,
    );
    expect(less.data.map((workspace) => workspace.id).toSet(), {'w3', 'w4'});

    final greaterOrEqual = engine.query(
      items: _workspaces,
      queryParameters: {
        'area': {'operator': 'greaterThanOrEquals', 'value': 50},
      },
      schema: _schema,
    );
    expect(greaterOrEqual.data.map((workspace) => workspace.id).toSet(), {
      'w1',
      'w2',
      'w3',
    });

    final lessOrEqual = engine.query(
      items: _workspaces,
      queryParameters: {
        'area': {'operator': 'lessThanOrEquals', 'value': 50},
      },
      schema: _schema,
    );
    expect(lessOrEqual.data.map((workspace) => workspace.id).toSet(), {
      'w3',
      'w4',
    });

    final isNull = engine.query(
      items: _workspaces,
      queryParameters: {
        'address': {'operator': 'isNull'},
      },
      schema: _schema,
    );
    expect(isNull.data.single.id, 'w2');
  });

  test('applies default operator when query value is a scalar', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {'areaMin': 50, 'areaMax': 100},
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id).toSet(), {
      'w1',
      'w2',
      'w3',
    });
  });

  test('ignores numeric ordering filters on null field values', () {
    final items = [
      _Workspace(
        id: 'with-area',
        name: 'With area',
        status: 1,
        provinceId: 1,
        area: 30,
      ),
      const _Workspace(
        id: 'without-area',
        name: 'Without area',
        status: 1,
        provinceId: 1,
        area: null,
      ),
    ];

    final page = engine.query(
      items: items,
      queryParameters: {
        'area': {'operator': 'greaterThan', 'value': 10},
      },
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id), ['with-area']);
  });

  test('does not match null strings for contains', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {
        'address': {'operator': 'contains', 'value': 'duong'},
      },
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id).toSet(), {
      'w3',
      'w1',
      'w4',
    });
  });

  test('uses Dart equality for null and notEquals filters', () {
    final nullEquals = engine.query(
      items: _workspaces,
      queryParameters: {'address': null},
      schema: _schema,
    );
    expect(nullEquals.data.single.id, 'w2');

    final notEquals = engine.query(
      items: _workspaces,
      queryParameters: {
        'status': {'operator': 'notEquals', 'value': 1},
      },
      schema: _schema,
    );
    expect(notEquals.total, 2);
  });

  test(
    'ignores fields, operators, values, and sort criteria outside schema',
    () {
      final page = engine.query(
        items: _workspaces,
        queryParameters: {
          'unknown': 'ignored',
          'status': {
            'operator': 'between',
            'value': [0, 1],
          },
          'area': {
            'operator': 'between',
            'value': [100],
          },
          'provinceId': 'wrong-type',
          'sort': 'unknown:asc,area:sideways,name',
        },
        schema: _schema,
      );

      expect(page.total, _workspaces.length);
      expect(
        page.data.map((workspace) => workspace.id),
        _workspaces.map((workspace) => workspace.id),
      );
    },
  );

  test('uses Dart numeric equality for equality filters', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {'status': 1.0},
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id).toSet(), {'w1', 'w3'});
  });

  test('sorts by null-last criteria then stable unique ID', () {
    final page = engine.query(
      items: _workspaces,
      queryParameters: {'sort': 'createdAt:desc,area:desc'},
      schema: _schema,
    );

    expect(page.data.map((workspace) => workspace.id).toList(), [
      'w4',
      'w3',
      'w2',
      'w1',
    ]);
  });

  test('keeps input order when sort ties and unique ID is absent', () {
    final schema = LocalQuerySchema<_Workspace>(
      sortFields: {'status': (workspace) => workspace.status},
    );

    final page = engine.query(
      items: _workspaces,
      queryParameters: {'sort': 'status:asc'},
      schema: schema,
    );

    expect(page.data.map((workspace) => workspace.id).toList(), [
      'w2',
      'w4',
      'w3',
      'w1',
    ]);
  });

  test(
    'defaults invalid paging and does not clamp a valid out-of-range page',
    () {
      final defaults = engine.query(
        items: _workspaces,
        queryParameters: {'page': 0, 'limit': -1},
        schema: _schema,
      );
      expect(defaults.page, 1);
      expect(defaults.limit, 20);

      final outOfRange = engine.query(
        items: _workspaces,
        queryParameters: {'page': 4, 'limit': 2},
        schema: _schema,
      );
      expect(outOfRange.page, 4);
      expect(outOfRange.data, isEmpty);
      expect(outOfRange.totalPages, 2);
    },
  );

  test(
    'returns local source and cache metadata with empty result semantics',
    () {
      final fetchedAt = DateTime(2026, 10, 30);
      final metadata = CacheMetadata(
        entityName: 'workspaces',
        accountId: 'account-uuid',
        cacheFormatVersion: 1,
        isComplete: true,
        cachedCount: 4,
        lastFetchedAt: fetchedAt,
      );
      final page = engine.query(
        items: _workspaces,
        queryParameters: {'search': 'no match'},
        schema: _schema,
        metadata: metadata,
      );

      expect(page.data, isEmpty);
      expect(page.total, 0);
      expect(page.totalPages, 1);
      expect(page.source, DataSourceKind.local);
      expect(page.isComplete, isTrue);
      expect(page.lastFetchedAt, fetchedAt);

      final withoutMetadata = engine.query(
        items: _workspaces,
        queryParameters: const {},
        schema: _schema,
      );
      expect(withoutMetadata.isComplete, isFalse);
      expect(withoutMetadata.lastFetchedAt, isNull);
    },
  );

  test('validates filter value types using accepts callback and ignores incompatible rules', () {
    // 1. inList with one invalid element type is ignored
    final invalidInList = engine.query(
      items: _workspaces,
      queryParameters: {
        'status': {
          'operator': 'inList',
          'value': [1, 'invalid_type'],
        },
      },
      schema: _schema,
    );
    expect(invalidInList.total, _workspaces.length);

    // 2. inList with valid elements is applied
    final validInList = engine.query(
      items: _workspaces,
      queryParameters: {
        'status': {
          'operator': 'inList',
          'value': [1],
        },
      },
      schema: _schema,
    );
    expect(validInList.total, 2);

    // 3. between with non-accepted value is ignored
    final invalidBetween = engine.query(
      items: _workspaces,
      queryParameters: {
        'area': {
          'operator': 'between',
          'value': [20, '100'],
        },
      },
      schema: _schema,
    );
    expect(invalidBetween.total, _workspaces.length);

    // 4. Empty cache does not bypass type check: wrong type is rejected even on empty list
    final emptyCacheResult = engine.query(
      items: <_Workspace>[],
      queryParameters: {'provinceId': 'wrong-string-type'},
      schema: _schema,
    );
    expect(emptyCacheResult.data, isEmpty);
  });
}
