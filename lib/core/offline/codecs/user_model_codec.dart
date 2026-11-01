import 'package:roomee/core/models/user_model.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';

class UserModelCodec implements EntityCodec<UserModel, String> {
  const UserModelCodec();

  @override
  String getId(UserModel entity) => entity.id;

  @override
  Map<String, dynamic> toJson(UserModel entity) => entity.toJson();

  @override
  UserModel fromJson(Map<String, dynamic> json) => UserModel.fromJson(json);
}
