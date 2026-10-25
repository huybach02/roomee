import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/widgets/filter/app_filter_drawer.dart';
import 'package:roomee/core/widgets/filter/app_search_app_bar.dart';
import 'package:roomee/core/widgets/filter/filter_field_config.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    locale: const Locale('vi'),
    home: child,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations.preload();
  });

  group('AppSearchAppBar Tests', () {
    testWidgets('renders title and action buttons in normal mode',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            appBar: AppSearchAppBar(
              title: 'Test Title',
              onSearchChanged: (_) {},
              onFilterTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('shows badge when activeFilterCount > 0', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            appBar: AppSearchAppBar(
              title: 'Test Title',
              activeFilterCount: 3,
              onFilterTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('morphs into search input when search icon is tapped',
        (tester) async {
      String searchedText = '';

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            appBar: AppSearchAppBar(
              title: 'Test Title',
              searchHint: 'Nhập từ khóa...',
              onSearchChanged: (val) => searchedText = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhấn icon search
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Lúc này Title biến mất, TextField xuất hiện với nút Back
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Nhập từ khóa...'), findsOneWidget);

      // Nhập từ khóa
      await tester.enterText(find.byType(TextField), 'phòng trọ');
      await tester.pump(const Duration(milliseconds: 500)); // qua debounce

      expect(searchedText, equals('phòng trọ'));

      // Nhấn nút Back để đóng search
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(searchedText, equals(''));
    });
  });

  group('AppFilterDrawer Tests', () {
    testWidgets('renders filter configs and handles selection and apply',
        (tester) async {
      final configs = [
        const FilterFieldConfig.chips(
          key: 'status',
          title: 'Trạng thái',
          options: [
            FilterOption(label: 'Tất cả', value: null),
            FilterOption(label: 'Hoạt động', value: 1),
            FilterOption(label: 'Tạm ngưng', value: 0),
          ],
        ),
      ];

      Map<String, dynamic> appliedFilters = {};
      bool isOpen = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Stack(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => isOpen = true),
                      child: const Text('Open'),
                    ),
                    AppFilterDrawer(
                      isOpen: isOpen,
                      onClose: () => setState(() => isOpen = false),
                      configs: configs,
                      initialFilters: const {'status': 1},
                      onApply: (filters) => appliedFilters = filters,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở Drawer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Bộ lọc & Sắp xếp'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Hoạt động'), findsOneWidget);

      // Chọn option Tạm ngưng
      await tester.tap(find.text('Tạm ngưng'));
      await tester.pumpAndSettle();

      // Bấm nút Áp dụng
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(appliedFilters['status'], equals(0));
    });
  });
}
