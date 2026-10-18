class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    final rawData = json['data'];
    T? parsedData;

    if (rawData != null) {
      if (fromJsonT != null) {
        parsedData = fromJsonT(rawData);
      } else if (rawData is T) {
        parsedData = rawData;
      }
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: parsedData,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson([dynamic Function(T? data)? toJsonT]) {
    return {
      'success': success,
      'message': message,
      if (data != null)
        'data': toJsonT != null ? toJsonT(data) : data,
      if (errors != null) 'errors': errors,
    };
  }
}
