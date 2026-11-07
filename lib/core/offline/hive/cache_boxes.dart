import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'hive_box_names.dart';

export 'hive_box_names.dart';

class CacheBoxes {
  /// Cấu hình duy nhất cho tất cả các Box: [tên box -> có mã hóa hay không]
  static const configs = <String, bool>{
    HiveBoxNames.workspaces: true,
    HiveBoxNames.users: true,
    HiveBoxNames.provinces: false,
    HiveBoxNames.wards: false,
    HiveBoxNames.metadata: false,
    HiveBoxNames.syncMutations: true,
  };

  final Map<String, Box<Map>> _boxes;

  const CacheBoxes(this._boxes);

  /// Lấy Box theo tên: boxes[HiveBoxNames.workspaces] hoặc boxes.box(...)
  Box<Map> box(String name) => _boxes[name]!;
  Box<Map> operator [](String name) => _boxes[name]!;

  /// Danh sách toàn bộ các Box đã mở để duyệt hàng loạt
  Iterable<Box<Map>> get all => _boxes.values;

  /// Tự động mở tất cả các Box theo cấu hình duy nhất
  static Future<CacheBoxes> open({HiveCipher? encryptionCipher}) async {
    final opened = <String, Box<Map>>{};

    await Future.wait(
      configs.entries.map((entry) async {
        final cipher = entry.value ? encryptionCipher : null;
        try {
          opened[entry.key] = await Hive.openBox<Map>(
            entry.key,
            encryptionCipher: cipher,
          );
        } catch (e, s) {
          debugPrint('[CacheBoxes] Error opening box "${entry.key}": $e\n$s');
          // Tự động phục hồi khi box bị hỏng hoặc sai encryption key (do đổi key/reinstall):
          // Xóa file box cũ trên đĩa và tạo lại box sạch mới, tránh làm sập khởi động app.
          await Hive.deleteBoxFromDisk(entry.key);
          opened[entry.key] = await Hive.openBox<Map>(
            entry.key,
            encryptionCipher: cipher,
          );
        }
      }),
    );

    return CacheBoxes(opened);
  }

  /// Tự động quét và dọn sạch dữ liệu thuộc accountId trên toàn bộ các Box
  Future<void> clearAccountData(String accountId) async {
    final accountPrefix = 'account:$accountId:';
    final metaPrefix = '$accountId:';

    await Future.wait(
      all.map((box) async {
        final keysToDelete = box.keys
            .where(
              (k) =>
                  k is String &&
                  (k.startsWith(accountPrefix) || k.startsWith(metaPrefix)),
            )
            .toList();

        if (keysToDelete.isNotEmpty) {
          await box.deleteAll(keysToDelete);
        }
      }),
    );
  }
}
