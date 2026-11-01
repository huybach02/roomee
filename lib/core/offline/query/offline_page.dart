import 'package:roomee/core/models/pagination_model.dart';

class OfflinePage<T> extends PaginationModel<T> {
  final bool isComplete;
  final DataSourceKind source;
  final DateTime? lastFetchedAt;

  const OfflinePage({
    required super.data,
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
    required this.isComplete,
    required this.source,
    this.lastFetchedAt,
  });

  factory OfflinePage.fromPaginationModel(
    PaginationModel<T> pagination, {
    DateTime? fetchedAt,
  }) {
    return OfflinePage<T>(
      data: pagination.data,
      total: pagination.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: pagination.totalPages,
      isComplete: pagination.page >= pagination.totalPages,
      source: DataSourceKind.remote,
      lastFetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  @override
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
