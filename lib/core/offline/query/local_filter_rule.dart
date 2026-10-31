enum LocalFilterOperator {
  equals,
  notEquals,
  contains,
  inList,
  greaterThan,
  lessThan,
  between,
  isNull,
}

class LocalFilterField<T> {
  final Object? Function(T) valueOf;
  final Set<LocalFilterOperator> operators;

  const LocalFilterField({required this.valueOf, required this.operators});
}
