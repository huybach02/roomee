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
}

enum DataSourceKind { remote, local }
