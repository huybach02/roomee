class CacheMetadata {
  final String entityName;
  final String accountId;
  final int cacheFormatVersion;
  final bool isComplete;
  final int cachedCount;
  final DateTime? lastFetchedAt;
  final DateTime? lastFullSyncAt;

  const CacheMetadata({
    required this.entityName,
    required this.accountId,
    required this.cacheFormatVersion,
    this.isComplete = false,
    this.cachedCount = 0,
    this.lastFetchedAt,
    this.lastFullSyncAt,
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      entityName: json['entityName'] as String,
      accountId: json['accountId'] as String,
      cacheFormatVersion: json['cacheFormatVersion'] as int,
      isComplete: json['isComplete'] as bool,
      cachedCount: json['cachedCount'] as int,
      lastFetchedAt: json['lastFetchedAt'] == null
          ? null
          : DateTime.parse(json['lastFetchedAt'] as String),
      lastFullSyncAt: json['lastFullSyncAt'] == null
          ? null
          : DateTime.parse(json['lastFullSyncAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'entityName': entityName,
    'accountId': accountId,
    'cacheFormatVersion': cacheFormatVersion,
    'isComplete': isComplete,
    'cachedCount': cachedCount,
    'lastFetchedAt': lastFetchedAt?.toIso8601String(),
    'lastFullSyncAt': lastFullSyncAt?.toIso8601String(),
  };
}
