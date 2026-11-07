import 'package:roomee/core/models/ward_model.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';

class WardModelCodec extends EntityCodec<WardModel, int> {
  const WardModelCodec();

  @override
  int getId(WardModel entity) => entity.id;

  @override
  Map<String, dynamic> toJson(WardModel entity) => entity.toJson();

  @override
  WardModel fromJson(Map<String, dynamic> json) => WardModel.fromJson(json);
}
