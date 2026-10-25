import 'package:roomee/core/models/province_model.dart';
import 'package:roomee/core/models/ward_model.dart';
import 'package:roomee/utils/constanst.dart';

class WorkspaceModel {
  final int id;
  final int userId;
  final WorkspaceType type;
  final String name;
  final double area;
  final int numberOfRooms;
  final int provinceId;
  final ProvinceModel? province;
  final int wardId;
  final WardModel? ward;
  final String address;
  final String? description;
  final String contactName;
  final String contactPhone;
  final String? contactZalo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? deletedAt;
  final int? deletedBy;

  const WorkspaceModel({
    required this.id,
    required this.userId,
    this.type = WorkspaceType.rentedRoom,
    required this.name,
    required this.area,
    this.numberOfRooms = 0,
    required this.provinceId,
    this.province,
    required this.wardId,
    this.ward,
    required this.address,
    this.description,
    required this.contactName,
    required this.contactPhone,
    this.contactZalo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      type: WorkspaceType.fromValue(json['type'] as String?),
      name: json['name'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      numberOfRooms: (json['numberOfRooms'] as num?)?.toInt() ?? 0,
      provinceId: (json['provinceId'] as num).toInt(),
      province: json['province'] != null
          ? ProvinceModel.fromJson(json['province'] as Map<String, dynamic>)
          : null,
      wardId: (json['wardId'] as num).toInt(),
      ward: json['ward'] != null
          ? WardModel.fromJson(json['ward'] as Map<String, dynamic>)
          : null,
      address: json['address'] as String? ?? '',
      description: json['description'] as String?,
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactZalo: json['contactZalo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdBy: (json['createdBy'] as num?)?.toInt(),
      updatedBy: (json['updatedBy'] as num?)?.toInt(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      deletedBy: (json['deletedBy'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'name': name,
      'area': area,
      'numberOfRooms': numberOfRooms,
      'provinceId': provinceId,
      if (province != null) 'province': province!.toJson(),
      'wardId': wardId,
      if (ward != null) 'ward': ward!.toJson(),
      'address': address,
      if (description != null) 'description': description,
      'contactName': contactName,
      'contactPhone': contactPhone,
      if (contactZalo != null) 'contactZalo': contactZalo,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deletedBy': deletedBy,
    };
  }

  WorkspaceModel copyWith({
    int? id,
    int? userId,
    WorkspaceType? type,
    String? name,
    double? area,
    int? numberOfRooms,
    int? provinceId,
    ProvinceModel? province,
    int? wardId,
    WardModel? ward,
    String? address,
    String? description,
    String? contactName,
    String? contactPhone,
    String? contactZalo,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
    DateTime? deletedAt,
    int? deletedBy,
  }) {
    return WorkspaceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      area: area ?? this.area,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      provinceId: provinceId ?? this.provinceId,
      province: province ?? this.province,
      wardId: wardId ?? this.wardId,
      ward: ward ?? this.ward,
      address: address ?? this.address,
      description: description ?? this.description,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactZalo: contactZalo ?? this.contactZalo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
