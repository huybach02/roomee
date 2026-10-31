import 'package:flutter/material.dart';

enum FilterType {
  /// Chọn 1 giá trị dạng nút bấm (Filter Chips)
  chips,

  /// Chọn nhiều giá trị dạng nút bấm (Multi-select Chips)
  multiChips,

  /// Dropdown chọn từ danh sách async (ví dụ: Tỉnh/Thành phố, Phường/Xã)
  dropdown,

  /// Khoảng giá trị (Min - Max)
  range,
}

class FilterOption {
  final String label;
  final dynamic value;
  final IconData? icon;

  const FilterOption({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class FilterFieldConfig {
  /// Key tương ứng trong query parameter (ví dụ: 'type', 'status', 'sortBy')
  final String key;

  /// Tiêu đề hiển thị cho section filter này
  final String title;

  /// Loại giao diện hiển thị
  final FilterType type;

  /// Danh sách các lựa chọn tĩnh
  final List<FilterOption>? options;

  /// Hàm nạp lựa chọn bất đồng bộ (cho dropdown như Tỉnh/Thành)
  final Future<List<FilterOption>> Function()? loadOptionsAsync;

  /// Giá trị mặc định (nếu giá trị hiện tại == defaultValue thì không tính là filter đang active)
  final dynamic defaultValue;

  /// Dùng cho FilterType.range
  final String? minKey;
  final String? maxKey;
  final String? unit;

  /// Đánh dấu cấu hình này là trường sắp xếp (tự động gom vào query param 'sort')
  final bool isSort;

  const FilterFieldConfig.chips({
    required this.key,
    required this.title,
    required this.options,
    this.defaultValue,
    this.isSort = false,
  })  : type = FilterType.chips,
        loadOptionsAsync = null,
        minKey = null,
        maxKey = null,
        unit = null;

  const FilterFieldConfig.multiChips({
    required this.key,
    required this.title,
    required this.options,
    this.defaultValue,
    this.isSort = false,
  })  : type = FilterType.multiChips,
        loadOptionsAsync = null,
        minKey = null,
        maxKey = null,
        unit = null;

  const FilterFieldConfig.dropdown({
    required this.key,
    required this.title,
    required this.loadOptionsAsync,
    this.defaultValue,
  })  : type = FilterType.dropdown,
        options = null,
        minKey = null,
        maxKey = null,
        unit = null,
        isSort = false;

  const FilterFieldConfig.range({
    required this.title,
    required this.minKey,
    required this.maxKey,
    this.unit,
    this.defaultValue,
  })  : key = '',
        type = FilterType.range,
        options = null,
        loadOptionsAsync = null,
        isSort = false;
}
