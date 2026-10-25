import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_popup_menu.dart';

void main() {
  testWidgets('AppPopupMenu renders default icon and opens menu with items', (
    WidgetTester tester,
  ) async {
    bool detailTapped = false;
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppPopupMenu<String>(
              onSelected: (val) => selectedValue = val,
              items: [
                AppMenuItem(
                  value: 'detail',
                  title: 'Xem chi tiết',
                  icon: Icons.visibility,
                  onTap: () => detailTapped = true,
                ),
                const AppMenuItem(
                  value: 'delete',
                  title: 'Xóa',
                  icon: Icons.delete,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Kiểm tra icon mặc định
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Nhấn mở menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Menu hiển thị 2 options
    expect(find.text('Xem chi tiết'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsOneWidget);

    // Kiểm tra style nguy hiểm của nút xóa
    final deleteText = tester.widget<Text>(find.text('Xóa'));
    expect(deleteText.style?.color, DefaultColors.danger);

    // Tap vào xem chi tiết
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();

    // Menu đóng lại và các callbacks được gọi
    expect(find.text('Xem chi tiết'), findsNothing);
    expect(detailTapped, isTrue);
    expect(selectedValue, 'detail');
  });

  testWidgets('AppPopupMenu renders custom icon and handles customWidget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppPopupMenu<int>(
              icon: const Icon(Icons.settings, key: Key('custom_icon')),
              items: const [
                AppMenuItem(
                  value: 1,
                  title: 'Custom',
                  customWidget: Text('Custom Item Widget'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom_icon')), findsOneWidget);

    await tester.tap(find.byKey(const Key('custom_icon')));
    await tester.pumpAndSettle();

    expect(find.text('Custom Item Widget'), findsOneWidget);
  });
}
