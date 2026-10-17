import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/screens/welcome_screen.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/main.dart';

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

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that MyApp builds successfully.
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('WelcomeScreen displays logo and action buttons',
      (WidgetTester tester) async {
    bool registerPressed = false;
    bool loginPressed = false;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: WelcomeScreen(
                onRegisterPressed: () => registerPressed = true,
                onLoginPressed: () => loginPressed = true,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final imageWidget = tester.widget<Image>(imageFinder);
    expect(
      (imageWidget.image as AssetImage).assetName,
      'assets/images/logo.png',
    );

    // Verify welcome greeting text is displayed
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(
      find.text('Giải pháp quản lý phòng trọ tiện lợi & hiệu quả'),
      findsOneWidget,
    );

    // Verify 'Đăng ký' button exists and is clickable
    final registerButton = find.widgetWithText(AppButton, 'Đăng ký');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    expect(registerPressed, isTrue);

    // Verify 'Đăng nhập' button exists and is clickable
    final loginButton = find.widgetWithText(AppButton, 'Đăng nhập');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    expect(loginPressed, isTrue);
  });

  testWidgets('WelcomeScreen toggles language between VI and EN',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const WelcomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially in Vietnamese
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    // Tap EN option
    final enButton = find.text('EN');
    expect(enButton, findsOneWidget);
    await tester.tap(enButton);
    await tester.pumpAndSettle();

    // Now text changes to English
    expect(find.text('Welcome to Roomee'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    // Tap VI option
    final viButton = find.text('VI');
    expect(viButton, findsOneWidget);
    await tester.tap(viButton);
    await tester.pumpAndSettle();

    // Text returns to Vietnamese
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
  });

  testWidgets('AppButton shows loading indicator when isLoading is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Tiếp tục',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tiếp tục'), findsNothing);
  });
}
