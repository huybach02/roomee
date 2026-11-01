import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/codecs/province_model_codec.dart';
import 'package:roomee/core/offline/codecs/user_model_codec.dart';
import 'package:roomee/core/offline/codecs/ward_model_codec.dart';
import 'package:roomee/core/offline/contracts/relation_adapter.dart';
import 'package:roomee/utils/constanst.dart';

class _TestAdapter extends RelationAdapter<String> {
  @override
  Future<void> saveRelations(String accountId, List<String> entities) async {}

  @override
  Future<List<String>> hydrate(
    String accountId,
    List<String> entities,
  ) async => entities;
}

void main() {
  group('ProvinceModelCodec', () {
    final codec = ProvinceModelCodec();
    const province = ProvinceModel(
      id: 92,
      code: 92,
      fullName: 'Thành phố Cần Thơ',
      codeName: 'can_tho',
    );

    test('getId returns int id', () {
      expect(codec.getId(province), 92);
    });

    test('toJson and fromJson preserve data', () {
      final json = codec.toJson(province);
      final restored = codec.fromJson(json);

      expect(restored.id, province.id);
      expect(restored.code, province.code);
      expect(restored.fullName, province.fullName);
      expect(restored.codeName, province.codeName);
    });
  });

  group('WardModelCodec', () {
    final codec = WardModelCodec();
    const ward = WardModel(
      id: 310,
      code: 310,
      provinceId: 92,
      fullName: 'Phường Ninh Kiều',
      codeName: 'ninh_kieu',
    );

    test('getId returns int id', () {
      expect(codec.getId(ward), 310);
    });

    test('toJson and fromJson preserve data', () {
      final json = codec.toJson(ward);
      final restored = codec.fromJson(json);

      expect(restored.id, ward.id);
      expect(restored.code, ward.code);
      expect(restored.provinceId, ward.provinceId);
      expect(restored.fullName, ward.fullName);
      expect(restored.codeName, ward.codeName);
    });
  });

  group('UserModelCodec', () {
    final codec = UserModelCodec();
    const user = UserModel(
      id: 'u-1',
      email: 'landlord@roomee.vn',
      fullName: 'Nguyễn Văn A',
      phoneNumber: '0900000001',
      role: UserRole.landlord,
    );

    test('getId returns string id', () {
      expect(codec.getId(user), 'u-1');
    });

    test('toJson and fromJson preserve data', () {
      final json = codec.toJson(user);
      final restored = codec.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.fullName, user.fullName);
      expect(restored.phoneNumber, user.phoneNumber);
      expect(restored.role, user.role);
    });
  });

  group('RelationAdapter', () {
    test('default clearRelations completes without error', () async {
      final adapter = _TestAdapter();
      await expectLater(adapter.clearRelations('acc-1'), completes);
    });
  });
}
