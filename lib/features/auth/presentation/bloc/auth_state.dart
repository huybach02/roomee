part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthOtpRequired extends AuthState {
  final String destination;
  final String purpose;
  final UserModel? user;

  const AuthOtpRequired({
    required this.destination,
    required this.purpose,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthOtpRequired &&
          runtimeType == other.runtimeType &&
          destination == other.destination &&
          purpose == other.purpose &&
          user == other.user;

  @override
  int get hashCode => Object.hash(destination, purpose, user);

  static String get needVerifyEmail => 'NEED_VERIFY_EMAIL';
}

final class Authenticated extends AuthState {
  final UserModel? user;
  final String token;

  const Authenticated({this.user, required this.token});

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

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthFailure extends AuthState {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const AuthFailure({required this.message, this.statusCode, this.errors});

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

final class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

final class AuthOtpSent extends AuthState {
  const AuthOtpSent();
}

final class AuthForgotPasswordSent extends AuthState {
  final String email;

  const AuthForgotPasswordSent({required this.email});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthForgotPasswordSent &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}

final class AuthResetOtpVerified extends AuthState {
  final String email;
  final String resetToken;

  const AuthResetOtpVerified({required this.email, required this.resetToken});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResetOtpVerified &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          resetToken == other.resetToken;

  @override
  int get hashCode => Object.hash(email, resetToken);
}

final class AuthResetPasswordSuccess extends AuthState {
  const AuthResetPasswordSuccess();
}
