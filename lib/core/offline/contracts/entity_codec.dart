abstract interface class EntityCodec<T, ID> {
  ID getId(T entity);

  Map<String, dynamic> toJson(T entity);

  T fromJson(Map<String, dynamic> json);
}
