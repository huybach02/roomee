enum SyncMutationAction {
  create,
  update,
  delete,
}

enum SyncMutationStatus {
  pending,
  inFlight,
  failed,
}

class SyncRejectedMutationDto {
  final String id;
  final String module;
  final String action;
  final String entityId;
  final int statusCode;
  final String reason;
  final dynamic details;

  const SyncRejectedMutationDto({
    required this.id,
    required this.module,
    required this.action,
    required this.entityId,
    required this.statusCode,
    required this.reason,
    this.details,
  });

  factory SyncRejectedMutationDto.fromJson(Map<String, dynamic> json) =>
      SyncRejectedMutationDto(
        id: json['id']?.toString() ?? '',
        module: json['module']?.toString() ?? '',
        action: json['action']?.toString() ?? 'create',
        entityId: json['entityId']?.toString() ?? '',
        statusCode: json['statusCode'] is int
            ? json['statusCode'] as int
            : int.tryParse(json['statusCode']?.toString() ?? '') ?? 500,
        reason: json['reason']?.toString() ?? '',
        details: json['details'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'action': action,
        'entityId': entityId,
        'statusCode': statusCode,
        'reason': reason,
        if (details != null) 'details': details,
      };
}

class SyncMutation {
  final String id;
  final String module;
  final SyncMutationAction action;
  final String entityId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final SyncMutationStatus status;
  final String? errorMessage;
  final int? statusCode;
  final dynamic errorDetails;
  final DateTime? failedAt;

  SyncMutation({
    required this.id,
    required this.module,
    required this.action,
    required this.entityId,
    this.data,
    DateTime? createdAt,
    this.status = SyncMutationStatus.pending,
    this.errorMessage,
    this.statusCode,
    this.errorDetails,
    this.failedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SyncMutation copyWith({
    String? id,
    String? module,
    SyncMutationAction? action,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    SyncMutationStatus? status,
    String? errorMessage,
    int? statusCode,
    dynamic errorDetails,
    DateTime? failedAt,
  }) =>
      SyncMutation(
        id: id ?? this.id,
        module: module ?? this.module,
        action: action ?? this.action,
        entityId: entityId ?? this.entityId,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        statusCode: statusCode ?? this.statusCode,
        errorDetails: errorDetails ?? this.errorDetails,
        failedAt: failedAt ?? this.failedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'action': action.name,
        'entityId': entityId,
        if (data != null) 'data': data,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (statusCode != null) 'statusCode': statusCode,
        if (errorDetails != null) 'errorDetails': errorDetails,
        if (failedAt != null) 'failedAt': failedAt!.toIso8601String(),
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
        status: json['status'] != null
            ? SyncMutationStatus.values
                    .where((e) => e.name == json['status'].toString())
                    .firstOrNull ??
                SyncMutationStatus.pending
            : SyncMutationStatus.pending,
        errorMessage: json['errorMessage']?.toString(),
        statusCode: json['statusCode'] is int
            ? json['statusCode'] as int
            : int.tryParse(json['statusCode']?.toString() ?? ''),
        errorDetails: json['errorDetails'],
        failedAt: json['failedAt'] != null
            ? DateTime.tryParse(json['failedAt'].toString())
            : null,
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
  final List<SyncRejectedMutationDto> rejectedMutations;
  final Map<String, SyncResultDto> entities;

  const SyncResponseDto({
    this.appliedMutationIds = const [],
    this.rejectedMutations = const [],
    this.entities = const {},
  });

  factory SyncResponseDto.fromJson(Map<String, dynamic> json) {
    final rawMutations = json['appliedMutationIds'] as List<dynamic>?;
    final appliedMutationIds =
        rawMutations?.map((e) => e.toString()).toList() ?? const [];

    final rawRejected = json['rejectedMutations'] as List<dynamic>?;
    final rejectedMutations = rawRejected
            ?.map((e) => SyncRejectedMutationDto.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList() ??
        const [];

    final rawEntities = json['entities'] as Map<dynamic, dynamic>? ?? json;
    final entities = <String, SyncResultDto>{};

    rawEntities.forEach((key, value) {
      if (key == 'appliedMutationIds' || key == 'rejectedMutations') return;
      if (value is Map) {
        entities[key.toString()] = SyncResultDto.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return SyncResponseDto(
      appliedMutationIds: appliedMutationIds,
      rejectedMutations: rejectedMutations,
      entities: entities,
    );
  }

  Map<String, dynamic> toJson() => {
        'appliedMutationIds': appliedMutationIds,
        'rejectedMutations': rejectedMutations.map((e) => e.toJson()).toList(),
        'entities': entities.map((k, v) => MapEntry(k, v.toJson())),
      };
}
