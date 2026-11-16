import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';

class DataUnitsPreloader {
  static const String assetPath = 'assets/data/data_units.json';
  static const String globalAccountId = 'global';
  static const String _metadataKey = 'data_units_version';

  /// Phiên bản của tập dữ liệu Tỉnh & Phường trong asset.
  /// Khi có thay đổi trong file JSON (sáp nhập tỉnh/xã, đổi tên...), chỉ cần tăng version lên 2, 3...
  /// Ứng dụng sẽ tự động nhận diện và nạp đè dữ liệu mới.
  static const int currentVersion = 1;

  /// Nạp sẵn dữ liệu Tỉnh/Thành và Phường/Xã từ asset vào Hive theo cơ chế Versioning.
  ///
  /// - Khi mở app bình thường: Chỉ kiểm tra 1 key trong metadata (tốn 0ms, không đọc file JSON).
  /// - Khi mới cài app hoặc nâng version: Đọc file asset nạp vào Hive và ghi nhận version.
  static Future<void> seedIfEmpty(CacheBoxes cacheBoxes, {bool force = false}) async {
    final metaBox = cacheBoxes[HiveBoxNames.metadata];
    final metaData = metaBox.get(_metadataKey);
    final seededVersion = (metaData?['version'] as int?) ?? 0;

    final provinceBox = cacheBoxes[HiveBoxNames.provinces];
    final wardBox = cacheBoxes[HiveBoxNames.wards];

    // ⚡ Fast-path (0ms): Đã seed đúng phiên bản và các box có dữ liệu
    if (!force &&
        seededVersion == currentVersion &&
        provinceBox.isNotEmpty &&
        wardBox.isNotEmpty) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonString);
      if (data is! Map<String, dynamic>) return;

      final provincesRaw = data['provinces'] as List? ?? [];
      final wardsRaw = data['wards'] as List? ?? [];

      // Nếu nâng cấp phiên bản hoặc ép nạp lại: Xóa dữ liệu cũ để tránh bản ghi mồ côi
      if (force || (seededVersion != currentVersion && seededVersion > 0)) {
        await Future.wait([
          provinceBox.clear(),
          wardBox.clear(),
        ]);
      }

      final provinceStore = HiveEntityStore<ProvinceModel, int>(
        box: provinceBox,
        codec: const ProvinceModelCodec(),
      );
      final wardStore = HiveEntityStore<WardModel, int>(
        box: wardBox,
        codec: const WardModelCodec(),
      );

      final provinces = provincesRaw
          .whereType<Map>()
          .map((p) => ProvinceModel.fromJson(Map<String, dynamic>.from(p)))
          .toList();

      final wards = wardsRaw
          .whereType<Map>()
          .map((w) => WardModel.fromJson(Map<String, dynamic>.from(w)))
          .toList();

      await Future.wait([
        if (provinces.isNotEmpty)
          provinceStore.putMany(
            accountId: globalAccountId,
            entities: provinces,
          ),
        if (wards.isNotEmpty)
          wardStore.putMany(
            accountId: globalAccountId,
            entities: wards,
          ),
      ]);

      // Ghi nhận metadata phiên bản đã nạp thành công
      await metaBox.put(_metadataKey, {
        'version': currentVersion,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'provincesCount': provinces.length,
        'wardsCount': wards.length,
      });

      debugPrint(
        '[DataUnitsPreloader] ✅ Đã nạp thành công ${provinces.length} tỉnh và ${wards.length} phường (v$currentVersion)',
      );
    } catch (e, s) {
      debugPrint('[DataUnitsPreloader] Error seeding data units: $e\n$s');
    }
  }
}
