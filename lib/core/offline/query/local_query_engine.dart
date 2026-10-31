import 'package:roomee/core/offline/hive/cache_metadata.dart';

import 'local_filter_rule.dart';
import 'local_query_schema.dart';
import 'offline_page.dart';
import 'search_normalizer.dart';

class LocalQueryEngine<T> {
  const LocalQueryEngine();

  OfflinePage<T> query({
    required List<T> items,
    required Map<String, dynamic> queryParameters,
    required LocalQuerySchema<T> schema,
    CacheMetadata? metadata,
  }) {
    Iterable<T> result = items;

    final rawSearch = queryParameters['search'];
    if (rawSearch is String && rawSearch.trim().isNotEmpty) {
      final search = normalizeSearch(rawSearch);
      result = result.where((item) {
        return schema.searchFields.any((field) {
          final value = field(item);
          return value != null && normalizeSearch(value).contains(search);
        });
      });
    }

    for (final entry in queryParameters.entries) {
      if (const {'search', 'sort', 'page', 'limit'}.contains(entry.key)) {
        continue;
      }

      final field = schema.filterFields[entry.key];
      if (field == null) continue;

      final rule = _parseFilter(entry.value);
      if (rule == null ||
          !field.operators.contains(rule.operator) ||
          !_hasValidValueShape(rule) ||
          !_isCompatibleFilter(field, rule, items)) {
        continue;
      }

      result = result.where((item) => _matches(field.valueOf(item), rule));
    }

    final filtered = result.toList();
    final sortCriteria = _parseSort(queryParameters['sort'], schema);
    if (sortCriteria.isNotEmpty) {
      final indexed = filtered.indexed
          .map((entry) => (item: entry.$2, index: entry.$1))
          .toList();
      indexed.sort((left, right) {
        for (final criterion in sortCriteria) {
          final leftValue = criterion.getValue(left.item);
          final rightValue = criterion.getValue(right.item);
          final comparison = _compareSortValues(leftValue, rightValue);
          if (comparison != 0) {
            if (leftValue == null || rightValue == null) return comparison;
            return criterion.descending ? -comparison : comparison;
          }
        }

        final leftId = schema.uniqueId?.call(left.item);
        final rightId = schema.uniqueId?.call(right.item);
        if (leftId != null && rightId != null) {
          final idComparison = leftId.compareTo(rightId);
          if (idComparison != 0) return idComparison;
        }
        return left.index.compareTo(right.index);
      });
      filtered
        ..clear()
        ..addAll(indexed.map((entry) => entry.item));
    }

    final page = _positiveInt(queryParameters['page'], fallback: 1);
    final limit = _positiveInt(queryParameters['limit'], fallback: 20);
    final total = filtered.length;
    final totalPages = total == 0 ? 1 : (total + limit - 1) ~/ limit;
    final start = (page - 1) * limit;
    final data = start >= total
        ? <T>[]
        : filtered.sublist(
            start,
            start + limit < total ? start + limit : total,
          );

    return OfflinePage<T>(
      data: data,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      isComplete: metadata?.isComplete ?? false,
      source: DataSourceKind.local,
      lastFetchedAt: metadata?.lastFetchedAt,
    );
  }

  _FilterRule? _parseFilter(Object? raw) {
    if (raw is Map) {
      final operatorName = raw['operator'];
      if (operatorName is! String) return null;
      final operator = LocalFilterOperator.values
          .where((candidate) => candidate.name == operatorName)
          .firstOrNull;
      if (operator == null) return null;
      if (operator == LocalFilterOperator.isNull) {
        return _FilterRule(operator);
      }
      if (!raw.containsKey('value')) return null;
      return _FilterRule(operator, raw['value']);
    }
    return _FilterRule(LocalFilterOperator.equals, raw);
  }

