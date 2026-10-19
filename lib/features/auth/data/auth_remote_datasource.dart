import 'package:roomee/core/network/network.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';

class AuthRemoteDataSource extends BaseService {
  AuthRemoteDataSource({super.client});

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

  Future<ApiResponse<dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return postData<dynamic>(
      '/auth/verify-otp',
      data: {'email': email, 'otp': otp},
    );
  }
}
