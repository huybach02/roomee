import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roomee/core/models/models.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'cached_user';

  AuthLocalDataSource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Lưu access token
  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  /// Lấy access token hiện tại
  Future<String?> getToken() async {
    return _storage.read(key: tokenKey);
  }

  /// Xóa access token
  Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
  }

  /// Lưu refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }

  /// Lấy refresh token hiện tại
  Future<String?> getRefreshToken() async {
    return _storage.read(key: refreshTokenKey);
  }

  /// Xóa refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: refreshTokenKey);
  }

  /// Lưu thông tin người dùng cục bộ (phục vụ hiển thị nhanh & offline mode)
  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: userKey, value: jsonStr);
  }

  /// Đọc thông tin người dùng từ bộ nhớ cục bộ
  Future<UserModel?> getUser() async {
    final jsonStr = await _storage.read(key: userKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Xóa thông tin người dùng cục bộ
  Future<void> deleteUser() async {
    await _storage.delete(key: userKey);
  }

  /// Kiểm tra trạng thái đã đăng nhập
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Xóa sạch phiên đăng nhập khi đăng xuất
  Future<void> clearSession() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteUser();
  }
}
