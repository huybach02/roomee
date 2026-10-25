import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;

  AuthBloc({IAuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const AuthInitial()) {
    on<AuthCheckEvent>(_onAuthCheck);
    on<AuthLoginEvent>(_onAuthLogin);
    on<AuthRegisterEvent>(_onAuthRegister);
    on<AuthLogoutEvent>(_onAuthLogout);
    on<AuthVerifyOtpEvent>(_onAuthVerifyOtp);
    on<AuthResendOtpEvent>(_onAuthResendOtp);
    on<AuthForgotPasswordEvent>(_onAuthForgotPassword);
    on<AuthVerifyResetOtpEvent>(_onAuthVerifyResetOtp);
    on<AuthResetPasswordEvent>(_onAuthResetPassword);
  }

  Future<void> _onAuthCheck(
    AuthCheckEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        // 1. Stale-While-Revalidate: Đọc ngay cache cũ từ storage để UI hiển thị tức thì (0ms latency)
        final cachedUser = await _authRepository.getCurrentUser();
        final token = await _authRepository.getToken() ?? '';
        final refreshToken = await _authRepository.getRefreshToken();
        emit(
          Authenticated(
            user: cachedUser,
            token: token,
            refreshToken: refreshToken,
          ),
        );

        // 2. Làm tươi dữ liệu từ server (Revalidation qua GET /auth/me)
        try {
          final freshUser = await _authRepository.syncUserProfile();
          if (freshUser != null) {
            final latestToken = await _authRepository.getToken() ?? token;
            final latestRefreshToken =
                await _authRepository.getRefreshToken() ?? refreshToken;
            emit(
              Authenticated(
                user: freshUser,
                token: latestToken,
                refreshToken: latestRefreshToken,
              ),
            );
          }
        } on UnauthorizedException {
          emit(const Unauthenticated());
        } on ForbiddenException {
          emit(const Unauthenticated());
        } catch (_) {
          // Lỗi mạng hoặc server tạm thời: Giữ nguyên cachedUser để người dùng sử dụng tiếp (hỗ trợ offline)
        }
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authData = await _authRepository.login(event.request);
      if (authData.code == AuthOtpRequired.needVerifyEmail) {
        emit(
          AuthOtpRequired(
            destination: event.request.email,
            purpose: 'register',
            user: authData.user,
          ),
        );
      } else {
        emit(
          Authenticated(
            user: authData.user,
            token: authData.token,
            refreshToken: authData.refreshToken,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authData = await _authRepository.register(event.request);
      if (authData.code == AuthOtpRequired.needVerifyEmail) {
        emit(
          AuthOtpRequired(
            destination: event.request.email,
            purpose: 'register',
            user: authData.user,
          ),
        );
      } else {
        emit(const Unauthenticated());
      }
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
    } finally {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthVerifyOtp(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authData = await _authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      emit(
        Authenticated(
          user: authData.user,
          token: authData.token,
          refreshToken: authData.refreshToken,
        ),
      );
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthResendOtp(
    AuthResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resendOtp(event.email);
      emit(const AuthOtpSent());
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthForgotPassword(
    AuthForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.forgotPassword(event.email);
      emit(AuthForgotPasswordSent(email: event.email));
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthVerifyResetOtp(
    AuthVerifyResetOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final resetToken = await _authRepository.verifyResetOtp(
        email: event.email,
        otp: event.otp,
      );
      emit(AuthResetOtpVerified(email: event.email, resetToken: resetToken));
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onAuthResetPassword(
    AuthResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authData = await _authRepository.resetPassword(
        resetToken: event.resetToken,
        newPassword: event.newPassword,
      );
      emit(
        Authenticated(
          user: authData.user,
          token: authData.token,
          refreshToken: authData.refreshToken,
        ),
      );
    } on ApiException catch (e) {
      emit(
        AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
}
