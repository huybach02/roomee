import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_local_datasource.dart';
import 'package:roomee/features/auth/data/auth_remote_datasource.dart';

abstract class IAuthRepository {
  Future<AuthData> login(LoginRequest request);

  Future<AuthData> register(RegisterRequest request);

  Future<void> resendOtp(String email);
  Future<void> verifyOtp({required String email, required String otp});

  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<void> logout();
}

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
        _localDataSource = localDataSource ?? AuthLocalDataSource();

  @override
  Future<AuthData> login(LoginRequest request) async {
    final response = await _remoteDataSource.login(request);

    final authData = response.data;
    if (authData == null) {
      throw const ServerException(message: 'Phản hồi không hợp lệ từ máy chủ.');
    }

    if (authData.token.isNotEmpty) {
      await _localDataSource.saveToken(authData.token);
    }
    if (authData.user != null) {
      await _localDataSource.saveUser(authData.user!);
    }

    return authData;
  }

  @override
  Future<AuthData> register(RegisterRequest request) async {
    final response = await _remoteDataSource.register(request);

    final authData = response.data;
    if (authData == null) {
      throw const ServerException(message: 'Phản hồi không hợp lệ từ máy chủ.');
    }

    if (authData.token.isNotEmpty) {
      await _localDataSource.saveToken(authData.token);
    }
    if (authData.user != null) {
      await _localDataSource.saveUser(authData.user!);
    }

    return authData;
  }

  @override
  Future<void> resendOtp(String email) async {
    await _remoteDataSource.resendOtp(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    await _remoteDataSource.verifyOtp(email: email, otp: otp);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Đọc thông tin user đã được cache từ local storage (hỗ trợ offline mode)
    return _localDataSource.getUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _localDataSource.isLoggedIn();
  }

  @override
  Future<String?> getToken() async {
    return _localDataSource.getToken();
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearSession();
  }
}
