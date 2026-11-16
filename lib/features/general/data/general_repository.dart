import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/contracts/entity_store.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_entity_store.dart';

abstract class IGeneralRepository {
  Future<List<ProvinceModel>> getProvinces();
  Future<List<WardModel>> getWardsByProvince(int provinceId);
}

class GeneralRepository implements IGeneralRepository {
  static const String globalAccountId = 'global';

  final EntityStore<ProvinceModel, int>? _provinceStore;
  final EntityStore<WardModel, int>? _wardStore;

  GeneralRepository({
    EntityStore<ProvinceModel, int>? provinceStore,
    EntityStore<WardModel, int>? wardStore,
  })  : _provinceStore = provinceStore,
        _wardStore = wardStore;

  factory GeneralRepository.fromBoxes(CacheBoxes boxes) {
    return GeneralRepository(
      provinceStore: HiveEntityStore<ProvinceModel, int>(
        box: boxes[HiveBoxNames.provinces],
        codec: const ProvinceModelCodec(),
      ),
      wardStore: HiveEntityStore<WardModel, int>(
        box: boxes[HiveBoxNames.wards],
        codec: const WardModelCodec(),
      ),
    );
  }

  EntityStore<ProvinceModel, int>? get _effectiveProvinceStore {
    if (_provinceStore != null) return _provinceStore;
    if (Hive.isBoxOpen(HiveBoxNames.provinces)) {
      return HiveEntityStore<ProvinceModel, int>(
        box: Hive.box<Map>(HiveBoxNames.provinces),
        codec: const ProvinceModelCodec(),
      );
    }
    return null;
  }

  EntityStore<WardModel, int>? get _effectiveWardStore {
    if (_wardStore != null) return _wardStore;
    if (Hive.isBoxOpen(HiveBoxNames.wards)) {
      return HiveEntityStore<WardModel, int>(
        box: Hive.box<Map>(HiveBoxNames.wards),
        codec: const WardModelCodec(),
      );
    }
    return null;
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    final store = _effectiveProvinceStore;
    if (store != null) {
      final cached = await store.getAll(accountId: globalAccountId);
      if (cached.isNotEmpty) {
        cached.sort((a, b) => a.fullName.compareTo(b.fullName));
        return cached;
      }
    }
    return const [];
  }

  @override
  Future<List<WardModel>> getWardsByProvince(int provinceId) async {
    final store = _effectiveWardStore;
    if (store != null) {
      final cached = await store.getAll(accountId: globalAccountId);
      final filtered = cached
          .where((w) => w.provinceId == provinceId)
          .toList();
      if (filtered.isNotEmpty) {
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        return filtered;
      }
    }
    return const [];
  }
}
