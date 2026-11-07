enum SyncMutationAction {
  create,
  update,
  delete,
}

class SyncMutation {
  final String id;
  final String module;
  final SyncMutationAction action;
  final String entityId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  SyncMutation({
    required this.id,
    required this.module,
    required this.action,
    required this.entityId,
    this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'action': action.name,
        'entityId': entityId,
        if (data != null) 'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncMutation.fromJson(Map<String, dynamic> json) => SyncMutation(
        id: json['id']?.toString() ?? '',
        module: json['module']?.toString() ?? '',
        action: SyncMutationAction.values.byName(
          json['action']?.toString() ?? 'create',
        ),
        entityId: json['entityId']?.toString() ?? '',
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

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

class SyncResponseDto {
  final List<String> appliedMutationIds;
  final Map<String, SyncResultDto> entities;

  const SyncResponseDto({
    this.appliedMutationIds = const [],
    this.entities = const {},
  });

  factory SyncResponseDto.fromJson(Map<String, dynamic> json) {
    final rawMutations = json['appliedMutationIds'] as List<dynamic>?;
    final appliedMutationIds =
        rawMutations?.map((e) => e.toString()).toList() ?? const [];

    final rawEntities = json['entities'] as Map<dynamic, dynamic>? ?? json;
    final entities = <String, SyncResultDto>{};

    rawEntities.forEach((key, value) {
      if (key == 'appliedMutationIds') return;
      if (value is Map) {
        entities[key.toString()] = SyncResultDto.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return SyncResponseDto(
      appliedMutationIds: appliedMutationIds,
      entities: entities,
    );
  }

  Map<String, dynamic> toJson() => {
        'appliedMutationIds': appliedMutationIds,
        'entities': entities.map((k, v) => MapEntry(k, v.toJson())),
      };
}
