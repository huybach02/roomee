import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/utils/function_helper.dart';

void main() {
  group('FunctionHelper.formatDateTime', () {
    test('returns placeholder when dateTime is null', () {
      expect(FunctionHelper.formatDateTime(null), '-');
      expect(
        FunctionHelper.formatDateTime(null, placeholder: 'N/A'),
        'N/A',
      );
    });

    test('formats dateTime with default pattern (dd/MM/yyyy HH:mm)', () {
      final date = DateTime(2026, 10, 25, 14, 30);
      expect(FunctionHelper.formatDateTime(date), '25/10/2026 14:30');
    });

    test('formats dateTime with custom pattern', () {
      final date = DateTime(2026, 10, 25, 14, 30);
      expect(
        FunctionHelper.formatDateTime(date, pattern: 'HH:mm dd-MM-yyyy'),
        '14:30 25-10-2026',
      );
    });
  });

  group('FunctionHelper.formatDate', () {
    test('returns placeholder when dateTime is null', () {
      expect(FunctionHelper.formatDate(null), '-');
      expect(
        FunctionHelper.formatDate(null, placeholder: 'Chưa có'),
        'Chưa có',
      );
    });

    test('formats date with default pattern (dd/MM/yyyy)', () {
      final date = DateTime(2026, 5, 8);
      expect(FunctionHelper.formatDate(date), '08/05/2026');
    });

    test('formats date with custom pattern', () {
      final date = DateTime(2026, 5, 8);
      expect(
        FunctionHelper.formatDate(date, pattern: 'yyyy-MM-dd'),
        '2026-05-08',
      );
    });
  });
}
