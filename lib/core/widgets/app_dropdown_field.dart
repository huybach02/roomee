import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/widgets/app_text_field.dart';

class AppDropdownOption<T> {
  final T value;
  final String label;

  const AppDropdownOption({required this.value, required this.label});
}

class AppDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T>? onChanged;
  final VoidCallback? onTap;
  final String? labelText;
  final String? hintText;
  final String? searchHint;
  final String? emptyText;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final bool enabled;
  final bool isLoading;

  const AppDropdownField({
    super.key,
    this.value,
    required this.options,
    this.onChanged,
    this.onTap,
    this.labelText,
    this.hintText,
    this.searchHint,
    this.emptyText,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value || widget.options != oldWidget.options) {
      _syncText(isPostFrame: true);
    }
  }

  void _syncText({bool isPostFrame = false}) {
    final matches = widget.options.where((o) => o.value == widget.value);
    final newText = matches.isEmpty ? '' : matches.first.label;
    if (_controller.text != newText) {
      if (isPostFrame) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.text = newText;
          }
        });
      } else {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    if (!widget.enabled) return;

    widget.onTap?.call();

    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DefaultColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _DropdownSheet<T>(
        options: widget.options,
        searchHint: widget.searchHint ?? '',
        emptyText: widget.emptyText ?? '',
        isLoading: widget.isLoading,
      ),
    );

    if (selected != null) {
      final matches = widget.options.where((o) => o.value == selected);
      _controller.text = matches.isEmpty ? '' : matches.first.label;
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openSheet,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DefaultColors.primary,
                ),
              ),
            )
          : const Icon(
              Icons.arrow_drop_down,
              color: DefaultColors.textSecondary,
            ),
      validator: widget.validator,
    );
  }
}

class _DropdownSheet<T> extends StatefulWidget {
  final List<AppDropdownOption<T>> options;
  final String searchHint;
  final String emptyText;
  final bool isLoading;

  const _DropdownSheet({
    required this.options,
    required this.searchHint,
    required this.emptyText,
    this.isLoading = false,
  });

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<AppDropdownOption<T>> _filtered = widget.options;

  @override
  void didUpdateWidget(covariant _DropdownSheet<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _onSearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final keyword = query.trim().toLowerCase();
    setState(() {
      _filtered = keyword.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.label.toLowerCase().contains(keyword))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DefaultColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _searchController,
                hintText: widget.searchHint,
                prefixIcon: const Icon(
                  Icons.search,
                  color: DefaultColors.textSecondary,
                ),
                onChanged: _onSearch,
              ),
            ),
            Expanded(
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DefaultColors.primary,
                      ),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyText,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        return ListTile(
                          title: Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              color: DefaultColors.textPrimary,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
