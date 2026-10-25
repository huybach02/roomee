class PaginationModel<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasReachedMax => page >= totalPages;

  factory PaginationModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic itemJson) fromJsonT,
  ) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    return PaginationModel<T>(
      data: rawList.map((item) => fromJsonT(item)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson([dynamic Function(T item)? toJsonT]) {
    return {
      'data': data.map((item) => toJsonT != null ? toJsonT(item) : item).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }

  PaginationModel<T> copyWith({
    List<T>? data,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return PaginationModel<T>(
      data: data ?? this.data,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
