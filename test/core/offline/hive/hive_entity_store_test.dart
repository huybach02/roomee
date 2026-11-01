import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';
import 'package:roomee/core/offline/hive/cache_key_builder.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';

class _Record {
  final String id;
  final String name;

  const _Record(this.id, this.name);
}

class _RecordCodec implements EntityCodec<_Record, String> {
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
}
