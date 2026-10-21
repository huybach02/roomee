import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/screens/loading_screen.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppLocalizations.preload();
    LoadingScreen.resetStateForTesting();
  });

  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('LoadingScreen Standalone Widget', () {
    testWidgets('renders CircularProgressIndicator and default message', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LoadingScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang xử lý...'), findsOneWidget);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        indicator.valueColor,
        isA<AlwaysStoppedAnimation<Color>>().having(
          (a) => a.value,
          'value',
          DefaultColors.primary,
        ),
      );
    });

    testWidgets('renders custom message when provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LoadingScreen(message: 'Vui lòng chờ giây lát...'),
        ),
      );

      expect(find.text('Vui lòng chờ giây lát...'), findsOneWidget);
      expect(find.text('Đang xử lý...'), findsNothing);
    });
  });

  group('LoadingOverlay Widget Wrapper', () {
    testWidgets('renders only child when isLoading is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LoadingOverlay(
            isLoading: false,
            child: Text('Nội dung trang'),
          ),
        ),
      );

      expect(find.text('Nội dung trang'), findsOneWidget);
      expect(find.byType(LoadingScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders child and LoadingScreen when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LoadingOverlay(
            isLoading: true,
            message: 'Đang tải dữ liệu...',
            child: Text('Nội dung trang'),
          ),
        ),
      );

      expect(find.text('Nội dung trang'), findsOneWidget);
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('Đang tải dữ liệu...'), findsOneWidget);
    });
  });

  group('LoadingScreen Imperative API (show / hide)', () {
    testWidgets('show displays overlay dialog and hide closes it', (
      tester,
    ) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              testContext = context;
              return const Text('Trang chủ');
            },
          ),
        ),
      );

      expect(LoadingScreen.isShowing, isFalse);

      // Mở loading
      LoadingScreen.show(testContext, message: 'Đang lưu...');
      await tester.pump(); // trigger frame to build dialog

      expect(LoadingScreen.isShowing, isTrue);
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('Đang lưu...'), findsOneWidget);

      // Đóng loading
      LoadingScreen.hide(testContext);
      await tester.pumpAndSettle();

      expect(LoadingScreen.isShowing, isFalse);
      expect(find.byType(LoadingScreen), findsNothing);
    });

    testWidgets('Extension methods showLoading and hideLoading work correctly', (
      tester,
    ) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              testContext = context;
              return const Text('Trang chủ');
            },
          ),
        ),
      );

      testContext.showLoading();
      await tester.pump();

      expect(LoadingScreen.isShowing, isTrue);
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('Đang xử lý...'), findsOneWidget);

      testContext.hideLoading();
      await tester.pumpAndSettle();

      expect(LoadingScreen.isShowing, isFalse);
      expect(find.byType(LoadingScreen), findsNothing);
    });

    testWidgets('Multiple show calls are guarded and hide handles safely', (
      tester,
    ) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              testContext = context;
              return const Text('Trang chủ');
            },
          ),
        ),
      );

      // Gọi show 2 lần liên tiếp
      LoadingScreen.show(testContext);
      LoadingScreen.show(testContext);
      await tester.pump();

      expect(LoadingScreen.isShowing, isTrue);
      expect(find.byType(LoadingScreen), findsOneWidget);

      // Gọi hide
      LoadingScreen.hide(testContext);
      await tester.pumpAndSettle();

      expect(LoadingScreen.isShowing, isFalse);
      expect(find.byType(LoadingScreen), findsNothing);

      // Gọi hide lần nữa khi đã đóng không gây crash
      LoadingScreen.hide(testContext);
      await tester.pumpAndSettle();
      expect(LoadingScreen.isShowing, isFalse);
    });
  });
}
