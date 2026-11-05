import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';

void main() {
  group('SyncItemDto', () {
    test('toJson and fromJson work correctly', () {
      const item = SyncItemDto(
        id: 'ws-1',
        updatedAt: '2026-11-05T10:00:00.000Z',
      );

      final json = item.toJson();
      expect(json['id'], 'ws-1');
      expect(json['updatedAt'], '2026-11-05T10:00:00.000Z');

      final fromJson = SyncItemDto.fromJson(json);
      expect(fromJson.id, 'ws-1');
      expect(fromJson.updatedAt, '2026-11-05T10:00:00.000Z');
    });

    test('toJson omits updatedAt when null', () {
      const item = SyncItemDto(id: 'ws-2');
      final json = item.toJson();

      expect(json['id'], 'ws-2');
      expect(json.containsKey('updatedAt'), isFalse);
    });
  });

  group('SyncResultDto', () {
    test('fromJson and toJson parse needUpdate and needDelete properly', () {
      final json = {
        'needUpdate': [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ],
        'needDelete': ['3', '4'],
      };

      final result = SyncResultDto.fromJson(json);
      expect(result.needUpdate.length, 2);
      expect(result.needUpdate.first['name'], 'Item 1');
      expect(result.needDelete, ['3', '4']);

      final serialized = result.toJson();
      expect(serialized['needUpdate'], result.needUpdate);
      expect(serialized['needDelete'], result.needDelete);
    });

    test('fromJson handles null / missing fields safely', () {
      final result = SyncResultDto.fromJson(const {});
      expect(result.needUpdate, isEmpty);
      expect(result.needDelete, isEmpty);
    });
  });
}
