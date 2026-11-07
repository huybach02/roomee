import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/hive/sync_mutation_store.dart';

void main() {
  late Directory directory;
  late Box<Map> box;
  late HiveSyncMutationStore store;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('hive_sync_mutation_test');
    Hive.init(directory.path);
    box = await Hive.openBox<Map>('test_sync_mutations');
    store = HiveSyncMutationStore(box: box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  group('HiveSyncMutationStore', () {
    test('adds and retrieves mutations in FIFO order', () async {
      final now = DateTime.now();
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          data: {'name': 'Ws 1'},
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-2',
          data: {'name': 'Ws 2'},
          createdAt: now,
        ),
      );

      final mutations = await store.getMutations(accountId: 'acc-1');
      expect(mutations.length, 2);
      expect(mutations[0].id, 'mut-1');
      expect(mutations[1].id, 'mut-2');
    });

    test('coalesces create followed by update into single create mutation',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          data: {'name': 'Initial Name', 'area': 100},
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-1',
          data: {'name': 'Updated Name', 'area': 120},
        ),
      );

      final mutations = await store.getMutations(accountId: 'acc-1');
      expect(mutations.length, 1);
      expect(mutations.first.id, 'mut-1');
      expect(mutations.first.action, SyncMutationAction.create);
      expect(mutations.first.data?['name'], 'Updated Name');
      expect(mutations.first.data?['area'], 120);
    });

    test('coalesces create followed by delete by completely cancelling mutation',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          data: {'name': 'Temporary Ws'},
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.delete,
          entityId: 'ws-1',
        ),
      );

      final mutations = await store.getMutations(accountId: 'acc-1');
      expect(mutations, isEmpty);
    });

    test('coalesces update followed by update by merging data', () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-1',
          data: {'name': 'Update 1', 'fieldA': 'A'},
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-1',
          data: {'name': 'Update 2', 'fieldB': 'B'},
        ),
      );

      final mutations = await store.getMutations(accountId: 'acc-1');
      expect(mutations.length, 1);
      expect(mutations.first.id, 'mut-1');
      expect(mutations.first.data?['name'], 'Update 2');
      expect(mutations.first.data?['fieldA'], 'A');
      expect(mutations.first.data?['fieldB'], 'B');
    });

    test('coalesces update followed by delete by replacing with delete mutation',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-1',
          data: {'name': 'Update 1'},
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.delete,
          entityId: 'ws-1',
        ),
      );

      final mutations = await store.getMutations(accountId: 'acc-1');
      expect(mutations.length, 1);
      expect(mutations.first.id, 'mut-2');
      expect(mutations.first.action, SyncMutationAction.delete);
    });

    test('removes applied mutations', () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
        ),
      );

      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-2',
        ),
      );

      await store.removeMutations(
        accountId: 'acc-1',
        mutationIds: ['mut-1'],
      );

      final remaining = await store.getMutations(accountId: 'acc-1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'mut-2');
    });

    test('clears all mutations for specific account', () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
        ),
      );

      await store.addMutation(
        accountId: 'acc-2',
        mutation: SyncMutation(
          id: 'mut-2',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-2',
        ),
      );

      await store.clearAccount(accountId: 'acc-1');

      expect(await store.getMutations(accountId: 'acc-1'), isEmpty);
      expect((await store.getMutations(accountId: 'acc-2')).length, 1);
    });
  });
}
