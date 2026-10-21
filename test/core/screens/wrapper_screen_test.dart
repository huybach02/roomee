import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/home_screen.dart';
import 'package:roomee/core/screens/landlord_screen.dart';
import 'package:roomee/core/screens/tenant_screen.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class _FakeAuthRepo implements IAuthRepository {
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
  Future<void> forgotPassword(String email) async {}

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async =>
      'token';

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

  Widget buildTestableWidget({
    required AuthBloc authBloc,
    required String initialLocation,
  }) {
    final router = createAppRouter(initialLocation: initialLocation);
    return MultiBlocProvider(
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
    );
  }

  group('WrapperScreen Redirection', () {
    testWidgets('redirects tenant with hasContract == false to HomeScreen', (
      tester,
    ) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      authBloc.emit(
        const Authenticated(
          user: UserModel(
            id: '1',
            email: 'tenant_no_contract@roomee.vn',
            role: UserRole.tenant,
            hasContract: false,
          ),
          token: 'token',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          authBloc: authBloc,
          initialLocation: AppRoutes.wrapper,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Khám phá phòng trọ & tin đăng cho thuê'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('redirects tenant with hasContract == true to TenantScreen', (
      tester,
    ) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      authBloc.emit(
        const Authenticated(
          user: UserModel(
            id: '2',
            email: 'tenant_with_contract@roomee.vn',
            role: UserRole.tenant,
            hasContract: true,
          ),
          token: 'token',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          authBloc: authBloc,
          initialLocation: AppRoutes.wrapper,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TenantScreen), findsOneWidget);
      expect(find.text('Quản lý phòng thuê'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('redirects landlord to LandlordScreen', (tester) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      authBloc.emit(
        const Authenticated(
          user: UserModel(
            id: '3',
            email: 'landlord@roomee.vn',
            role: UserRole.landlord,
          ),
          token: 'token',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          authBloc: authBloc,
          initialLocation: AppRoutes.wrapper,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LandlordScreen), findsOneWidget);
      expect(find.text('Quản lý nhà trọ'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('redirects staff to LandlordScreen', (tester) async {
      final fakeRepo = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      authBloc.emit(
        const Authenticated(
          user: UserModel(
            id: '4',
            email: 'staff@roomee.vn',
            role: UserRole.staff,
          ),
          token: 'token',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          authBloc: authBloc,
          initialLocation: AppRoutes.wrapper,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LandlordScreen), findsOneWidget);

      authBloc.close();
    });
  });
}