  bool _isCompatibleFilter(
    LocalFilterField<T> field,
    _FilterRule rule,
    List<T> items,
  ) {
    final values = items
        .map(field.valueOf)
        .where((value) => value != null)
        .toList();
    if (values.isEmpty) return true;

    bool matchesFieldType(Object value) => values.every((actual) {
      return actual!.runtimeType == value.runtimeType ||
          (actual is num && value is num);
    });

    switch (rule.operator) {
      case LocalFilterOperator.equals:
      case LocalFilterOperator.notEquals:
        return rule.value == null || matchesFieldType(rule.value as Object);
      case LocalFilterOperator.contains:
        return values.every((value) => value is String) && rule.value is String;
      case LocalFilterOperator.inList:
        return (rule.value as List).every(
          (value) => value == null || matchesFieldType(value),
        );
      case LocalFilterOperator.greaterThan:
      case LocalFilterOperator.lessThan:
        return values.every((value) => value is num) && rule.value is num;
      case LocalFilterOperator.between:
        return values.every((value) => value is num);
      case LocalFilterOperator.isNull:
        return true;
    }
  }

  bool _hasValidValueShape(_FilterRule rule) {
    switch (rule.operator) {
      case LocalFilterOperator.equals:
      case LocalFilterOperator.notEquals:
        return true;
      case LocalFilterOperator.contains:
        return rule.value is String;
      case LocalFilterOperator.inList:
        return rule.value is List;
      case LocalFilterOperator.greaterThan:
      case LocalFilterOperator.lessThan:
        return rule.value is num;
      case LocalFilterOperator.between:
        final range = rule.value;
        return range is List &&
            range.length == 2 &&
            range[0] is num &&
            range[1] is num;
      case LocalFilterOperator.isNull:
        return true;
    }
  }

  bool _matches(Object? actual, _FilterRule rule) {
    switch (rule.operator) {
      case LocalFilterOperator.equals:
        return actual == rule.value;
      case LocalFilterOperator.notEquals:
        return actual != rule.value;
      case LocalFilterOperator.contains:
        if (actual is! String || rule.value is! String) return false;
        return normalizeSearch(actual)
            .contains(normalizeSearch(rule.value as String));
      case LocalFilterOperator.inList:
        if (rule.value is! List) return true;
        return (rule.value as List).contains(actual);
      case LocalFilterOperator.greaterThan:
        if (actual is! num || rule.value is! num) return false;
        return actual > (rule.value as num);
      case LocalFilterOperator.lessThan:
        if (actual is! num || rule.value is! num) return false;
        return actual < (rule.value as num);
      case LocalFilterOperator.between:
        final range = rule.value;
        if (actual is! num || range is! List || range.length != 2) return false;
        final lower = range[0];
        final upper = range[1];
        if (lower is! num || upper is! num) return true;
        return actual >= lower && actual <= upper;
      case LocalFilterOperator.isNull:
        return actual == null;
    }
  }

  List<_SortCriterion<T>> _parseSort(Object? raw, LocalQuerySchema<T> schema) {
    if (raw is! String) return [];

    final criteria = <_SortCriterion<T>>[];
    for (final part in raw.split(',')) {
      final pieces = part.split(':');
      if (pieces.length != 2) continue;
      final fieldName = pieces[0].trim();
      final order = pieces[1].trim().toLowerCase();
      final getter = schema.sortFields[fieldName];
      if (getter == null || (order != 'asc' && order != 'desc')) continue;
      criteria.add(_SortCriterion(getter, order == 'desc'));
    }
    return criteria;
  }

  int _compareSortValues(Comparable? left, Comparable? right) {
    if (left == null) return right == null ? 0 : 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  int _positiveInt(Object? value, {required int fallback}) {
    return value is int && value > 0 ? value : fallback;
  }
}

class _FilterRule {
  final LocalFilterOperator operator;
  final Object? value;

  const _FilterRule(this.operator, [this.value]);
}

class _SortCriterion<T> {
  final Comparable? Function(T) getValue;
  final bool descending;

  const _SortCriterion(this.getValue, this.descending);
}
