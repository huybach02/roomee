import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';

class _Record {
  final String id;
  final String name;

  const _Record(this.id, this.name);
}

class _RecordCodec extends EntityCodec<_Record, String> {
  @override
  String getId(_Record entity) => entity.id;

  @override
  Map<String, dynamic> toJson(_Record entity) => {
    'id': entity.id,
    'name': entity.name,
  };

  @override
  _Record fromJson(Map<String, dynamic> json) =>
      _Record(json['id'] as String, json['name'] as String);
}

class _TimestampedRecord {
  final String id;
  final String name;
  final DateTime? updatedAt;

  const _TimestampedRecord(this.id, this.name, [this.updatedAt]);
}

class _TimestampedCodec extends EntityCodec<_TimestampedRecord, String> {
  @override
  String getId(_TimestampedRecord entity) => entity.id;

  @override
  Map<String, dynamic> toJson(_TimestampedRecord entity) => {
    'id': entity.id,
    'name': entity.name,
    if (entity.updatedAt != null)
      'updatedAt': entity.updatedAt!.toIso8601String(),
  };

  @override
  _TimestampedRecord fromJson(Map<String, dynamic> json) => _TimestampedRecord(
    json['id'] as String,
    json['name'] as String,
    json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  @override
  DateTime? getUpdatedAt(_TimestampedRecord entity) => entity.updatedAt;
}

void main() {
  late Directory directory;
  late Box<Map> box;
  late HiveEntityStore<_Record, String> store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hive_entity_store_test');
    Hive.init(directory.path);
    box = await Hive.openBox<Map>('records');
    store = HiveEntityStore(box: box, codec: _RecordCodec());
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('stores and retrieves an entity by account and ID', () async {
    const record = _Record('record-1', 'One');

    await store.put(accountId: 'account-a', entity: record);

    final retrieved = await store.getById(
      accountId: 'account-a',
      id: 'record-1',
    );
    expect(retrieved?.name, 'One');
    expect(await store.getById(accountId: 'account-b', id: 'record-1'), isNull);
  });

  test('stores many entities and lists only the requested account', () async {
    await store.putMany(
      accountId: 'account-a',
      entities: const [_Record('1', 'One'), _Record('2', 'Two')],
    );
    await store.put(
      accountId: 'account-b',
      entity: const _Record('3', 'Three'),
    );

    final records = await store.getAll(accountId: 'account-a');

    expect(records.map((record) => record.id).toList(), ['1', '2']);
    expect(await store.getAll(accountId: 'account-b'), [isA<_Record>()]);
  });

  test('deletes only the entity for the specified account', () async {
    await store.put(accountId: 'account-a', entity: const _Record('1', 'A'));
    await store.put(accountId: 'account-b', entity: const _Record('1', 'B'));

    await store.delete(accountId: 'account-a', id: '1');

    expect(await store.getById(accountId: 'account-a', id: '1'), isNull);
    expect((await store.getById(accountId: 'account-b', id: '1'))?.name, 'B');
  });

  test('clearAccount preserves other account and global keys', () async {
    await store.put(accountId: 'abc', entity: const _Record('1', 'A'));
    await store.put(accountId: 'abc2', entity: const _Record('1', 'B'));
    await box.put(CacheKeyBuilder.global('1'), {'id': '1', 'name': 'Global'});

    await store.clearAccount(accountId: 'abc');

    expect(await store.getAll(accountId: 'abc'), isEmpty);
    expect((await store.getById(accountId: 'abc2', id: '1'))?.name, 'B');
    expect(box.get('global:1'), {'id': '1', 'name': 'Global'});
  });

  test(
    'putMany with an empty list leaves existing entries unchanged',
    () async {
      await store.put(
        accountId: 'account-a',
        entity: const _Record('1', 'One'),
      );

      await store.putMany(accountId: 'account-a', entities: const []);

      expect((await store.getAll(accountId: 'account-a')).single.name, 'One');
    },
  );

  test('propagates errors when a cached entity cannot be decoded', () async {
    await box.put(CacheKeyBuilder.entity('account-a', '1'), {
      'id': 1,
      'name': 'One',
    });

    expect(
      () => store.getById(accountId: 'account-a', id: '1'),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => store.getAll(accountId: 'account-a'),
      throwsA(isA<TypeError>()),
    );
  });

  test('count returns the correct number of entities for an account', () async {
    expect(await store.count(accountId: 'account-a'), 0);

    await store.putMany(
      accountId: 'account-a',
      entities: const [_Record('1', 'One'), _Record('2', 'Two')],
    );
    await store.put(
      accountId: 'account-b',
      entity: const _Record('3', 'Three'),
    );

    expect(await store.count(accountId: 'account-a'), 2);
    expect(await store.count(accountId: 'account-b'), 1);
    expect(await store.count(accountId: 'account-c'), 0);
  });

  group('version-aware upsert & tombstone protection', () {
    late HiveEntityStore<_TimestampedRecord, String> timestampedStore;

    setUp(() {
      timestampedStore = HiveEntityStore(
        box: box,
        codec: _TimestampedCodec(),
      );
    });

    test('overwrites older local data when incoming data is newer', () async {
      final t1 = DateTime.parse('2026-11-05T10:00:00Z');
      final t2 = DateTime.parse('2026-11-05T10:05:00Z');

      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Version 1', t1),
      );

      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Version 2', t2),
      );

      final result = await timestampedStore.getById(
        accountId: 'acc-1',
        id: 'w1',
      );
      expect(result?.name, 'Version 2');
    });

    test(
      'does NOT overwrite newer local data when incoming data is older',
      () async {
        final t1 = DateTime.parse('2026-11-05T10:00:00Z');
        final t2 = DateTime.parse('2026-11-05T10:05:00Z');

        // Local đã có bản ghi mới hơn (t2)
        await timestampedStore.put(
          accountId: 'acc-1',
          entity: _TimestampedRecord('w1', 'Version 2 (Newer)', t2),
        );

        // API list cũ đến sau mang bản ghi cũ hơn (t1)
        await timestampedStore.put(
          accountId: 'acc-1',
          entity: _TimestampedRecord('w1', 'Version 1 (Stale)', t1),
        );

        final result = await timestampedStore.getById(
          accountId: 'acc-1',
          id: 'w1',
        );
        // Vẫn giữ phiên bản mới hơn, không bị ghi đè!
        expect(result?.name, 'Version 2 (Newer)');
      },
    );

    test('blocks resurrection of deleted entity when stale data arrives',
        () async {
      final t1 = DateTime.parse('2026-11-05T09:00:00Z');

      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Active', t1),
      );

      // Xóa bản ghi
      await timestampedStore.delete(accountId: 'acc-1', id: 'w1');

      // Xác nhận đã xóa
      expect(
        await timestampedStore.getById(accountId: 'acc-1', id: 'w1'),
        isNull,
      );

      // Một API list cũ đến sau mang theo bản ghi w1 có updatedAt cũ hơn thời điểm xóa
      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Resurrect Attempt', t1),
      );

      // Bản ghi vẫn phải là null (không bị hồi sinh)
      expect(
        await timestampedStore.getById(accountId: 'acc-1', id: 'w1'),
        isNull,
      );
    });

    test(
      'allows recreation of deleted entity when incoming data is strictly newer than deletion',
      () async {
        await timestampedStore.delete(accountId: 'acc-1', id: 'w1');

        // Bản ghi mới được tạo lại trên server trong tương lai
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        await timestampedStore.put(
          accountId: 'acc-1',
          entity: _TimestampedRecord('w1', 'Recreated', futureTime),
        );

        final result = await timestampedStore.getById(
          accountId: 'acc-1',
          id: 'w1',
        );
        expect(result?.name, 'Recreated');
      },
    );

    test('applySync records tombstones and prevents stale resurrection',
        () async {
      final t1 = DateTime.parse('2026-11-05T08:00:00Z');
      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Before Sync', t1),
      );

      // Background sync báo w1 cần xóa
      await timestampedStore.applySync(
        accountId: 'acc-1',
        result: const SyncResultDto(needDelete: ['w1']),
      );

      expect(
        await timestampedStore.getById(accountId: 'acc-1', id: 'w1'),
        isNull,
      );

      // API list cũ đến sau chứa w1
      await timestampedStore.put(
        accountId: 'acc-1',
        entity: _TimestampedRecord('w1', 'Stale Resurrection', t1),
      );

      expect(
        await timestampedStore.getById(accountId: 'acc-1', id: 'w1'),
        isNull,
      );
    });

    test(
      'applySync throws FormatException and preserves existing data when parse fails',
      () async {
        final t1 = DateTime.parse('2026-11-05T08:00:00Z');
        await timestampedStore.put(
          accountId: 'acc-1',
          entity: _TimestampedRecord('w1', 'Original Item', t1),
        );

        // result mang needDelete w1, nhưng needUpdate có 1 bản ghi lỗi kiểu dữ liệu
        final badResult = SyncResultDto(
          needDelete: ['w1'],
          needUpdate: [
            // name không phải String -> parse lỗi
            {'id': 'w2', 'name': 12345},
          ],
        );

        expect(
          () => timestampedStore.applySync(
            accountId: 'acc-1',
            result: badResult,
          ),
          throwsA(isA<FormatException>()),
        );

        // Xác nhận: w1 KHÔNG bị xóa (toàn bộ mutation bị hủy bỏ, bảo toàn dữ liệu cũ)
        final preserved = await timestampedStore.getById(
          accountId: 'acc-1',
          id: 'w1',
        );
        expect(preserved?.name, 'Original Item');
      },
    );
  });
}
