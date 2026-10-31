import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/hive/cache_metadata.dart';

void main() {
  test('serializes and parses metadata with timestamps', () {
    final metadata = CacheMetadata(
      entityName: 'workspaces',
      accountId: 'account-uuid',
      cacheFormatVersion: 1,
      isComplete: true,
      cachedCount: 40,
      lastFetchedAt: DateTime.parse('2026-10-30T10:00:00.000Z'),
      lastFullSyncAt: DateTime.parse('2026-10-29T10:00:00.000Z'),
    );

    final json = metadata.toJson();

    expect(json, {
      'entityName': 'workspaces',
      'accountId': 'account-uuid',
      'cacheFormatVersion': 1,
      'isComplete': true,
      'cachedCount': 40,
      'lastFetchedAt': '2026-10-30T10:00:00.000Z',
      'lastFullSyncAt': '2026-10-29T10:00:00.000Z',
    });
    expect(CacheMetadata.fromJson(json).lastFetchedAt, metadata.lastFetchedAt);
    expect(
      CacheMetadata.fromJson(json).lastFullSyncAt,
      metadata.lastFullSyncAt,
    );
  });

  test('serializes and parses null timestamps', () {
    final metadata = CacheMetadata(
      entityName: 'workspaces',
      accountId: 'account-uuid',
      cacheFormatVersion: 1,
    );

    expect(metadata.isComplete, isFalse);
    expect(metadata.cachedCount, 0);
    expect(metadata.toJson()['lastFetchedAt'], isNull);
    expect(metadata.toJson()['lastFullSyncAt'], isNull);
    expect(CacheMetadata.fromJson(metadata.toJson()).lastFetchedAt, isNull);
  });

  test('rejects missing required fields', () {
    expect(
      () => CacheMetadata.fromJson({
        'accountId': 'account-uuid',
        'cacheFormatVersion': 1,
        'isComplete': false,
        'cachedCount': 0,
      }),
      throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
    );
  });

  test('rejects incorrectly typed required fields', () {
    expect(
      () => CacheMetadata.fromJson({
        'entityName': 'workspaces',
        'accountId': 7,
        'cacheFormatVersion': 1,
        'isComplete': false,
        'cachedCount': 0,
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects invalid timestamp strings', () {
    expect(
      () => CacheMetadata.fromJson({
        'entityName': 'workspaces',
        'accountId': 'account-uuid',
        'cacheFormatVersion': 1,
        'isComplete': false,
        'cachedCount': 0,
        'lastFetchedAt': 'not-a-date',
        'lastFullSyncAt': null,
      }),
      throwsFormatException,
    );
  });
}
