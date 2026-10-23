import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/screens/no_internet_screen.dart';
import 'package:roomee/core/widgets/app_button.dart';

void main() {
  setUp(() async {
    await AppLocalizations.preload();
    NoInternetScreen.resetStateForTesting();
  });

  Widget createTestWidget() {
    return const MaterialApp(
      home: NoInternetScreen(),
    );
  }

  testWidgets('NoInternetScreen renders properly with icon, title, message, and retry button',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text(t('errors.noInternetTitle')), findsOneWidget);
    expect(find.text(t('errors.noInternetMessage')), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text(t('retry')), findsOneWidget);
  });
}
