import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_local_datasource.dart';
import 'package:roomee/features/auth/data/auth_remote_datasource.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthDto', () {
    test('UserModel fromJson and toJson work correctly', () {
      final json = {
        'id': 'usr_1',
        'email': 'tenant@roomee.vn',
        'fullName': 'Nguyễn Văn A',
        'phoneNumber': '0901234567',
        'avatarUrl': 'https://roomee.vn/avatar.png',
        'bio': 'Người thuê trọ',
        'gender': 'male',
        'role': 'tenant',
        'isActive': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr_1');
      expect(user.email, 'tenant@roomee.vn');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.gender, Gender.male);
      expect(user.role, UserRole.tenant);
      expect(user.isActive, isTrue);

      final outputJson = user.toJson();
      expect(outputJson['email'], 'tenant@roomee.vn');
      expect(outputJson['role'], 'tenant');
    });

    test('AuthData fromJson parses user and token', () {
      final json = {
        'user': {
          'id': 'usr_2',
          'email': 'landlord@roomee.vn',
          'role': 'landlord',
        },
        'token': 'jwt_token_123',
      };

      final authData = AuthData.fromJson(json);
      expect(authData.token, 'jwt_token_123');
      expect(authData.user, isNotNull);
      expect(authData.user?.role, UserRole.landlord);
    });
  });

  group('AuthLocalDataSource', () {
    late AuthLocalDataSource localDataSource;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      localDataSource = AuthLocalDataSource();
    });

    test('saves, reads, and deletes token', () async {
      expect(await localDataSource.getToken(), isNull);
      expect(await localDataSource.isLoggedIn(), isFalse);

      await localDataSource.saveToken('token_abc');
      expect(await localDataSource.getToken(), 'token_abc');
      expect(await localDataSource.isLoggedIn(), isTrue);

      await localDataSource.deleteToken();
      expect(await localDataSource.getToken(), isNull);
      expect(await localDataSource.isLoggedIn(), isFalse);
    });

    test('saves, reads, and deletes refresh token', () async {
      expect(await localDataSource.getRefreshToken(), isNull);

      await localDataSource.saveRefreshToken('refresh_abc');
      expect(await localDataSource.getRefreshToken(), 'refresh_abc');

      await localDataSource.deleteRefreshToken();
      expect(await localDataSource.getRefreshToken(), isNull);
    });

    test('saves, reads, and clears user profile', () async {
      const user = UserModel(
        id: 'usr_1',
        email: 'test@roomee.vn',
        fullName: 'Nguyễn Văn A',
      );

      await localDataSource.saveUser(user);
      final cachedUser = await localDataSource.getUser();

      expect(cachedUser, isNotNull);
      expect(cachedUser?.id, 'usr_1');
      expect(cachedUser?.fullName, 'Nguyễn Văn A');

      await localDataSource.clearSession();
      expect(await localDataSource.getUser(), isNull);
    });
  });

  group('AuthRepository', () {
    late Dio testDio;
    late AuthRemoteDataSource remoteDataSource;
    late AuthLocalDataSource localDataSource;
    late AuthRepository repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      testDio = Dio();
      final client = ApiClient(dio: testDio);
      remoteDataSource = AuthRemoteDataSource(client: client);
      localDataSource = AuthLocalDataSource();
      repository = AuthRepository(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    test('login persists token and user and returns AuthData', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Đăng nhập thành công',
                  'data': {
                    'token': 'secret_jwt_token',
                    'user': {
                      'id': 'usr_100',
                      'email': 'tenant@roomee.vn',
                      'fullName': 'Trần Văn B',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final authData = await repository.login(
        const LoginRequest(
          email: 'tenant@roomee.vn',
          password: 'password123',
        ),
      );

      expect(authData.token, 'secret_jwt_token');
      expect(authData.user?.fullName, 'Trần Văn B');

      // Verify persisted in local data source
      expect(await localDataSource.getToken(), 'secret_jwt_token');
      final savedUser = await repository.getCurrentUser();
      expect(savedUser?.id, 'usr_100');
      expect(await repository.isLoggedIn(), isTrue);
    });

    test('register persists token and user and returns AuthData', () async {
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'message': 'Đăng ký thành công',
                  'data': {
                    'token': 'reg_token_456',
                    'user': {
                      'id': 'usr_200',
                      'email': 'new@roomee.vn',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final authData = await repository.register(
        const RegisterRequest(
          fullName: 'newuser',
          email: 'new@roomee.vn',
          password: 'password123',
        ),
      );

      expect(authData.token, 'reg_token_456');
      expect(await repository.getToken(), 'reg_token_456');
    });

    test('logout clears local storage session', () async {
      await localDataSource.saveToken('token_to_clear');
      await localDataSource.saveUser(
        const UserModel(id: '1', email: 'test@roomee.vn'),
      );

      expect(await repository.isLoggedIn(), isTrue);

      await repository.logout();

      expect(await repository.isLoggedIn(), isFalse);
      expect(await repository.getCurrentUser(), isNull);
    });

    test('resendOtp sends post request to /auth/resend-otp', () async {
      String? requestedPath;
      Map<String, dynamic>? requestedData;

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            requestedData = options.data as Map<String, dynamic>?;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Thành công',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

      await repository.resendOtp('test@roomee.vn');

      expect(requestedPath, '/auth/resend-otp');
      expect(requestedData, {'email': 'test@roomee.vn'});
    });

    test('verifyOtp sends post request to /auth/verify-otp', () async {
      String? requestedPath;
      Map<String, dynamic>? requestedData;

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            requestedData = options.data as Map<String, dynamic>?;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Thành công',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

      await repository.verifyOtp(email: 'test@roomee.vn', otp: '123456');

      expect(requestedPath, '/auth/verify-otp');
      expect(requestedData, {'email': 'test@roomee.vn', 'otp': '123456'});
    });

    test('refreshToken calls /auth/refresh-token and updates tokens', () async {
      await localDataSource.saveRefreshToken('old_refresh_123');

      String? requestedPath;
      Map<String, dynamic>? requestedData;

      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            requestedData = options.data as Map<String, dynamic>?;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Thành công',
                  'data': {
                    'accessToken': 'new_access_token',
                    'refreshToken': 'new_refresh_token',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await repository.refreshToken();

      expect(requestedPath, '/auth/refresh-token');
      expect(requestedData, {'refreshToken': 'old_refresh_123'});
      expect(result.accessToken, 'new_access_token');
      expect(result.refreshToken, 'new_refresh_token');
      expect(await repository.getToken(), 'new_access_token');
      expect(await repository.getRefreshToken(), 'new_refresh_token');
    });
  });
}
