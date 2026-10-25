import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';

class AppSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final String? searchHint;
  final String? initialSearch;
  final List<Widget>? extraActions;
  final Duration debounceDuration;

  const AppSearchAppBar({
    super.key,
    required this.title,
    this.leading,
    this.onSearchChanged,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.searchHint,
    this.initialSearch,
    this.extraActions,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppSearchAppBar> createState() => _AppSearchAppBarState();
}

class _AppSearchAppBarState extends State<AppSearchAppBar> {
  bool _isSearching = false;
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    if (_searchController.text.isNotEmpty) {
      _isSearching = true;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _stopSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearchChanged?.call('');
  }

  void _onTextChanged(String value) {
    setState(() {}); // cập nhật nút Clear (X)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearchChanged?.call(value.trim());
    });
  }

  Widget _buildFilterButton() {
    if (widget.onFilterTap == null) return const SizedBox.shrink();

    final filterButton = IconButton(
      icon: const Icon(
        Icons.tune_rounded,
        color: DefaultColors.primary,
      ),
      tooltip: t('filterTitle'),
      onPressed: widget.onFilterTap,
    );

    if (widget.activeFilterCount <= 0) {
      return filterButton;
    }

    return Badge(
      label: Text(
        '${widget.activeFilterCount}',
        style: const TextStyle(
          color: DefaultColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: DefaultColors.secondary,
      offset: const Offset(-6, 6),
      child: filterButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: DefaultColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: DefaultColors.primary,
          ),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: FontSizes.standard,
            color: DefaultColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.searchHint ?? t('searchHintGeneric'),
            hintStyle: const TextStyle(
              fontSize: FontSizes.standard,
              color: DefaultColors.textSecondary,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: _onTextChanged,
          onSubmitted: (val) {
            _debounceTimer?.cancel();
            widget.onSearchChanged?.call(val.trim());
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                color: DefaultColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                _searchController.clear();
                _onTextChanged('');
              },
            ),
          _buildFilterButton(),
          const SizedBox(width: 4),
        ],
      );
    }

    return AppBar(
      backgroundColor: DefaultColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: widget.leading != null,
      leading: widget.leading,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: DefaultColors.primary,
          fontSize: FontSizes.medium,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: DefaultColors.primary,
          ),
          tooltip: t('searchHintGeneric'),
          onPressed: _startSearch,
        ),
        _buildFilterButton(),
        if (widget.extraActions != null) ...widget.extraActions!,
        const SizedBox(width: 4),
      ],
    );
  }
}
