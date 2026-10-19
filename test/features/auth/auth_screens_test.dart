import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/auth/presentation/screens/login_screen.dart';
import 'package:roomee/features/auth/presentation/screens/otp_screen.dart';

class _FakeAuthRepo implements IAuthRepository {
  @override
  Future<AuthData> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const AuthData(token: 'fake_tok', code: null);
  }

  @override
  Future<AuthData> register(RegisterRequest request) async {
    return const AuthData(token: 'fake_tok', code: null);
  }

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<void> resendOtp(String email) async {}

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {}
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

  testWidgets('LoginScreen shows loading on AppButton when AuthLoading', (
    WidgetTester tester,
  ) async {
    final bloc = AuthBloc(authRepository: _FakeAuthRepo());

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill valid credentials
    final textFields = find.byType(AppTextField);
    await tester.enterText(textFields.first, 'user@roomee.vn');
    await tester.enterText(textFields.last, 'password123');
    await tester.pumpAndSettle();

    final loginBtn = find.widgetWithText(AppButton, 'Đăng nhập');
    await tester.tap(loginBtn);
    await tester.pump();

    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    bloc.close();
  });

  testWidgets('OtpScreen renders UI elements and handles OTP submission properly', (
    WidgetTester tester,
  ) async {
    String? verifiedOtp;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OtpScreen(
          destination: 'test@roomee.vn',
          onVerify: (otp) async {
            verifiedOtp = otp;
          },
        ),
      ),
    );
    await tester.pump();

    // Verify title and destination subtitle
    expect(find.text('Xác thực mã OTP'), findsOneWidget);
    expect(find.textContaining('test@roomee.vn'), findsOneWidget);

    // Verify 6 OTP input TextFields
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(6));

    // Tap verify without entering OTP -> Error shown
    final verifyBtn = find.widgetWithText(AppButton, 'Xác nhận');
    await tester.tap(verifyBtn);
    await tester.pump();
    expect(find.text('Vui lòng nhập đủ 6 chữ số mã OTP'), findsOneWidget);

    // Enter 6 digits
    for (int i = 0; i < 6; i++) {
      await tester.enterText(textFields.at(i), '${i + 1}');
      await tester.pump();
    }

    // Tap verify button with valid OTP
    await tester.tap(verifyBtn);
    await tester.pump();

    expect(verifiedOtp, '123456');
    expect(find.text('Vui lòng nhập đủ 6 chữ số mã OTP'), findsNothing);
  });

  testWidgets('OtpScreen handles resend countdown and resend trigger', (
    WidgetTester tester,
  ) async {
    bool resendCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OtpScreen(
          destination: 'test@roomee.vn',
          onResend: () async {
            resendCalled = true;
          },
        ),
      ),
    );
    await tester.pump();

    // Initial countdown is active (60s)
    expect(find.textContaining('Gửi lại mã sau'), findsOneWidget);
    expect(find.text('Gửi lại mã'), findsNothing);

    // Fast-forward 60 seconds
    await tester.pump(const Duration(seconds: 61));

    // Resend button should now appear
    final resendBtn = find.text('Gửi lại mã');
    expect(resendBtn, findsOneWidget);

    // Tap resend
    await tester.tap(resendBtn);
    await tester.pump();

    expect(resendCalled, isTrue);
    expect(find.text('Mã xác thực mới đã được gửi thành công'), findsOneWidget);
  });
}
