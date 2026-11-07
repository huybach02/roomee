import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/contracts/app_uuid.dart';

void main() {
  group('AppUuid.v4', () {
    test('generates a valid RFC 4122 v4 UUID format', () {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      for (var i = 0; i < 50; i++) {
        final id = AppUuid.v4();
        expect(uuidRegex.hasMatch(id), isTrue, reason: '$id is not a valid UUID v4');
      }
    });

    test('generates unique IDs', () {
      final ids = List.generate(100, (_) => AppUuid.v4());
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, ids.length);
    });
  });
}
