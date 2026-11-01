class OfflinePage<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool isComplete;
  final DataSourceKind source;
  final DateTime? lastFetchedAt;

  const OfflinePage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.isComplete,
    required this.source,
    this.lastFetchedAt,
  });

  bool get hasReachedMax => page >= totalPages;

  OfflinePage<T> copyWith({
    List<T>? data,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    bool? isComplete,
    DataSourceKind? source,
    DateTime? lastFetchedAt,
  }) {
    return OfflinePage<T>(
      data: data ?? this.data,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      isComplete: isComplete ?? this.isComplete,
      source: source ?? this.source,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}

enum DataSourceKind { remote, local }
