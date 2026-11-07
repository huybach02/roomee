import 'package:roomee/core/models/province_model.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';

class ProvinceModelCodec extends EntityCodec<ProvinceModel, int> {
  const ProvinceModelCodec();

  @override
  int getId(ProvinceModel entity) => entity.id;

  @override
  Map<String, dynamic> toJson(ProvinceModel entity) => entity.toJson();

  @override
  ProvinceModel fromJson(Map<String, dynamic> json) =>
      ProvinceModel.fromJson(json);
}
