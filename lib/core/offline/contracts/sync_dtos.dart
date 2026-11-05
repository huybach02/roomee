class SyncItemDto {
  final String id;
  final String? updatedAt;

  const SyncItemDto({
    required this.id,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  factory SyncItemDto.fromJson(Map<String, dynamic> json) => SyncItemDto(
        id: json['id']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString(),
      );
}

class SyncResultDto {
  final List<Map<String, dynamic>> needUpdate;
  final List<String> needDelete;

  const SyncResultDto({
    this.needUpdate = const [],
    this.needDelete = const [],
  });

  factory SyncResultDto.fromJson(Map<String, dynamic> json) => SyncResultDto(
        needUpdate: (json['needUpdate'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
        needDelete: (json['needDelete'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'needUpdate': needUpdate,
        'needDelete': needDelete,
      };
}
