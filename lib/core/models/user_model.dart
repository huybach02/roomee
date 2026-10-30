import 'package:intl/intl.dart';
import 'package:roomee/core/models/province_model.dart';
import 'package:roomee/core/models/ward_model.dart';
import 'package:roomee/utils/constanst.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final DateTime? birthday;
  final Gender gender;
  final UserRole role;
  final bool isActive;
  final bool hasContract;
  final int? provinceId;
  final ProvinceModel? province;
  final int? wardId;
  final WardModel? ward;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.birthday,
    this.gender = Gender.male,
    this.role = UserRole.tenant,
    this.isActive = true,
    this.hasContract = false,
    this.provinceId,
    this.province,
    this.wardId,
    this.ward,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
      gender: _parseGender(json['gender']),
      role: _parseRole(json['role']),
      isActive: json['isActive'] as bool? ?? true,
      hasContract: json['hasContract'] as bool? ?? false,
      provinceId: json['provinceId'] as int?,
      province: json['province'] is Map<String, dynamic>
          ? ProvinceModel.fromJson(json['province'] as Map<String, dynamic>)
          : null,
      wardId: json['wardId'] as int?,
      ward: json['ward'] is Map<String, dynamic>
          ? WardModel.fromJson(json['ward'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (fullName != null) 'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (birthday != null) 'birthday': DateFormat('yyyy-MM-dd').format(birthday!),
      'gender': gender.name,
      'role': role.name,
      'isActive': isActive,
      'hasContract': hasContract,
      if (provinceId != null) 'provinceId': provinceId,
      if (province != null) 'province': province!.toJson(),
      if (wardId != null) 'wardId': wardId,
      if (ward != null) 'ward': ward!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    DateTime? birthday,
    Gender? gender,
    UserRole? role,
    bool? isActive,
    bool? hasContract,
    int? provinceId,
    ProvinceModel? province,
    int? wardId,
    WardModel? ward,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      hasContract: hasContract ?? this.hasContract,
      provinceId: provinceId ?? this.provinceId,
      province: province ?? this.province,
      wardId: wardId ?? this.wardId,
      ward: ward ?? this.ward,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static Gender _parseGender(dynamic val) {
    if (val == 'female') return Gender.female;
    if (val == 'other') return Gender.other;
    return Gender.male;
  }

  static UserRole _parseRole(dynamic val) {
    if (val == 'landlord') return UserRole.landlord;
    if (val == 'staff') return UserRole.staff;
    if (val == 'admin') return UserRole.admin;
    return UserRole.tenant;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          hasContract == other.hasContract;

  @override
  int get hashCode => Object.hash(id, email, role, hasContract);
}
