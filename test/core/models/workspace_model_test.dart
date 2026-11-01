import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/utils/constanst.dart';

void main() {
  group('WorkspaceModel user relation', () {
    test('fromJson parses user when present in json', () {
      final json = {
        'id': 'ws-1',
        'userId': 'user-1',
        'name': 'Khu trọ ABC',
        'area': 120.0,
        'provinceId': 92,
        'wardId': 310,
        'address': 'Đường 30/4',
        'contactName': 'Nguyễn Văn A',
        'contactPhone': '0900000001',
        'user': {
          'id': 'user-1',
          'email': 'a@roomee.vn',
          'fullName': 'Nguyễn Văn A',
          'phoneNumber': '0900000001',
          'role': 'landlord',
        },
      };

      final ws = WorkspaceModel.fromJson(json);

      expect(ws.id, 'ws-1');
      expect(ws.user, isNotNull);
      expect(ws.user?.id, 'user-1');
      expect(ws.user?.fullName, 'Nguyễn Văn A');
      expect(ws.user?.role, UserRole.landlord);
    });

    test('toJson serializes user when present and omits when null', () {
      const wsWithUser = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Khu trọ ABC',
        area: 120.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 30/4',
        contactName: 'Nguyễn Văn A',
        contactPhone: '0900000001',
        user: UserModel(
          id: 'user-1',
          email: 'a@roomee.vn',
          fullName: 'Nguyễn Văn A',
        ),
      );

      final jsonWithUser = wsWithUser.toJson();
      expect(jsonWithUser['user'], isNotNull);
      expect(jsonWithUser['user']['id'], 'user-1');

      const wsWithoutUser = WorkspaceModel(
        id: 'ws-2',
        userId: 'user-2',
        name: 'Khu trọ DEF',
        area: 80.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 3/2',
        contactName: 'Trần B',
        contactPhone: '0900000002',
      );

      final jsonWithoutUser = wsWithoutUser.toJson();
      expect(jsonWithoutUser.containsKey('user'), isFalse);
    });

    test('copyWith updates user relation', () {
      const ws = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Khu trọ ABC',
        area: 120.0,
        provinceId: 92,
        wardId: 310,
        address: 'Đường 30/4',
        contactName: 'Nguyễn Văn A',
        contactPhone: '0900000001',
      );

      expect(ws.user, isNull);

      const user = UserModel(
        id: 'user-1',
        email: 'a@roomee.vn',
        fullName: 'Nguyễn Văn A',
      );

      final updated = ws.copyWith(user: user);

      expect(updated.user, isNotNull);
      expect(updated.user?.id, 'user-1');
      expect(updated.user?.fullName, 'Nguyễn Văn A');
    });
  });
}
