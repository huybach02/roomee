import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/contracts/local_crud_datasource.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/query/offline_page.dart';

class _FakeLocalCrudDataSource implements LocalCrudDataSource<String, String> {
  @override
  String get entityName => 'fakes';

  @override
  Future<void> cacheRemotePage({
    required String accountId,
    required List<String> items,
    bool isComplete = false,
  }) async {}

  @override
  Future<OfflinePage<String>> queryPage({
    required String accountId,
    required Map<String, dynamic> queryParameters,
  }) async {
    return const OfflinePage(
      data: ['item-1'],
      total: 1,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: true,
      source: DataSourceKind.local,
    );
  }

  @override
  Future<String?> getById({
    required String accountId,
    required String id,
  }) async => 'item-$id';

  @override
  Future<void> cacheCreated({
    required String accountId,
    required String item,
  }) async {}

  @override
  Future<void> cacheUpdated({
    required String accountId,
    required String item,
  }) async {}

  @override
  Future<void> remove({
    required String accountId,
    required String id,
  }) async {}

  @override
  Future<void> clearAccount({
    required String accountId,
  }) async {}

  @override
  Future<List<SyncItemDto>> getSyncItems({required String accountId}) async =>
      const [];

  @override
  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems({
    required String accountId,
  }) async =>
      const {};

  @override
  Future<void> applySyncResult({
    required String accountId,
    required SyncResultDto result,
  }) async {}

  @override
  Future<void> applyRelationSync({
    required String accountId,
    required Map<String, SyncResultDto> relationResults,
  }) async {}

  @override
  String itemFromJson(Map<String, dynamic> json) => json['name']?.toString() ?? '';

  @override
  Map<String, dynamic> itemToJson(String item) => {'name': item};
}


void main() {
  test('LocalCrudDataSource defines standard local CRUD contract', () async {
    final LocalCrudDataSource<String, String> ds = _FakeLocalCrudDataSource();

    await ds.cacheRemotePage(accountId: 'acc-1', items: ['a', 'b']);
    final page = await ds.queryPage(accountId: 'acc-1', queryParameters: {});
    expect(page.data, ['item-1']);

    final item = await ds.getById(accountId: 'acc-1', id: '1');
    expect(item, 'item-1');

    await ds.cacheCreated(accountId: 'acc-1', item: 'c');
    await ds.cacheUpdated(accountId: 'acc-1', item: 'c');
    await ds.remove(accountId: 'acc-1', id: '1');
    await ds.clearAccount(accountId: 'acc-1');
  });
}
