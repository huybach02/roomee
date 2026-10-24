import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';

class AuthRemoteDataSource extends BaseService {
  AuthRemoteDataSource({super.client});

  Future<ApiResponse<UserModel>> getMe() {
    return get<UserModel>(
      '/auth/me',
      fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthData>> login(LoginRequest request) {
    return postData<AuthData>(
      '/auth/login',
      data: request.toJson(),
      fromJsonT: (json) => AuthData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthData>> register(RegisterRequest request) {
    return postData<AuthData>(
      '/auth/register',
      data: request.toJson(),
      fromJsonT: (json) => AuthData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> resendOtp(String email) {
    return postData<dynamic>(
      '/auth/resend-otp',
      data: {'email': email},
    );
  }

  Future<ApiResponse<AuthData>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return postData<AuthData>(
      '/auth/verify-otp',
      data: {'email': email, 'otp': otp},
      fromJsonT: (json) => AuthData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> forgotPassword(String email) {
    return postData<dynamic>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<ApiResponse<VerifyResetOtpResponse>> verifyResetOtp({
    required String email,
    required String otp,
  }) {
    return postData<VerifyResetOtpResponse>(
      '/auth/verify-reset-otp',
      data: {'email': email, 'otp': otp},
      fromJsonT: (json) =>
          VerifyResetOtpResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AuthData>> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return postData<AuthData>(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
      fromJsonT: (json) => AuthData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> logout() {
    return postData<dynamic>('/auth/logout');
  }

  Future<ApiResponse<RefreshTokenResponse>> refreshToken(String refreshToken) {
    return postData<RefreshTokenResponse>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
      fromJsonT: (json) =>
          RefreshTokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
