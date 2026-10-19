import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_notification.dart';

void main() {
  testWidgets('AppNotification.showSuccess displays green SnackBar with check icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotification.showSuccess(context, 'Thành công!');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final SnackBar snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.backgroundColor, DefaultColors.success);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Thành công!'), findsOneWidget);
  });

  testWidgets('AppNotification.showError displays red SnackBar with error icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotification.showError(context, 'Có lỗi xảy ra!');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final SnackBar snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.backgroundColor, DefaultColors.danger);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Có lỗi xảy ra!'), findsOneWidget);
  });

  testWidgets('AppNotification.showWarning displays yellow SnackBar with warning icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotification.showWarning(context, 'Cảnh báo!');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, DefaultColors.warning);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Cảnh báo!'), findsOneWidget);
  });

  testWidgets('AppNotification.showInfo displays info SnackBar with info icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.showInfoNotification('Thông tin hướng dẫn');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, DefaultColors.info);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Thông tin hướng dẫn'), findsOneWidget);
  });
}
