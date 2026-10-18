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

class _FakeAuthRepo implements IAuthRepository {
  @override
  Future<AuthData> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const AuthData(token: 'fake_tok');
  }

  @override
  Future<AuthData> register(RegisterRequest request) async {
    return const AuthData(token: 'fake_tok');
  }

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> logout() async {}
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
}
