import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/contracts/lookup_option.dart';
import 'package:roomee/core/offline/repository/lookup_repository.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';
import 'package:roomee/core/widgets/lookup_dropdown_field.dart';

class _FakeLookupRepository implements ILookupRepository {
  List<LookupOption> options;
  Object? errorToThrow;
  final List<dynamic> requestedParentIds = [];

  _FakeLookupRepository({this.options = const []});

  @override
  Future<List<LookupOption>> getOptions({
    required String accountId,
    required String module,
    dynamic parentId,
    bool forceRefresh = false,
  }) async {
    requestedParentIds.add(parentId);
    if (errorToThrow != null) throw errorToThrow!;
    return options;
  }

  @override
  Future<void> refreshAll({
    required String accountId,
    List<String>? modules,
  }) async {}

  @override
  Future<void> addOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {}

  @override
  Future<void> updateOption({
    required String accountId,
    required String module,
    required LookupOption option,
  }) async {}

  @override
  Future<void> removeOption({
    required String accountId,
    required String module,
    required dynamic id,
  }) async {}
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('LookupDropdownField', () {
    testWidgets('nạp options và hiển thị label của value đang chọn', (
      tester,
    ) async {
      final repo = _FakeLookupRepository(
        options: const [
          LookupOption(id: 'ws-1', label: 'Workspace Một'),
          LookupOption(id: 'ws-2', label: 'Workspace Hai'),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          LookupDropdownField(
            lookupRepository: repo,
            accountId: 'user-1',
            module: 'workspaces',
            value: 'ws-2',
            labelText: 'Workspace',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workspace Hai'), findsOneWidget);
    });

    testWidgets('mở sheet và chọn option trả về id dạng chuỗi', (tester) async {
      String? selected;
      final repo = _FakeLookupRepository(
        options: const [
          LookupOption(id: 'ws-1', label: 'Workspace Một'),
          LookupOption(id: 'ws-2', label: 'Workspace Hai'),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return LookupDropdownField(
                lookupRepository: repo,
                accountId: 'user-1',
                module: 'workspaces',
                value: selected,
                searchHint: 'Tìm kiếm...',
                emptyText: 'Không có dữ liệu',
                onChanged: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Workspace Một'));
      await tester.pumpAndSettle();

      expect(selected, 'ws-1');
      expect(find.text('Workspace Một'), findsOneWidget);
    });

    testWidgets('lỗi khi nạp không làm sập form và hiện emptyText', (
      tester,
    ) async {
      final repo = _FakeLookupRepository()..errorToThrow = Exception('boom');

      await tester.pumpWidget(
        _wrap(
          LookupDropdownField(
            lookupRepository: repo,
            accountId: 'user-1',
            module: 'workspaces',
            emptyText: 'Không có dữ liệu',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Không có dữ liệu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('đổi parentId sẽ nạp lại đúng tham số', (tester) async {
      final repo = _FakeLookupRepository(
        options: const [LookupOption(id: 'room-1', label: 'Phòng 1')],
      );

      Widget build(String? parentId) => _wrap(
        LookupDropdownField(
          lookupRepository: repo,
          accountId: 'user-1',
          module: 'rooms',
          parentId: parentId,
        ),
      );

      await tester.pumpWidget(build('ws-1'));
      await tester.pumpAndSettle();
      expect(repo.requestedParentIds, contains('ws-1'));

      await tester.pumpWidget(build('ws-2'));
      await tester.pumpAndSettle();
      expect(repo.requestedParentIds, contains('ws-2'));

      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Phòng 1'), findsOneWidget);
    });
  });
}
