/// Model đại diện cho Tỉnh/Thành phố (liên kết với Province entity ở backend)
class ProvinceModel {
  final int id;
  final int code;
  final String fullName;
  final String? fullNameEn;
  final String codeName;

  const ProvinceModel({
    required this.id,
    required this.code,
    required this.fullName,
    this.fullNameEn,
    required this.codeName,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      fullNameEn: json['fullNameEn'] as String?,
      codeName: json['codeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'fullName': fullName,
      if (fullNameEn != null) 'fullNameEn': fullNameEn,
      'codeName': codeName,
    };
  }

  ProvinceModel copyWith({
    int? id,
    int? code,
    String? fullName,
    String? fullNameEn,
    String? codeName,
  }) {
    return ProvinceModel(
      id: id ?? this.id,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      fullNameEn: fullNameEn ?? this.fullNameEn,
      codeName: codeName ?? this.codeName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, code);
}
