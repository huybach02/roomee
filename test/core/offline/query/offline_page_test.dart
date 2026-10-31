import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

void main() {
  test('represents an empty local page and reaches the only page', () {
    const page = OfflinePage<int>(
      data: [],
      total: 0,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: false,
      source: DataSourceKind.local,
    );

    expect(page.data, isEmpty);
    expect(page.total, 0);
    expect(page.hasReachedMax, isTrue);
    expect(page.lastFetchedAt, isNull);
  });

  test('hasReachedMax is false before the final page', () {
    const page = OfflinePage<int>(
      data: [1],
      total: 21,
      page: 1,
      limit: 20,
      totalPages: 2,
      isComplete: true,
      source: DataSourceKind.local,
    );

    expect(page.hasReachedMax, isFalse);
  });
}
