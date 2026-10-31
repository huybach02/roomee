import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/query/local_filter_rule.dart';
import 'package:roomee/core/offline/query/local_query_schema.dart';

class _Item {
  final String id;
  final String name;
  final double area;

  const _Item(this.id, this.name, this.area);
}

void main() {
  test('schema declares search, filter, sort, and unique ID accessors', () {
    final schema = LocalQuerySchema<_Item>(
      searchFields: [(item) => item.name],
      filterFields: {
        'area': LocalFilterField(
          valueOf: (item) => item.area,
          operators: {LocalFilterOperator.between},
        ),
      },
      sortFields: {'name': (item) => item.name},
      uniqueId: (item) => item.id,
    );

    const item = _Item('item-1', 'One', 10);
    expect(schema.searchFields.single(item), 'One');
    expect(schema.filterFields['area']!.valueOf(item), 10);
    expect(schema.sortFields['name']!(item), 'One');
    expect(schema.uniqueId!(item), 'item-1');
  });

  test('schema defaults to empty fields', () {
    const schema = LocalQuerySchema<_Item>();

    expect(schema.searchFields, isEmpty);
    expect(schema.filterFields, isEmpty);
    expect(schema.sortFields, isEmpty);
    expect(schema.uniqueId, isNull);
  });
}
