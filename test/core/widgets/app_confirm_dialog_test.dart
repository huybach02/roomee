import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/widgets/app_confirm_dialog.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations.preload();
  });

  Widget buildTestWidget({
    required VoidCallback onTrigger,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: onTrigger,
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  testWidgets('AppConfirmDialog renders title, message and default buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        onTrigger: () {},
      ),
    );

    final BuildContext context = tester.element(find.byType(ElevatedButton));

    AppConfirmDialog.show(
      context,
      title: 'Tiêu đề xác nhận',
      message: 'Bạn có chắc chắn không?',
    );

    await tester.pumpAndSettle();

    expect(find.text('Tiêu đề xác nhận'), findsOneWidget);
    expect(find.text('Bạn có chắc chắn không?'), findsOneWidget);
    expect(find.text(t('cancel')), findsOneWidget);
    expect(find.text(t('confirm')), findsOneWidget);
  });

  testWidgets('AppConfirmDialog cancel button returns false and triggers onCancel', (
    WidgetTester tester,
  ) async {
    bool? dialogResult;
    bool cancelTriggered = false;

    await tester.pumpWidget(
      buildTestWidget(
        onTrigger: () {},
      ),
    );

    final BuildContext context = tester.element(find.byType(ElevatedButton));

    AppConfirmDialog.show(
      context,
      title: 'Xác nhận hủy',
      message: 'Thử nút hủy',
      onCancel: () {
        cancelTriggered = true;
      },
    ).then((val) => dialogResult = val);

    await tester.pumpAndSettle();

    await tester.tap(find.text(t('cancel')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(dialogResult, isFalse);
    expect(cancelTriggered, isTrue);
  });

  testWidgets('AppConfirmDialog confirm button returns true and triggers onConfirm with danger style', (
    WidgetTester tester,
  ) async {
    bool? dialogResult;
    bool confirmTriggered = false;

    await tester.pumpWidget(
      buildTestWidget(
        onTrigger: () {},
      ),
    );

    final BuildContext context = tester.element(find.byType(ElevatedButton));

    AppConfirmDialog.show(
      context,
      title: 'Xác nhận xóa',
      message: 'Xác nhận xóa dữ liệu?',
      confirmText: 'Xóa ngay',
      isDanger: true,
      onConfirm: () {
        confirmTriggered = true;
      },
    ).then((val) => dialogResult = val);

    await tester.pumpAndSettle();

    final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'Xóa ngay');
    expect(confirmButtonFinder, findsOneWidget);

    final ElevatedButton button = tester.widget<ElevatedButton>(confirmButtonFinder);
    expect(button.style?.backgroundColor?.resolve({}), DefaultColors.danger);

    await tester.tap(confirmButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(dialogResult, isTrue);
    expect(confirmTriggered, isTrue);
  });

  testWidgets('AppConfirmDialog renders custom content widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        onTrigger: () {},
      ),
    );

    final BuildContext context = tester.element(find.byType(ElevatedButton));

    AppConfirmDialog.show(
      context,
      title: 'Custom Content',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: DefaultColors.warning),
          Text('Nội dung tùy biến'),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Custom Content'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.text('Nội dung tùy biến'), findsOneWidget);
  });
}
