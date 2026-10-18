import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_remote_datasource.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  group('AuthInterceptor', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test_token_123',
        'app_locale': 'en',
      });
    });

    test('injects Authorization Bearer and Accept-Language headers', () async {
      final dio = Dio();
      final interceptor = AuthInterceptor();
      dio.interceptors.add(interceptor);

      RequestOptions? capturedOptions;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'OK'},
              ),
            );
          },
        ),
      );

      await dio.get('https://example.com/test');

      expect(capturedOptions, isNotNull);
      expect(
        capturedOptions!.headers['Authorization'],
        'Bearer test_token_123',
      );
      expect(capturedOptions!.headers['Accept-Language'], 'en');
    });

    test('calls onUnauthorized callback when response status is 401', () async {
      bool unauthorizedCalled = false;
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        statusCode: 401,
        body: '{"success": false, "message": "Unauthorized"}',
      );
      dio.interceptors.add(
        AuthInterceptor(
          onUnauthorized: () {
            unauthorizedCalled = true;
          },
        ),
      );

      try {
        await dio.get('https://example.com/protected');
      } catch (_) {}

      expect(unauthorizedCalled, isTrue);
    });
  });

  group('BaseService', () {
    late Dio testDio;
    late ApiClient apiClient;
    late BaseService baseService;

    setUp(() {
      testDio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
      apiClient = ApiClient(dio: testDio);
      baseService = BaseService(client: apiClient);
    });

    test('get() returns successful ApiResponse', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Lấy dữ liệu thành công',
                  'data': {
                    'items': [1, 2, 3],
                  },
                },
              ),
            );
          },
        ),
      );

      final response = await baseService.get<Map<String, dynamic>>('/items');

      expect(response.success, isTrue);
      expect(response.message, 'Lấy dữ liệu thành công');
      expect(response.data?['items'], [1, 2, 3]);
    });

    test('post() maps DioException to ApiException properly', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'success': false, 'message': 'Email không hợp lệ'},
                ),
              ),
            );
          },
        ),
      );

      expect(
        () => baseService.post('/auth/login', data: {'email': 'invalid'}),
        throwsA(
          isA<ClientException>().having(
            (e) => e.message,
            'message',
            'Email không hợp lệ',
          ),
        ),
      );
    });

    test(
      'maps connectionError to NoInternetException (offline trigger)',
      () async {
        testDio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'No internet connection',
                ),
              );
            },
          ),
        );

        expect(
          () => baseService.get('/offline-test'),
          throwsA(isA<NoInternetException>()),
        );
      },
    );

    test('getDataAll() passes query parameters and returns list', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms');
            expect(options.queryParameters['page'], 1);
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'OK',
                  'data': [
                    {'id': 1, 'name': 'Phòng 101'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final result = await baseService.getDataAll<List<dynamic>>(
        '/rooms',
        queryParameters: {'page': 1},
      );

      expect(result.success, isTrue);
      expect((result.data as List).length, 1);
    });

    test('getDataById() appends id to endpoint properly', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms/101');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'OK',
                  'data': {'id': 101, 'name': 'Phòng 101'},
                },
              ),
            );
          },
        ),
      );

      final result = await baseService.getDataById<Map<String, dynamic>>(
        '/rooms',
        101,
      );

      expect(result.success, isTrue);
      expect(result.data?['id'], 101);
    });

    test('getDataSelect() calls select endpoint', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms/select');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'OK',
                  'data': [
                    {'value': 1, 'label': 'Phòng 101'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final result = await baseService.getDataSelect<List<dynamic>>(
        '/rooms/select',
      );

      expect(result.success, isTrue);
      expect((result.data as List).first['label'], 'Phòng 101');
    });

    test('postData() sends payload and returns response', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms');
            expect(options.data['name'], 'Phòng mới');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'message': 'Created',
                  'data': {'id': 201},
                },
              ),
            );
          },
        ),
      );

      final result = await baseService.postData<Map<String, dynamic>>(
        '/rooms',
        data: {'name': 'Phòng mới'},
      );

      expect(result.success, isTrue);
      expect(result.data?['id'], 201);
    });

    test('postDataWithFile() sends FormData', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/upload');
            expect(options.data, isA<FormData>());
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Uploaded',
                  'data': {'url': 'https://roomee.vn/img.png'},
                },
              ),
            );
          },
        ),
      );

      final formData = FormData.fromMap({'name': 'avatar'});
      final result = await baseService.postDataWithFile<Map<String, dynamic>>(
        '/upload',
        formData: formData,
      );

      expect(result.success, isTrue);
      expect(result.data?['url'], 'https://roomee.vn/img.png');
    });

    test('putData() appends id and sends update payload', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms/101');
            expect(options.data['price'], 2500000);
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'Updated'},
              ),
            );
          },
        ),
      );

      final result = await baseService.putData(
        '/rooms',
        id: 101,
        data: {'price': 2500000},
      );

      expect(result.success, isTrue);
    });

    test('patchData() appends id and updates partial payload', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms/101');
            expect(options.data['status'], 'available');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'Patched'},
              ),
            );
          },
        ),
      );

      final result = await baseService.patchData(
        '/rooms',
        id: 101,
        data: {'status': 'available'},
      );

      expect(result.success, isTrue);
    });

    test('deleteData() appends id and sends delete request', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/rooms/101');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'Deleted'},
              ),
            );
          },
        ),
      );

      final result = await baseService.deleteData('/rooms', id: 101);
      expect(result.success, isTrue);
    });
  });

  group('AuthRemoteDataSource', () {
    test('login sends email and password and returns response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/auth/login');
            expect(options.data['email'], 'test@roomee.vn');
            expect(options.data['password'], 'secret123');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Đăng nhập thành công',
                  'data': {'token': 'jwt_xyz'},
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(dio: dio);
      final remoteSource = AuthRemoteDataSource(client: client);

      final result = await remoteSource.login(
        const LoginRequest(email: 'test@roomee.vn', password: 'secret123'),
      );

      expect(result.success, isTrue);
      expect(result.data?.token, 'jwt_xyz');
    });

    test('register sends fullName, email and password', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/auth/register');
            expect(options.data['fullName'], 'admin');
            expect(options.data['email'], 'admin@roomee.vn');
            expect(options.data['phoneNumber'], '0901234567');
            expect(options.data['gender'], 'female');
            expect(options.data['role'], 'landlord');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Đăng ký thành công',
                  'data': {
                    'token': 'reg_token',
                    'user': {'id': 'uuid-1', 'email': 'admin@roomee.vn'},
                  },
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(dio: dio);
      final remoteSource = AuthRemoteDataSource(client: client);

      final result = await remoteSource.register(
        const RegisterRequest(
          fullName: 'admin',
          email: 'admin@roomee.vn',
          password: 'password123',
          phoneNumber: '0901234567',
          gender: Gender.female,
          role: UserRole.landlord,
        ),
      );

      expect(result.success, isTrue);
      expect(result.data?.token, 'reg_token');
      expect(result.data?.user?.id, 'uuid-1');
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _FakeAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
