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

  group('WorkspaceModel', () {
    test('fromJson and toJson parse Workspace data properly', () {
      final json = {
        'id': 1,
        'userId': 2,
        'type': 'apartment/mini_house',
        'name': 'Khu trọ Thăng Long',
        'area': 120.5,
        'numberOfRooms': 10,
        'provinceId': 1,
        'wardId': 5,
        'address': 'Số 10 Cầu Giấy',
        'description': 'Khu trọ an ninh tốt',
        'contactName': 'Nguyễn Văn Chủ',
        'contactPhone': '0901234567',
        'contactZalo': '0901234567',
        'createdBy': 2,
        'updatedBy': 2,
      };

      final workspace = WorkspaceModel.fromJson(json);

      expect(workspace.id, 1);
      expect(workspace.userId, 2);
      expect(workspace.type, WorkspaceType.apartmentMiniHouse);
      expect(workspace.name, 'Khu trọ Thăng Long');
      expect(workspace.area, 120.5);
      expect(workspace.numberOfRooms, 10);
      expect(workspace.provinceId, 1);
      expect(workspace.wardId, 5);
      expect(workspace.address, 'Số 10 Cầu Giấy');
      expect(workspace.description, 'Khu trọ an ninh tốt');
      expect(workspace.contactName, 'Nguyễn Văn Chủ');
      expect(workspace.contactPhone, '0901234567');
      expect(workspace.contactZalo, '0901234567');

      final output = workspace.toJson();
      expect(output['type'], 'apartment/mini_house');
      expect(output['name'], 'Khu trọ Thăng Long');
      expect(output['area'], 120.5);
    });

    test('copyWith works properly', () {
      const ws1 = WorkspaceModel(
        id: 1,
        userId: 2,
        name: 'Nhà A',
        area: 50.0,
        provinceId: 1,
        wardId: 1,
        address: 'Địa chỉ',
        contactName: 'Chủ',
        contactPhone: '0900000000',
      );
      final ws2 = ws1.copyWith(name: 'Nhà B', numberOfRooms: 5);

      expect(ws2.id, 1);
      expect(ws2.name, 'Nhà B');
      expect(ws2.numberOfRooms, 5);
      expect(ws2.area, 50.0);
    });
  });

  group('PaginationModel', () {
    test('fromJson and toJson parse pagination data properly', () {
      final json = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'total': 45,
        'page': 1,
        'limit': 20,
        'totalPages': 3,
      };

      final pagination = PaginationModel<String>.fromJson(
        json,
        (item) => (item as Map<String, dynamic>)['name'] as String,
      );

      expect(pagination.data.length, 2);
      expect(pagination.data[0], 'Item 1');
      expect(pagination.data[1], 'Item 2');
      expect(pagination.total, 45);
      expect(pagination.page, 1);
      expect(pagination.limit, 20);
      expect(pagination.totalPages, 3);
      expect(pagination.hasReachedMax, isFalse);

      final output = pagination.toJson((item) => item);
      expect(output['total'], 45);
      expect(output['page'], 1);
      expect(output['totalPages'], 3);
      expect((output['data'] as List).length, 2);
    });

    test('hasReachedMax returns true when page >= totalPages', () {
      const pagination = PaginationModel<int>(
        data: [1, 2],
        total: 2,
        page: 2,
        limit: 10,
        totalPages: 2,
      );

      expect(pagination.hasReachedMax, isTrue);
    });

    test('copyWith works properly', () {
      const p1 = PaginationModel<int>(
        data: [1],
        total: 10,
        page: 1,
        limit: 5,
        totalPages: 2,
      );
      final p2 = p1.copyWith(data: [1, 2], page: 2);

      expect(p2.data, [1, 2]);
      expect(p2.page, 2);
      expect(p2.total, 10);
      expect(p2.totalPages, 2);
    });
  });
}
