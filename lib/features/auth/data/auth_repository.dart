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

  Future<void> forgotPassword(String email);
  Future<String> verifyResetOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  Future<UserModel?> getCurrentUser();
  Future<UserModel?> syncUserProfile();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<RefreshTokenResponse> refreshToken();
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
    if (authData.refreshToken != null && authData.refreshToken!.isNotEmpty) {
      await _localDataSource.saveRefreshToken(authData.refreshToken!);
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
    if (authData.refreshToken != null && authData.refreshToken!.isNotEmpty) {
      await _localDataSource.saveRefreshToken(authData.refreshToken!);
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
  Future<void> forgotPassword(String email) async {
    await _remoteDataSource.forgotPassword(email);
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _remoteDataSource.verifyResetOtp(
      email: email,
      otp: otp,
    );
    final token = response.data?.resetToken;
    if (token == null || token.isEmpty) {
      throw const ServerException(message: 'Mã xác thực không hợp lệ');
    }
    return token;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _remoteDataSource.resetPassword(
      token: resetToken,
      newPassword: newPassword,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Đọc thông tin user đã được cache từ local storage (hỗ trợ offline mode)
    return _localDataSource.getUser();
  }

  @override
  Future<UserModel?> syncUserProfile() async {
    final response = await _remoteDataSource.getMe();
    final freshUser = response.data;
    if (freshUser != null) {
      await _localDataSource.saveUser(freshUser);
    }
    return freshUser;
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
  Future<String?> getRefreshToken() async {
    return _localDataSource.getRefreshToken();
  }

  @override
  Future<RefreshTokenResponse> refreshToken() async {
    final currentRefreshToken = await _localDataSource.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw const UnauthorizedException(message: 'Phiên đăng nhập đã hết hạn.');
    }

    final response = await _remoteDataSource.refreshToken(currentRefreshToken);
    final data = response.data;
    if (data == null) {
      throw const ServerException(message: 'Phản hồi không hợp lệ từ máy chủ.');
    }

    await _localDataSource.saveToken(data.accessToken);
    await _localDataSource.saveRefreshToken(data.refreshToken);

    return data;
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Bỏ qua lỗi mạng (ví dụ khi thiết bị offline) để luôn đảm bảo xóa session cục bộ
    } finally {
      await _localDataSource.clearSession();
    }
  }
}
