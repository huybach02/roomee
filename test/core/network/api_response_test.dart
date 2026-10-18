import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/network/network.dart';

void main() {
  group('ApiResponse', () {
    test('parses success response correctly with json', () {
      final json = {
        'success': true,
        'message': 'Thành công',
        'data': {'id': '123', 'name': 'Roomee'},
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'Thành công');
      expect(response.data?['id'], '123');
      expect(response.data?['name'], 'Roomee');
      expect(response.errors, isNull);
    });

    test('parses error response correctly with errors payload', () {
      final json = {
        'success': false,
        'message': 'Dữ liệu không hợp lệ',
        'errors': [
          {'field': 'email', 'message': 'Email không hợp lệ'}
        ],
      };

      final response = ApiResponse<dynamic>.fromJson(json);

      expect(response.success, isFalse);
      expect(response.message, 'Dữ liệu không hợp lệ');
      expect(response.data, isNull);
      expect(response.errors, isList);
      expect((response.errors as List).first['field'], 'email');
    });

    test('parses custom entity with fromJsonT function', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': {'title': 'Phòng trọ A'},
      };

      final response = ApiResponse<String>.fromJson(
        json,
        (data) => (data as Map<String, dynamic>)['title'] as String,
      );

      expect(response.success, isTrue);
      expect(response.data, 'Phòng trọ A');
    });
  });

  group('ApiException.fromDioException', () {
    final dummyRequestOptions = RequestOptions(path: '/test');

    test('maps connectionError to NoInternetException', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet',
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception, isA<NoInternetException>());
    });

    test('maps connectionTimeout to TimeoutException', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception, isA<TimeoutException>());
    });

    test('maps 401 badResponse to UnauthorizedException with custom message', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: dummyRequestOptions,
          statusCode: 401,
          data: {
            'success': false,
            'message': 'Token không hợp lệ hoặc đã hết hạn',
          },
        ),
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception, isA<UnauthorizedException>());
      expect(exception.message, 'Token không hợp lệ hoặc đã hết hạn');
      expect(exception.statusCode, 401);
    });

    test('maps 400 badResponse to ClientException with errors', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: dummyRequestOptions,
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Dữ liệu đầu vào sai',
            'errors': {'email': 'Email đã tồn tại'},
          },
        ),
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception, isA<ClientException>());
      expect(exception.message, 'Dữ liệu đầu vào sai');
      expect(exception.statusCode, 400);
      expect(exception.errors, isMap);
    });

    test('maps 500 badResponse to ServerException', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: dummyRequestOptions,
          statusCode: 500,
          data: {'success': false, 'message': 'Internal Server Error'},
        ),
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception, isA<ServerException>());
      expect(exception.statusCode, 500);
    });
  });
}
