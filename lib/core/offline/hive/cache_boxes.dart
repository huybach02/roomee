import 'package:hive_ce_flutter/hive_flutter.dart';

import 'hive_box_names.dart';

class CacheBoxes {
  final Box<Map> workspaces;
  final Box<Map> users;
  final Box<Map> provinces;
  final Box<Map> wards;
  final Box<Map> metadata;

  const CacheBoxes({
    required this.workspaces,
    required this.users,
    required this.provinces,
    required this.wards,
    required this.metadata,
  });

  static Future<CacheBoxes> open() async {
    return CacheBoxes(
      metadata: await Hive.openBox<Map>(HiveBoxNames.metadata),
      workspaces: await Hive.openBox<Map>(HiveBoxNames.workspaces),
      users: await Hive.openBox<Map>(HiveBoxNames.users),
      provinces: await Hive.openBox<Map>(HiveBoxNames.provinces),
      wards: await Hive.openBox<Map>(HiveBoxNames.wards),
    );
  }
}
