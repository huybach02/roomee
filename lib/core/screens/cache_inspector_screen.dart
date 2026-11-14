import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/widgets/app_notification.dart';

/// Màn hình kiểm tra và theo dõi dữ liệu Hive Cache cục bộ (In-App Debugger).
/// Chỉ khả dụng trong chế độ phát triển (kDebugMode).
class CacheInspectorScreen extends StatefulWidget {
  const CacheInspectorScreen({super.key});

  @override
  State<CacheInspectorScreen> createState() => _CacheInspectorScreenState();
}

class _CacheInspectorScreenState extends State<CacheInspectorScreen> {
  late String _selectedBoxName;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _availableBoxes = [
    HiveBoxNames.workspaces,
    HiveBoxNames.users,
    HiveBoxNames.syncMutations,
    HiveBoxNames.metadata,
    HiveBoxNames.provinces,
    HiveBoxNames.wards,
  ];

  @override
  void initState() {
    super.initState();
    _selectedBoxName = _availableBoxes.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Box<Map>? _getBox(BuildContext context, String boxName) {
    try {
      final cacheBoxes = context.read<CacheBoxes>();
      return cacheBoxes.box(boxName);
    } catch (_) {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<Map>(boxName);
      }
      return null;
    }
  }

  void _showRecordDetail(BuildContext context, dynamic key, dynamic value) {
    String formattedJson;
    try {
      formattedJson = const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      formattedJson = value.toString();
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DefaultColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Key: $key',
                          style: const TextStyle(
                            fontSize: FontSizes.standard,
                            fontWeight: FontWeight.bold,
                            color: DefaultColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Sao chép JSON',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: formattedJson));
                          AppNotification.showSuccess(
                            context,
                            'Đã sao chép JSON vào bộ nhớ tạm',
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        formattedJson,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: FontSizes.small,
                          color: DefaultColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Chỉ khả dụng trong chế độ Debug')),
      );
    }

    final currentBox = _getBox(context, _selectedBoxName);
    final isEncrypted = CacheBoxes.configs[_selectedBoxName] ?? false;

    final allKeys = currentBox?.keys.toList() ?? [];
    final filteredKeys = allKeys.where((k) {
      final keyStr = k.toString().toLowerCase();
      return keyStr.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: DefaultColors.white,
      appBar: AppBar(
        title: const Text(
          'Hive Cache Inspector',
          style: TextStyle(
            color: DefaultColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DefaultColors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: DefaultColors.primary),
            tooltip: 'Tải lại',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            tooltip: 'Xóa toàn bộ box này',
            onPressed: currentBox == null
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận xóa Box'),
                        content: Text(
                          'Bạn có chắc muốn xóa sạch toàn bộ dữ liệu trong box "$_selectedBoxName"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await currentBox.clear();
                      setState(() {});
                      if (context.mounted) {
                        AppNotification.showSuccess(
                          context,
                          'Đã dọn dẹp box $_selectedBoxName',
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Box Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _availableBoxes.map((name) {
                final isSelected = name == _selectedBoxName;
                final box = _getBox(context, name);
                final count = box?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('${name.replaceFirst('cache_', '')} ($count)'),
                    selected: isSelected,
                    selectedColor: DefaultColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : DefaultColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedBoxName = name;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. Header Info & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo key...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  backgroundColor:
                      isEncrypted ? Colors.amber.shade100 : Colors.green.shade100,
                  label: Text(
                    isEncrypted ? 'AES-256' : 'Plain',
                    style: TextStyle(
                      fontSize: FontSizes.small,
                      fontWeight: FontWeight.bold,
                      color:
                          isEncrypted ? Colors.brown : Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số bản ghi: ${allKeys.length}',
                  style: const TextStyle(
                    fontSize: FontSizes.small,
                    color: DefaultColors.textSecondary,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    'Khớp: ${filteredKeys.length}',
                    style: const TextStyle(
                      fontSize: FontSizes.small,
                      color: DefaultColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),

          // 3. Danh sách Keys & Records
          Expanded(
            child: currentBox == null
                ? const Center(child: Text('Box chưa được mở hoặc không tồn tại'))
                : filteredKeys.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có dữ liệu trong box này',
                          style: TextStyle(color: DefaultColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredKeys.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final key = filteredKeys[index];
                          final value = currentBox.get(key);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  DefaultColors.primary.withAlpha(25),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: DefaultColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              key.toString(),
                              style: const TextStyle(
                                fontSize: FontSizes.standard,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              value is Map
                                  ? 'Fields: ${value.keys.take(4).join(", ")}...'
                                  : value.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: FontSizes.small,
                                color: DefaultColors.textSecondary,
                              ),
                            ),
                            trailing:
                                const Icon(Icons.chevron_right, size: 20),
                            onTap: () =>
                                _showRecordDetail(context, key, value),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
