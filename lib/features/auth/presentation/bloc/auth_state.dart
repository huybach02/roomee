part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

/// Trạng thái khởi tạo ban đầu
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Trạng thái đang tải / xử lý
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Trạng thái đã xác thực / đăng nhập thành công
final class Authenticated extends AuthState {
  final UserModel? user;
  final String token;

  const Authenticated({
    this.user,
    required this.token,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          token == other.token;

  @override
  int get hashCode => Object.hash(user, token);
}

/// Trạng thái chưa xác thực (chưa đăng nhập hoặc đã đăng xuất)
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Trạng thái lỗi khi thực hiện tác vụ auth
final class AuthFailure extends AuthState {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const AuthFailure({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(message, statusCode);
}
