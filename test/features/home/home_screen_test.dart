import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/core/screens/home_screen.dart';
import 'package:roomee/utils/constanst.dart';

class _FakeAuthRepo implements IAuthRepository {
  bool loggedOut = false;

  @override
  Future<AuthData> login(LoginRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<AuthData> register(RegisterRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel?> syncUserProfile() async => null;

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
  Future<void> logout() async {
    loggedOut = true;
  }

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
      'fake_token';

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

  testWidgets('HomeScreen renders user info and handles logout', (tester) async {
    final fakeRepo = _FakeAuthRepo();
    final authBloc = AuthBloc(authRepository: fakeRepo);
    final router = createAppRouter(initialLocation: AppRoutes.home);

    const testUser = UserModel(
      id: '123',
      email: 'landlord@roomee.vn',
      fullName: 'Trần Văn Chủ',
      role: UserRole.landlord,
    );

    // Seed authenticated state
    authBloc.emit(const Authenticated(user: testUser, token: 'fake_token'));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
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

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Xin chào, Trần Văn Chủ!'), findsOneWidget);
    expect(find.text('landlord@roomee.vn'), findsOneWidget);
    expect(find.text('LANDLORD'), findsOneWidget);

    // Tap logout button
    final logoutBtn = find.widgetWithText(AppButton, 'Đăng xuất');
    expect(logoutBtn, findsOneWidget);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.loggedOut, isTrue);

    authBloc.close();
  });
}
