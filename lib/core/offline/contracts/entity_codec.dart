abstract class EntityCodec<T, ID> {
  const EntityCodec();

  ID getId(T entity);

  Map<String, dynamic> toJson(T entity);

  T fromJson(Map<String, dynamic> json);

  DateTime? getUpdatedAt(T entity) => null;

  DateTime? extractUpdatedAtFromJson(Map json) {
    final raw = json['updatedAt'] ?? json['updated_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
