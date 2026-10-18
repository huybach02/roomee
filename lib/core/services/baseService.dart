// ignore_for_file: file_names

import 'package:dio/dio.dart';
import 'package:roomee/core/network/api_client.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/network/api_response.dart';

/// Lớp Service cơ sở cung cấp các phương thức gọi HTTP chuẩn hóa (GET, POST, PUT, PATCH, DELETE)
/// và các hàm CRUD nghiệp vụ mức cao (getDataAll, getDataById, getDataSelect, postData, postDataWithFile, putData, patchData, deleteData).
///
/// Các feature service hoặc RemoteDataSource sẽ kế thừa lớp này để tương tác với Backend API.
class BaseService {
  final ApiClient client;

  BaseService({ApiClient? client}) : client = client ?? ApiClient.instance;

  Dio get dio => client.dio;

  String _buildPathWithId(String endpoint, dynamic id) {
    if (id == null) return endpoint;
    final cleanEndpoint = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    return '$cleanEndpoint/$id';
  }

  /// Helper xử lý response đồng nhất
  ApiResponse<T> handleResponse<T>(
    Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(responseData, fromJsonT);
    }

    return ApiResponse<T>(
      success:
          (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300,
      message: response.statusMessage ?? '',
      data: responseData is T ? responseData : null,
    );
  }

  /// Wrapper bọc thực thi request và map DioException sang ApiException
  Future<ApiResponse<T>> safeRequest<T>(
    Future<Response> Function() request, {
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await request();
      return handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  // ==========================================
  // Core HTTP Methods
  // ==========================================

  /// GET request nguyên bản
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJsonT: fromJsonT,
    );
  }

  /// POST request nguyên bản
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJsonT: fromJsonT,
    );
  }

  /// PUT request nguyên bản
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJsonT: fromJsonT,
    );
  }

  /// PATCH request nguyên bản
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJsonT: fromJsonT,
    );
  }

  /// DELETE request nguyên bản
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJsonT: fromJsonT,
    );
  }

  // ==========================================
  // High-Level Standard CRUD Methods
  // ==========================================

  /// Lấy toàn bộ danh sách dữ liệu (hỗ trợ query params: phân trang, tìm kiếm, lọc)
  Future<ApiResponse<T>> getDataAll<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return get<T>(
      endpoint,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Lấy chi tiết một bản ghi theo ID (tự động nối endpoint/id)
  Future<ApiResponse<T>> getDataById<T>(
    String endpoint,
    dynamic id, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    final path = _buildPathWithId(endpoint, id);
    return get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Lấy danh sách rút gọn phục vụ hiển thị combobox, dropdown, thẻ chọn
  Future<ApiResponse<T>> getDataSelect<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return get<T>(
      endpoint,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Thêm mới bản ghi (POST)
  Future<ApiResponse<T>> postData<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Thêm mới bản ghi kèm tệp tin (Multipart / FormData upload với progress callback)
  Future<ApiResponse<T>> postDataWithFile<T>(
    String endpoint, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    return safeRequest<T>(
      () => dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      ),
      fromJsonT: fromJsonT,
    );
  }

  /// Cập nhật toàn bộ bản ghi (PUT) (có thể truyền id riêng hoặc gom sẵn trong endpoint)
  Future<ApiResponse<T>> putData<T>(
    String endpoint, {
    dynamic id,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    final path = _buildPathWithId(endpoint, id);
    return put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Cập nhật một phần bản ghi (PATCH) (có thể truyền id riêng hoặc gom sẵn trong endpoint)
  Future<ApiResponse<T>> patchData<T>(
    String endpoint, {
    dynamic id,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    final path = _buildPathWithId(endpoint, id);
    return patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }

  /// Xóa bản ghi (DELETE) (có thể truyền id riêng hoặc gom sẵn trong endpoint)
  Future<ApiResponse<T>> deleteData<T>(
    String endpoint, {
    dynamic id,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) {
    final path = _buildPathWithId(endpoint, id);
    return delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJsonT: fromJsonT,
    );
  }
}
