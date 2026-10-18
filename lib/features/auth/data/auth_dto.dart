import 'package:roomee/core/models/models.dart';
import 'package:roomee/utils/constanst.dart';

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginRequest &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password;

  @override
  int get hashCode => Object.hash(email, password);
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final Gender gender;
  final UserRole role;
  final int? provinceId;
  final int? wardId;
  final String? birthday;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.gender = Gender.male,
    this.role = UserRole.tenant,
    this.provinceId,
    this.wardId,
    this.birthday,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phoneNumber != null && phoneNumber!.isNotEmpty)
        'phoneNumber': phoneNumber,
      'gender': gender.name,
      'role': role.name,
      if (provinceId != null) 'provinceId': provinceId,
      if (wardId != null) 'wardId': wardId,
      if (birthday != null && birthday!.isNotEmpty) 'birthday': birthday,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterRequest &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          email == other.email &&
          password == other.password &&
          phoneNumber == other.phoneNumber &&
          gender == other.gender &&
          role == other.role &&
          provinceId == other.provinceId &&
          wardId == other.wardId &&
          birthday == other.birthday;

  @override
  int get hashCode => Object.hash(
        fullName,
        email,
        password,
        phoneNumber,
        gender,
        role,
        provinceId,
        wardId,
        birthday,
      );
}

class AuthData {
  final UserModel? user;
  final String token;

  const AuthData({this.user, required this.token});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {if (user != null) 'user': user!.toJson(), 'token': token};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthData &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          token == other.token;

  @override
  int get hashCode => Object.hash(user, token);
}
