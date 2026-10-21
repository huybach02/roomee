import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:roomee/features/auth/presentation/screens/reset_password_screen.dart';

class _FakeAuthRepo implements IAuthRepository {
  String? forgotPasswordEmail;
  String? resetPasswordToken;
  String? resetPasswordNewPassword;

  @override
  Future<AuthData> login(LoginRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<AuthData> register(RegisterRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<RefreshTokenResponse> refreshToken() async =>
      const RefreshTokenResponse(
        accessToken: 'new_token',
        refreshToken: 'new_refresh',
      );

  @override
  Future<void> logout() async {}

  @override
  Future<void> resendOtp(String email) async {}

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {}

  @override
  Future<void> forgotPassword(String email) async {
    forgotPasswordEmail = email;
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async =>
      'mock_reset_token';

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    resetPasswordToken = resetToken;
    resetPasswordNewPassword = newPassword;
  }
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppLocalizations.preload();
  });

  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  group('ForgotPasswordScreen', () {
    testWidgets('renders fields and submits forgot password event', (
      tester,
    ) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = createAppRouter(initialLocation: AppRoutes.forgotPassword);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            locale: const Locale('vi'),
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Quên mật khẩu'), findsOneWidget);

      // Enter invalid email -> validator fails
      final emailField = find.byType(AppTextField);
      await tester.enterText(emailField, 'invalid_email');
      await tester.pumpAndSettle();

      final sendBtn = find.widgetWithText(AppButton, 'Gửi mã xác thực');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.forgotPasswordEmail, isNull);

      // Enter valid email -> succeeds and triggers repo
      await tester.enterText(emailField, 'test@roomee.vn');
      await tester.pumpAndSettle();
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.forgotPasswordEmail, 'test@roomee.vn');

      authBloc.close();
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('renders password inputs and submits reset password event', (
      tester,
    ) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);
      final router = GoRouter(
        initialLocation: '/test-reset',
        routes: [
          GoRoute(
            path: '/test-reset',
            builder: (context, state) =>
                const ResetPasswordScreen(resetToken: 'valid_token_123'),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) =>
                const Scaffold(body: Text('Login Screen Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            locale: const Locale('vi'),
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);

      final textFields = find.byType(AppTextField);
      expect(textFields, findsNWidgets(2));

      // Enter mismatched passwords
      await tester.enterText(textFields.at(0), 'password123');
      await tester.enterText(textFields.at(1), 'mismatched123');
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(AppButton, 'Lưu mật khẩu mới');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.resetPasswordNewPassword, isNull);

      // Enter matching valid password
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.resetPasswordToken, 'valid_token_123');
      expect(fakeRepo.resetPasswordNewPassword, 'password123');

      authBloc.close();
    });
  });
}
