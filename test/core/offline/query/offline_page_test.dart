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

  test('copyWith replaces data while preserving other properties', () {
    final fetchedAt = DateTime(2026, 11, 1);
    final page = OfflinePage<int>(
      data: [1, 2],
      total: 2,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: true,
      source: DataSourceKind.local,
      lastFetchedAt: fetchedAt,
    );

    final updated = page.copyWith(data: [10, 20]);

    expect(updated.data, [10, 20]);
    expect(updated.total, 2);
    expect(updated.page, 1);
    expect(updated.limit, 20);
    expect(updated.totalPages, 1);
    expect(updated.isComplete, isTrue);
    expect(updated.source, DataSourceKind.local);
    expect(updated.lastFetchedAt, fetchedAt);
  });
}
