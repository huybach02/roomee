import 'package:hive_ce_flutter/hive_flutter.dart';

import 'cache_boxes.dart';

class HiveInitializer {
  static Future<CacheBoxes> initialize() async {
    await Hive.initFlutter();

    return CacheBoxes.open();
  }
}
