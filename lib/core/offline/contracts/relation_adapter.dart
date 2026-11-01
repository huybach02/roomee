abstract class RelationAdapter<T> {
  /// Bóc tách các entity con từ danh sách cha, khử trùng lặp và lưu vào các Box tương ứng
  Future<void> saveRelations(String accountId, List<T> entities);

  /// Nhận danh sách cha (thường là 1 trang đã phân trang), gom ID khóa ngoại,
  /// đọc theo lô từ các Box con và gắn ngược lại vào danh sách cha
  Future<List<T>> hydrate(String accountId, List<T> entities);

  /// Dọn dẹp các relation con theo account nếu cần (mặc định không làm gì)
  Future<void> clearRelations(String accountId) async {}
}
