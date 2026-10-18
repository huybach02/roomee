/// Model đại diện cho Phường/Xã (liên kết với Ward entity ở backend)
class WardModel {
  final int id;
  final int code;
  final int provinceId;
  final String fullName;
  final String? fullNameEn;
  final String codeName;

  const WardModel({
    required this.id,
    required this.code,
    required this.provinceId,
    required this.fullName,
    this.fullNameEn,
    required this.codeName,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as int? ?? 0,
      provinceId: json['provinceId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      fullNameEn: json['fullNameEn'] as String?,
      codeName: json['codeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'provinceId': provinceId,
      'fullName': fullName,
      if (fullNameEn != null) 'fullNameEn': fullNameEn,
      'codeName': codeName,
    };
  }

  WardModel copyWith({
    int? id,
    int? code,
    int? provinceId,
    String? fullName,
    String? fullNameEn,
    String? codeName,
  }) {
    return WardModel(
      id: id ?? this.id,
      code: code ?? this.code,
      provinceId: provinceId ?? this.provinceId,
      fullName: fullName ?? this.fullName,
      fullNameEn: fullNameEn ?? this.fullNameEn,
      codeName: codeName ?? this.codeName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, code);
}
