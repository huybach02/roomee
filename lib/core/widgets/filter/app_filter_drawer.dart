import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/filter/app_filter_section.dart';
import 'package:roomee/core/widgets/filter/filter_field_config.dart';

class AppFilterDrawer extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<FilterFieldConfig> configs;
  final Map<String, dynamic> initialFilters;
  final ValueChanged<Map<String, dynamic>> onApply;
  final VoidCallback? onReset;
  final Duration animationDuration;

  const AppFilterDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.configs,
    this.initialFilters = const {},
    required this.onApply,
    this.onReset,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<AppFilterDrawer> createState() => _AppFilterDrawerState();
}

class _AppFilterDrawerState extends State<AppFilterDrawer> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters);
  }

  @override
  void didUpdateWidget(covariant AppFilterDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _filters = Map<String, dynamic>.from(widget.initialFilters);
    }
  }

  void _handleReset() {
    setState(() {
      _filters.clear();
      for (final cfg in widget.configs) {
        if (cfg.defaultValue != null) {
          _filters[cfg.key] = cfg.defaultValue;
        }
      }
    });
    widget.onReset?.call();
  }

  void _handleApply() {
    widget.onApply(_filters);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final drawerWidth = (mediaQuery.size.width * 0.85).clamp(280.0, 380.0);

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: Stack(
        children: [
          // Semi-transparent backdrop
          AnimatedOpacity(
            opacity: widget.isOpen ? 1.0 : 0.0,
            duration: widget.animationDuration,
            curve: Curves.easeInOut,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Slide-in panel from right
          AnimatedAlign(
            alignment: widget.isOpen
                ? Alignment.centerRight
                : const Alignment(1.3, 0),
            duration: widget.animationDuration,
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: widget.isOpen ? Offset.zero : const Offset(1, 0),
              duration: widget.animationDuration,
              curve: Curves.easeOutCubic,
              child: Container(
                width: drawerWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: DefaultColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: DefaultColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t('filterTitle'),
                              style: const TextStyle(
                                fontSize: FontSizes.standard,
                                fontWeight: FontWeight.bold,
                                color: DefaultColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: DefaultColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: DefaultColors.border),

                    // Scrollable Content
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: widget.configs.length,
                        separatorBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child:
                              Divider(height: 1, color: DefaultColors.border),
                        ),
                        itemBuilder: (context, index) {
                          final config = widget.configs[index];
                          return AppFilterSection(
                            config: config,
                            currentValue: _filters[config.key],
                            onChanged: (val) {
                              setState(() {
                                if (val == null ||
                                    (val is String && val.isEmpty)) {
                                  _filters.remove(config.key);
                                } else {
                                  _filters[config.key] = val;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                    // Footer
                    const Divider(height: 1, color: DefaultColors.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: t('filterReset'),
                              type: AppButtonType.outline,
                              height: 34,
                              fontSize: 13,
                              borderRadius: 8,
                              padding: EdgeInsets.zero,
                              onPressed: _handleReset,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              text: t('filterApply'),
                              type: AppButtonType.primary,
                              height: 34,
                              fontSize: 13,
                              borderRadius: 8,
                              padding: EdgeInsets.zero,
                              onPressed: _handleApply,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
