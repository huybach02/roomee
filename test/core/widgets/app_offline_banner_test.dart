import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/widgets/app_offline_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('vi'), Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations.preload();
  });

  testWidgets('AppOfflineBanner renders notice and wifi_off icon', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppOfflineBanner()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text(t('common.offlineModeNotice')), findsOneWidget);
  });

  testWidgets('AppOfflineBanner formats and displays lastFetchedAt', (tester) async {
    final time = DateTime(2026, 11, 1, 14, 30);
    await tester.pumpWidget(
      _wrap(AppOfflineBanner(lastFetchedAt: time)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.textContaining('14:30 01/11'), findsOneWidget);
  });
}
