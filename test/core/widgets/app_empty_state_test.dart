import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState renders title, subtitle, and default icon properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Chưa có dữ liệu',
            subtitle: 'Vui lòng quay lại sau',
            icon: Icons.domain_disabled_rounded,
          ),
        ),
      ),
    );

    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    expect(find.text('Vui lòng quay lại sau'), findsOneWidget);
    expect(find.byIcon(Icons.domain_disabled_rounded), findsOneWidget);

    // Verify title text style
    final titleWidget = tester.widget<Text>(find.text('Chưa có dữ liệu'));
    expect(titleWidget.style?.color, DefaultColors.textPrimary);
    expect(titleWidget.style?.fontWeight, FontWeight.bold);

    // Verify subtitle text style
    final subtitleWidget = tester.widget<Text>(find.text('Vui lòng quay lại sau'));
    expect(subtitleWidget.style?.color, DefaultColors.textSecondary);
  });

  testWidgets('AppEmptyState handles action widget and user interaction', (
    WidgetTester tester,
  ) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Danh sách trống',
            action: ElevatedButton(
              onPressed: () => actionTapped = true,
              child: const Text('Tạo mới ngay'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Danh sách trống'), findsOneWidget);
    expect(find.text('Tạo mới ngay'), findsOneWidget);

    await tester.tap(find.text('Tạo mới ngay'));
    await tester.pump();

    expect(actionTapped, isTrue);
  });

  testWidgets('AppEmptyState renders custom illustration when provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Custom Illustration',
            illustration: Icon(Icons.star, key: Key('custom_star')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom_star')), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsNothing);
  });
}
