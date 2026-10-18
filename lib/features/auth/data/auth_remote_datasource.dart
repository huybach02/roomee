import 'package:roomee/core/network/network.dart';

class AuthRemoteDataSource extends BaseService {
  AuthRemoteDataSource({super.client});

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return postData<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return postData<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }
}
