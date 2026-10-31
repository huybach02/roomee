import 'local_filter_rule.dart';

class LocalQuerySchema<T> {
  final List<String? Function(T)> searchFields;
  final Map<String, LocalFilterField<T>> filterFields;
  final Map<String, Comparable? Function(T)> sortFields;
  final String? Function(T)? uniqueId;

  const LocalQuerySchema({
    this.searchFields = const [],
    this.filterFields = const {},
    this.sortFields = const {},
    this.uniqueId,
  });
}
