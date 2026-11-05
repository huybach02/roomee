enum LocalFilterOperator {
  equals,
  notEquals,
  contains,
  inList,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
  between,
  isNull,
}

class LocalFilterField<T> {
  final Object? Function(T) valueOf;
  final Set<LocalFilterOperator> operators;
  final bool Function(Object value) accepts;

  const LocalFilterField({
    required this.valueOf,
    required this.operators,
    required this.accepts,
  });
}
