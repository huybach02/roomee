import 'entity_store.dart';
import 'sync_dtos.dart';

abstract class RelationAdapter<T> {
  /// Bóc tách các entity con từ danh sách cha, khử trùng lặp và lưu vào các Box tương ứng
  Future<void> saveRelations(String accountId, List<T> entities);

  /// Nhận danh sách cha (thường là 1 trang đã phân trang), gom ID khóa ngoại,
  /// đọc theo lô từ các Box con và gắn ngược lại vào danh sách cha
  Future<List<T>> hydrate(String accountId, List<T> entities);

  /// Dọn dẹp các relation con theo account nếu cần (mặc định không làm gì)
  Future<void> clearRelations(String accountId) async {}

  /// Khai báo danh sách các store cần sync tự động (key là tên module, vd: 'user', 'floor')
  Map<String, EntityStore> get syncableStores => const {};

  /// Tự động lấy danh sách {id, updatedAt} từ tất cả các store trong [syncableStores]
  Future<Map<String, List<SyncItemDto>>> getRelationSyncItems(
    String accountId,
  ) async {
    final map = <String, List<SyncItemDto>>{};
    for (final entry in syncableStores.entries) {
      final items = await entry.value.getSyncItems(accountId: accountId);
      if (items.isNotEmpty) {
        map[entry.key] = items;
      }
    }
    return map;
  }

  /// Tự động cập nhật kết quả sync vào các store tương ứng trong [syncableStores]
  Future<void> applyRelationSync(
    String accountId,
    Map<String, SyncResultDto> relationResults,
  ) async {
    for (final entry in syncableStores.entries) {
      final moduleKey = entry.key;
      final result =
          relationResults[moduleKey] ?? relationResults['${moduleKey}s'];
      if (result != null) {
        await entry.value.applySync(accountId: accountId, result: result);
      }
    }
  }
}


