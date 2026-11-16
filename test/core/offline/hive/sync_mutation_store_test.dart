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

    test('purgeExpired removes only mutations older than maxAge', () async {
      final now = DateTime.now();
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'old-mut',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-old',
          createdAt: now.subtract(const Duration(days: 31)),
        ),
      );
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'fresh-mut',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-fresh',
          createdAt: now,
        ),
      );

      final purged = await store.purgeExpired(maxAge: const Duration(days: 30));

      expect(purged, 1);
      final remaining = await store.getMutations(accountId: 'acc-1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'fresh-mut');
    });

    test('markMutationsAsFailed updates status, error info and timestamp',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
        ),
      );

      await store.markMutationsAsFailed(
        accountId: 'acc-1',
        failures: [
          const SyncRejectedMutationDto(
            id: 'mut-1',
            module: 'workspaces',
            action: 'create',
            entityId: 'ws-1',
            statusCode: 400,
            reason: 'Name must not be empty',
            details: {'field': 'name'},
          ),
        ],
      );

      final failed = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.failed,
      );
      expect(failed.length, 1);
      expect(failed.first.id, 'mut-1');
      expect(failed.first.status, SyncMutationStatus.failed);
      expect(failed.first.errorMessage, 'Name must not be empty');
      expect(failed.first.statusCode, 400);
      expect(failed.first.errorDetails, {'field': 'name'});
      expect(failed.first.failedAt, isNotNull);

      // pending list rỗng
      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending, isEmpty);
    });

    test('getProtectedCreateEntityIds returns all create entity IDs', () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-create',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-create',
        ),
      );
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-update',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-update',
        ),
      );

      final protectedIds =
          await store.getProtectedCreateEntityIds(accountId: 'acc-1');
      expect(protectedIds, {'ws-create'});
      expect(protectedIds.contains('ws-update'), isFalse);
    });

    test('resetMutationToPending resets failed mutation back to pending',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          status: SyncMutationStatus.failed,
          errorMessage: 'Bad input',
          data: {'name': 'Old'},
        ),
      );

      await store.resetMutationToPending(
        accountId: 'acc-1',
        mutationId: 'mut-1',
        updatedData: {'name': 'New'},
      );

      final mutations = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(mutations.length, 1);
      expect(mutations.first.status, SyncMutationStatus.pending);
      expect(mutations.first.data?['name'], 'New');
    });

    test('markMutationsAsInFlight marks pending mutations as inFlight',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
          data: {'name': 'Ws 1'},
        ),
      );

      await store.markMutationsAsInFlight(
        accountId: 'acc-1',
        mutationIds: ['mut-1'],
      );

      final inFlight = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.inFlight,
      );
      expect(inFlight.length, 1);
      expect(inFlight.first.id, 'mut-1');
      expect(inFlight.first.status, SyncMutationStatus.inFlight);

      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending, isEmpty);
    });

    test('resetInFlightMutations resets inFlight mutations back to pending',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-1',
        ),
      );
      await store.markMutationsAsInFlight(
        accountId: 'acc-1',
        mutationIds: ['mut-1'],
      );

      await store.resetInFlightMutations(accountId: 'acc-1');

      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.length, 1);
      expect(pending.first.id, 'mut-1');
      expect(pending.first.status, SyncMutationStatus.pending);
    });

    test(
        'does not coalesce update into in-flight mutation, creates separate pending mutation',
        () async {
      // 1. Tạo phiếu P1 và chuyển sang inFlight (đang bay trên mạng)
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-p1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-race',
          data: {'name': 'Hoa Lan'},
        ),
      );
      await store.markMutationsAsInFlight(
        accountId: 'acc-1',
        mutationIds: ['mut-p1'],
      );

      // 2. Người dùng sửa tiếp thành "Hoa Sứ" trong lúc P1 đang bay
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-p2',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-race',
          data: {'name': 'Hoa Sứ'},
        ),
      );

      // P1 phải còn nguyên trạng thái inFlight và tên cũ
      final inFlight = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.inFlight,
      );
      expect(inFlight.length, 1);
      expect(inFlight.first.id, 'mut-p1');
      expect(inFlight.first.data?['name'], 'Hoa Lan');

      // P2 được lưu thành 1 phiếu update pending độc lập
      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.length, 1);
      expect(pending.first.id, 'mut-p2');
      expect(pending.first.action, SyncMutationAction.update);
      expect(pending.first.data?['name'], 'Hoa Sứ');

      // Khi P1 xong và bị xóa, P2 vẫn an toàn trong sổ
      await store.removeMutations(accountId: 'acc-1', mutationIds: ['mut-p1']);
      final remaining = await store.getMutations(accountId: 'acc-1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'mut-p2');
      expect(remaining.first.data?['name'], 'Hoa Sứ');
    });

    test(
        'coalesces subsequent update into the pending mutation while in-flight mutation remains isolated',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-p1',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-multi',
          data: {'name': 'V1', 'area': 50},
        ),
      );
      await store.markMutationsAsInFlight(
        accountId: 'acc-1',
        mutationIds: ['mut-p1'],
      );

      // Lần sửa 1: tạo P2 pending
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-p2',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-multi',
          data: {'name': 'V2'},
        ),
      );

      // Lần sửa 2: gộp tiếp vào P2 pending
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-p3',
          module: 'workspaces',
          action: SyncMutationAction.update,
          entityId: 'ws-multi',
          data: {'area': 100},
        ),
      );

      final inFlight = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.inFlight,
      );
      expect(inFlight.length, 1);
      expect(inFlight.first.id, 'mut-p1');

      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.length, 1);
      expect(pending.first.id, 'mut-p2');
      expect(pending.first.data?['name'], 'V2');
      expect(pending.first.data?['area'], 100);
    });

    test('purgeExpired automatically resets orphan inFlight mutations',
        () async {
      await store.addMutation(
        accountId: 'acc-1',
        mutation: SyncMutation(
          id: 'mut-orphan',
          module: 'workspaces',
          action: SyncMutationAction.create,
          entityId: 'ws-orphan',
        ),
      );
      await store.markMutationsAsInFlight(
        accountId: 'acc-1',
        mutationIds: ['mut-orphan'],
      );

      // Giả lập app mở lại và gọi purgeExpired
      await store.purgeExpired(maxAge: const Duration(days: 30));

      final inFlight = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.inFlight,
      );
      expect(inFlight, isEmpty);

      final pending = await store.getMutations(
        accountId: 'acc-1',
        status: SyncMutationStatus.pending,
      );
      expect(pending.length, 1);
      expect(pending.first.id, 'mut-orphan');
    });
  });
}
