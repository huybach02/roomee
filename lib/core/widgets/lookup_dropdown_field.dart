import 'package:flutter/material.dart';
import 'package:roomee/core/offline/repository/lookup_repository.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';

class LookupDropdownField extends StatefulWidget {
  final ILookupRepository lookupRepository;
  final String accountId;

  /// Tên module đồng bộ (số nhiều), ví dụ: `workspaces`, `rooms`.
  final String module;

  /// Lọc lựa chọn con theo bản ghi cha (ví dụ: phòng theo workspace).
  final String? parentId;

  /// Giá trị đang chọn (id dạng chuỗi).
  final String? value;
  final ValueChanged<String>? onChanged;

  final String? labelText;
  final String? hintText;
  final String? searchHint;
  final String? emptyText;

  final String? initialLabel;

  final Widget? prefixIcon;
  final bool enabled;
  final bool dense;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  const LookupDropdownField({
    super.key,
    required this.lookupRepository,
    required this.accountId,
    required this.module,
    this.parentId,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.searchHint,
    this.emptyText,
    this.initialLabel,
    this.prefixIcon,
    this.enabled = true,
    this.dense = false,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<LookupDropdownField> createState() => _LookupDropdownFieldState();
}

class _LookupDropdownFieldState extends State<LookupDropdownField> {
  List<AppDropdownOption<String>> _options = const [];
  bool _isLoading = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void didUpdateWidget(covariant LookupDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.module != oldWidget.module ||
        widget.accountId != oldWidget.accountId ||
        widget.parentId != oldWidget.parentId ||
        widget.lookupRepository != oldWidget.lookupRepository) {
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    final seq = ++_loadSeq;
    setState(() {
      _isLoading = true;
      _options = const [];
    });

    try {
      final raw = await widget.lookupRepository.getOptions(
        accountId: widget.accountId,
        module: widget.module,
        parentId: widget.parentId,
      );
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _options = raw
            .map(
              (o) => AppDropdownOption<String>(
                value: o.id.toString(),
                label: o.label,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      debugPrint('[LookupDropdownField] Load options error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      value: widget.value,
      initialLabel: widget.initialLabel,
      options: _options,
      isLoading: _isLoading,
      enabled: widget.enabled && !_isLoading,
      onChanged: widget.onChanged,
      labelText: widget.labelText,
      hintText: widget.hintText,
      searchHint: widget.searchHint,
      emptyText: widget.emptyText,
      prefixIcon: widget.prefixIcon,
      dense: widget.dense,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
    );
  }
}
