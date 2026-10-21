import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/auth/presentation/screens/otp_screen.dart';
import 'package:roomee/features/auth/presentation/screens/register_screen.dart';
import 'package:roomee/features/general/data/general_repository.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/core/screens/home_screen.dart';
import 'package:roomee/utils/constanst.dart';

class _FakeGeneralRepo implements IGeneralRepository {
  @override
  Future<List<ProvinceModel>> getProvinces() async => const [
        ProvinceModel(id: 1, code: 79, fullName: 'TP HCM', codeName: 'hcm'),
      ];

  @override
  Future<List<WardModel>> getWardsByProvince(int provinceId) async => const [
        WardModel(
          id: 10,
          code: 1,
          provinceId: 1,
          fullName: 'Phường 1',
          codeName: 'p1',
        ),
      ];
}

class _FakeAuthRepo implements IAuthRepository {
  @override
  Future<AuthData> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const AuthData(
      token: 'fake_tok',
      user: UserModel(
        id: '1',
        email: 'user@roomee.vn',
        role: UserRole.tenant,
        hasContract: false,
      ),
      code: null,
    );
  }

  @override
  Future<AuthData> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const AuthData(token: 'fake_tok', code: null);
  }

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
        accessToken: 'fake_tok',
        refreshToken: 'fake_refresh_tok',
      );

  @override
  Future<void> logout() async {}

  @override
  Future<void> resendOtp(String email) async {}

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async =>
      'fake_reset_token';

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {}
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

  testWidgets(
    'LoginScreen shows LoadingOverlay and LoadingScreen when AuthLoading and navigates to HomeScreen',
    (WidgetTester tester) async {
      final bloc = AuthBloc(authRepository: _FakeAuthRepo());
      final router = createAppRouter(initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: bloc),
            BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
          ],
          child: MaterialApp.router(
            locale: const Locale('vi'),
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
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

      // Verify loading overlay and indicator is shown
      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Verify navigated to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);

      bloc.close();
    },
  );

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

  testWidgets(
    'RegisterScreen shows LoadingOverlay and LoadingScreen when AuthLoading',
    (WidgetTester tester) async {
      final authBloc = AuthBloc(authRepository: _FakeAuthRepo());
      final generalBloc = GeneralBloc(repository: _FakeGeneralRepo());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<GeneralBloc>.value(value: generalBloc),
          ],
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ban đầu không loading
      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.byType(LoadingScreen), findsNothing);

      // Kích hoạt event đăng ký để bloc emit AuthLoading
      authBloc.add(
        const AuthRegisterEvent(
          RegisterRequest(
            fullName: 'Nguyen Van A',
            email: 'test@roomee.vn',
            password: 'password123',
            phoneNumber: '0901234567',
            gender: Gender.male,
            role: UserRole.tenant,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));

      // Verify LoadingScreen overlay xuất hiện đè lên giao diện
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('Đang xử lý...'), findsOneWidget);

      await tester.pumpAndSettle();
      authBloc.close();
      generalBloc.close();
    },
  );
}
