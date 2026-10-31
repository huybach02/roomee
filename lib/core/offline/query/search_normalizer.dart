import 'package:diacritic/diacritic.dart';

String normalizeSearch(String value) {
  return removeDiacritics(value).trim().toLowerCase();
}
