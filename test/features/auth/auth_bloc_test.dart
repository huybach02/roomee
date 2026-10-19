import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';

class _FakeAuthRepository implements IAuthRepository {
  bool loggedIn = false;
  UserModel? currentUser;
  String? token;
  ApiException? errorToThrow;

  @override
  Future<AuthData> login(LoginRequest request) async {
    if (errorToThrow != null) throw errorToThrow!;
    loggedIn = true;
    token = 'login_token_123';
    currentUser = UserModel(id: '1', email: request.email);
    return AuthData(user: currentUser, token: token!, code: null);
  }

  @override
  Future<AuthData> register(RegisterRequest request) async {
    if (errorToThrow != null) throw errorToThrow!;
    loggedIn = true;
    token = 'reg_token_456';
    currentUser = UserModel(
      id: '2',
      email: request.email,
      fullName: request.fullName,
    );
    return AuthData(
      user: currentUser,
      token: token!,
      code: 'NEED_VERIFY_EMAIL',
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<bool> isLoggedIn() async {
    return loggedIn;
  }

  @override
  Future<String?> getToken() async {
    return token;
  }

  @override
  Future<void> logout() async {
    loggedIn = false;
    currentUser = null;
    token = null;
  }

  String? lastResentEmail;
  String? lastVerifiedEmail;
  String? lastVerifiedOtp;

  @override
  Future<void> resendOtp(String email) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastResentEmail = email;
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastVerifiedEmail = email;
    lastVerifiedOtp = otp;
  }
}

void main() {
  late _FakeAuthRepository fakeRepo;
  late AuthBloc authBloc;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeRepo);
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  group('AuthCheckEvent', () {
    test('emits [Unauthenticated] when not logged in', () async {
      expectLater(authBloc.stream, emitsInOrder([const Unauthenticated()]));

      authBloc.add(const AuthCheckEvent());
    });

    test('emits [Authenticated] when logged in', () async {
      fakeRepo.loggedIn = true;
      fakeRepo.currentUser = const UserModel(id: '10', email: 'test@roomee.vn');
      fakeRepo.token = 'existing_token';

      expectLater(
        authBloc.stream,
        emitsInOrder([
          const Authenticated(
            user: UserModel(id: '10', email: 'test@roomee.vn'),
            token: 'existing_token',
          ),
        ]),
      );

      authBloc.add(const AuthCheckEvent());
    });
  });

  group('AuthLoginEvent', () {
    test('emits [AuthLoading, Authenticated] on successful login', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const Authenticated(
            user: UserModel(id: '1', email: 'user@roomee.vn'),
            token: 'login_token_123',
          ),
        ]),
      );

      authBloc.add(
        const AuthLoginEvent(
          LoginRequest(email: 'user@roomee.vn', password: 'password123'),
        ),
      );
    });

    test('emits [AuthLoading, AuthFailure] on login error', () async {
      fakeRepo.errorToThrow = const ClientException(
        message: 'Email hoặc mật khẩu không chính xác',
        statusCode: 400,
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            message: 'Email hoặc mật khẩu không chính xác',
            statusCode: 400,
          ),
        ]),
      );

      authBloc.add(
        const AuthLoginEvent(
          LoginRequest(email: 'user@roomee.vn', password: 'wrong_password'),
        ),
      );
    });
  });

  group('AuthRegisterEvent', () {
    test(
      'emits [AuthLoading, AuthOtpRequired] on successful registration',
      () async {
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthOtpRequired(
              destination: 'new@roomee.vn',
              purpose: 'register',
              user: UserModel(
                id: '2',
                email: 'new@roomee.vn',
                fullName: 'New User',
              ),
            ),
          ]),
        );

        authBloc.add(
          const AuthRegisterEvent(
            RegisterRequest(
              fullName: 'New User',
              email: 'new@roomee.vn',
              password: 'password123',
            ),
          ),
        );
      },
    );

    test('emits [AuthLoading, AuthFailure] on registration error', () async {
      fakeRepo.errorToThrow = const ClientException(
        message: 'Email đã tồn tại trong hệ thống',
        statusCode: 400,
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            message: 'Email đã tồn tại trong hệ thống',
            statusCode: 400,
          ),
        ]),
      );

      authBloc.add(
        const AuthRegisterEvent(
          RegisterRequest(
            fullName: 'Test',
            email: 'existing@roomee.vn',
            password: 'password123',
          ),
        ),
      );
    });
  });

  group('AuthLogoutEvent', () {
    test('emits [AuthLoading, Unauthenticated] on logout', () async {
      fakeRepo.loggedIn = true;
      fakeRepo.token = 'token_to_logout';

      expectLater(
        authBloc.stream,
        emitsInOrder([const AuthLoading(), const Unauthenticated()]),
      );

      authBloc.add(const AuthLogoutEvent());
    });
  });

  group('AuthOtpRequired equality', () {
    test('compares correctly based on destination, purpose, and user', () {
      const otpState1 = AuthOtpRequired(
        destination: 'test@roomee.vn',
        purpose: 'register',
      );
      const otpState2 = AuthOtpRequired(
        destination: 'test@roomee.vn',
        purpose: 'register',
      );
      const otpState3 = AuthOtpRequired(
        destination: 'other@roomee.vn',
        purpose: 'register',
      );

      expect(otpState1, equals(otpState2));
      expect(otpState1 == otpState3, isFalse);
    });
  });

  group('AuthVerifyOtpEvent', () {
    test('emits [AuthLoading, AuthOtpVerified] on successful verification', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([const AuthLoading(), const AuthOtpVerified()]),
      );

      authBloc.add(
        const AuthVerifyOtpEvent(email: 'test@roomee.vn', otp: '123456'),
      );
    });

    test('emits [AuthLoading, AuthFailure] on verification error', () async {
      fakeRepo.errorToThrow = const ClientException(
        message: 'Mã xác thực không hợp lệ',
        statusCode: 400,
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            message: 'Mã xác thực không hợp lệ',
            statusCode: 400,
          ),
        ]),
      );

      authBloc.add(
        const AuthVerifyOtpEvent(email: 'test@roomee.vn', otp: '000000'),
      );
    });
  });

  group('AuthResendOtpEvent', () {
    test('emits [AuthLoading, AuthOtpSent] on successful resend', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([const AuthLoading(), const AuthOtpSent()]),
      );

      authBloc.add(const AuthResendOtpEvent('test@roomee.vn'));
    });

    test('emits [AuthLoading, AuthFailure] on resend error', () async {
      fakeRepo.errorToThrow = const ServerException(
        message: 'Không thể gửi email OTP',
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            message: 'Không thể gửi email OTP',
            statusCode: 500,
          ),
        ]),
      );

      authBloc.add(const AuthResendOtpEvent('test@roomee.vn'));
    });
  });
}
