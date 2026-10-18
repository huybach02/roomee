import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  group('ProvinceModel', () {
    test('fromJson and toJson parse Province data properly', () {
      final json = {
        'id': 1,
        'code': 79,
        'fullName': 'Thành phố Hồ Chí Minh',
        'fullNameEn': 'Ho Chi Minh City',
        'codeName': 'ho_chi_minh',
      };

      final province = ProvinceModel.fromJson(json);

      expect(province.id, 1);
      expect(province.code, 79);
      expect(province.fullName, 'Thành phố Hồ Chí Minh');
      expect(province.fullNameEn, 'Ho Chi Minh City');
      expect(province.codeName, 'ho_chi_minh');

      final output = province.toJson();
      expect(output['id'], 1);
      expect(output['code'], 79);
      expect(output['fullName'], 'Thành phố Hồ Chí Minh');
    });

    test('copyWith and equality work properly', () {
      const province1 = ProvinceModel(
        id: 1,
        code: 79,
        fullName: 'Thành phố Hồ Chí Minh',
        codeName: 'ho_chi_minh',
      );
      final province2 = province1.copyWith(fullNameEn: 'HCM City');

      expect(province2.id, 1);
      expect(province2.code, 79);
      expect(province2.fullNameEn, 'HCM City');
      expect(province1 == province2, isTrue); // So sánh theo id và code
    });
  });

  group('WardModel', () {
    test('fromJson and toJson parse Ward data properly', () {
      final json = {
        'id': 10,
        'code': 26734,
        'provinceId': 1,
        'fullName': 'Phường Bến Nghé',
        'fullNameEn': 'Ben Nghe Ward',
        'codeName': 'ben_nghe',
      };

      final ward = WardModel.fromJson(json);

      expect(ward.id, 10);
      expect(ward.code, 26734);
      expect(ward.provinceId, 1);
      expect(ward.fullName, 'Phường Bến Nghé');
      expect(ward.fullNameEn, 'Ben Nghe Ward');
      expect(ward.codeName, 'ben_nghe');

      final output = ward.toJson();
      expect(output['id'], 10);
      expect(output['code'], 26734);
      expect(output['provinceId'], 1);
    });

    test('copyWith and equality work properly', () {
      const ward1 = WardModel(
        id: 10,
        code: 26734,
        provinceId: 1,
        fullName: 'Phường Bến Nghé',
        codeName: 'ben_nghe',
      );
      final ward2 = ward1.copyWith(fullNameEn: 'Ben Nghe');

      expect(ward2.id, 10);
      expect(ward2.fullNameEn, 'Ben Nghe');
      expect(ward1 == ward2, isTrue); // So sánh theo id và code
    });
  });

  group('UserModel', () {
    test('fromJson and toJson parse User data properly', () {
      final json = {
        'id': 'usr_1',
        'email': 'tenant@roomee.vn',
        'fullName': 'Nguyễn Văn A',
        'phoneNumber': '0901234567',
        'gender': 'female',
        'role': 'landlord',
        'isActive': false,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr_1');
      expect(user.email, 'tenant@roomee.vn');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.phoneNumber, '0901234567');
      expect(user.gender, Gender.female);
      expect(user.role, UserRole.landlord);
      expect(user.isActive, isFalse);

      final output = user.toJson();
      expect(output['role'], 'landlord');
      expect(output['gender'], 'female');
    });

    test('copyWith and equality work properly', () {
      const user1 = UserModel(id: '1', email: 'a@roomee.vn');
      final user2 = user1.copyWith(fullName: 'A');

      expect(user2.id, '1');
      expect(user2.fullName, 'A');
      expect(user1 == user2, isTrue); // So sánh theo id và email
    });

    test('parses birthday as a date', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@roomee.vn',
        'birthday': '2000-05-15',
      });

      expect(user.birthday, DateTime(2000, 5, 15));
      expect(user.toJson()['birthday'], '2000-05-15');
    });
  });
}
