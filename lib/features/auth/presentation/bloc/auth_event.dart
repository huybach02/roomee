part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {
  const AuthEvent();
}

/// Kiểm tra trạng thái phiên đăng nhập khi khởi động app
final class AuthCheckEvent extends AuthEvent {
  const AuthCheckEvent();
}

/// Yêu cầu đăng nhập
final class AuthLoginEvent extends AuthEvent {
  final LoginRequest request;

  const AuthLoginEvent(this.request);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLoginEvent &&
          runtimeType == other.runtimeType &&
          request == other.request;

  @override
  int get hashCode => request.hashCode;
}

/// Yêu cầu đăng ký tài khoản mới
final class AuthRegisterEvent extends AuthEvent {
  final RegisterRequest request;

  const AuthRegisterEvent(this.request);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthRegisterEvent &&
          runtimeType == other.runtimeType &&
          request == other.request;

  @override
  int get hashCode => request.hashCode;
}

/// Yêu cầu đăng xuất tài khoản
final class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}
