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
}
