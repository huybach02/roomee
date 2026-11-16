import 'package:flutter/foundation.dart';

@immutable
class LookupOption {
  final dynamic id;
  final String label;
  final dynamic parentId;
  final Map<String, dynamic>? extra;

  const LookupOption({
    required this.id,
    required this.label,
    this.parentId,
    this.extra,
  });

  factory LookupOption.fromJson(Map<String, dynamic> json) {
    return LookupOption(
      id: json['id'],
      label: json['label']?.toString() ?? '',
      parentId: json['parentId'],
      extra: json['extra'] is Map
          ? Map<String, dynamic>.from(json['extra'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (parentId != null) 'parentId': parentId,
    if (extra != null) 'extra': extra,
  };

  LookupOption copyWith({
    dynamic id,
    String? label,
    dynamic parentId,
    Map<String, dynamic>? extra,
  }) {
    return LookupOption(
      id: id ?? this.id,
      label: label ?? this.label,
      parentId: parentId ?? this.parentId,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupOption &&
          runtimeType == other.runtimeType &&
          id.toString() == other.id.toString() &&
          label == other.label &&
          parentId?.toString() == other.parentId?.toString();

  @override
  int get hashCode => Object.hash(id.toString(), label, parentId?.toString());

  @override
  String toString() =>
      'LookupOption(id: $id, label: $label, parentId: $parentId)';
}
