import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/query/search_normalizer.dart';

void main() {
  test('removes Vietnamese diacritics and normalizes case and whitespace', () {
    expect(normalizeSearch('  KHU TRỌ ĐƯỜNG  '), 'khu tro duong');
  });

  test('normalizes query and model text consistently', () {
    expect(normalizeSearch('khu tro'), contains(normalizeSearch('Khu trọ')));
  });
}
