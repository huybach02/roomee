import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_confirm_dialog.dart';
import 'package:roomee/core/widgets/app_empty_state.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/core/widgets/app_popup_menu.dart';
import 'package:roomee/core/widgets/filter/app_filter_drawer.dart';
import 'package:roomee/core/widgets/filter/app_search_app_bar.dart';
import 'package:roomee/core/widgets/filter/filter_field_config.dart';
import 'package:roomee/features/general/data/general_repository.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class ListWorkspaceScreen extends StatefulWidget {
  const ListWorkspaceScreen({super.key});

  @override
  State<ListWorkspaceScreen> createState() => _ListWorkspaceScreenState();
}

class _ListWorkspaceScreenState extends State<ListWorkspaceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  String _searchKeyword = '';
  late Map<String, dynamic> _filters;
  bool _isFilterOpen = false;

  Map<String, dynamic> _getDefaultFilters() {
    final defaults = <String, dynamic>{};
    for (final config in _getFilterConfigs()) {
      if (config.defaultValue != null) {
        defaults[config.key] = config.defaultValue;
      }
    }
    return defaults;
  }

  int get _activeFilterCount {
    int count = 0;
    for (final config in _getFilterConfigs()) {
      final val = _filters[config.key];
      if (val != null && val != config.defaultValue) {
        count++;
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _filters = _getDefaultFilters();
    _scrollController.addListener(_onScroll);
    _loadWorkspaces();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMoreWorkspaces();
    }
  }

  Map<String, dynamic> _buildQueryParams() {
    final queryParams = <String, dynamic>{};
    if (_searchKeyword.isNotEmpty) {
      queryParams['search'] = _searchKeyword;
    }

    final configs = _getFilterConfigs();
    final sortList = <String>[];

    for (final config in configs) {
      final val = _filters[config.key];
      if (val == null || (val is String && val.isEmpty)) continue;

      if (config.isSort) {
        sortList.add(val.toString());
      } else {
        queryParams[config.key] = val;
      }
    }

    if (sortList.isNotEmpty) {
      queryParams['sort'] = sortList.join(',');
    }

    return queryParams;
  }

  void _loadWorkspaces() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    context.read<WorkspaceBloc>().add(
          WorkspaceLoadEvent(queryParameters: _buildQueryParams()),
        );
  }

  void _loadMoreWorkspaces() {
    context.read<WorkspaceBloc>().add(
          WorkspaceLoadMoreEvent(queryParameters: _buildQueryParams()),
        );
  }

  List<FilterFieldConfig> _getFilterConfigs() {
    return [
      FilterFieldConfig.chips(
        key: 'sortByScale',
        title: t('sortByScale'),
        isSort: true,
        options: [
          FilterOption(label: t('sortAreaAsc'), value: 'area:asc'),
          FilterOption(label: t('sortAreaDesc'), value: 'area:desc'),
          FilterOption(label: t('sortRoomsAsc'), value: 'numberOfRooms:asc'),
          FilterOption(label: t('sortRoomsDesc'), value: 'numberOfRooms:desc'),
        ],
      ),
      FilterFieldConfig.chips(
        key: 'sortBy',
        title: t('sortBy'),
        defaultValue: 'createdAt:desc',
        isSort: true,
        options: [
          FilterOption(label: t('sortNewest'), value: 'createdAt:desc'),
          FilterOption(label: t('sortOldest'), value: 'createdAt:asc'),
          FilterOption(label: t('sortNameAZ'), value: 'name:asc'),
          FilterOption(label: t('sortNameZA'), value: 'name:desc'),
        ],
      ),
      FilterFieldConfig.chips(
        key: 'status',
        title: t('fields.status'),
        options: [
          FilterOption(label: t('filterAll'), value: null),
          FilterOption(label: t('workspaceStatusActive'), value: 1),
          FilterOption(label: t('workspaceStatusInactive'), value: 0),
        ],
      ),
      FilterFieldConfig.chips(
        key: 'type',
        title: t('fields.workspaceType'),
        options: [
          FilterOption(label: t('filterAll'), value: null),
          FilterOption(
            label: t('workspaceTypeRentedRoom'),
            value: 'rented_room',
          ),
          FilterOption(
            label: t('workspaceTypeApartment'),
            value: 'apartment_mini_house',
          ),
          FilterOption(
            label: t('workspaceTypeDormitory'),
            value: 'dormitory',
          ),
        ],
      ),
      FilterFieldConfig.dropdown(
        key: 'provinceId',
        title: t('fields.province'),
        loadOptionsAsync: () async {
          final generalState = context.read<GeneralBloc>().state;
          List<ProvinceModel> provinces = [];
          if (generalState is GeneralLoaded &&
              generalState.provinces.isNotEmpty) {
            provinces = generalState.provinces;
          } else {
            try {
              provinces = await GeneralRepository().getProvinces();
            } catch (_) {}
          }
          return [
            FilterOption(label: t('filterAll'), value: null),
            ...provinces.map(
              (p) => FilterOption(label: p.fullName, value: p.id),
            ),
          ];
        },
      ),
    ];
  }

  Future<void> _openCreateWorkspace() async {
    final result = await context.push(AppRoutes.createWorkspace);
    if (result == true && mounted) {
      _loadWorkspaces();
    }
  }

  Future<void> _handleViewDetail(WorkspaceModel ws) async {
    final refreshed = await context.push<bool>(
      AppRoutes.workspaceDetail,
      extra: ws,
    );
    if (refreshed == true && mounted) {
      _loadWorkspaces();
    }
  }

  Future<void> _handleEdit(WorkspaceModel ws) async {
    final updated = await context.push<bool>(
      AppRoutes.editWorkspace,
      extra: ws,
    );
    if (updated == true && mounted) {
      _loadWorkspaces();
    }
  }

  void _handleDelete(WorkspaceModel ws) {
    AppConfirmDialog.show(
      context,
      title: t('deleteConfirmTitle'),
      message: t('deleteWorkspaceConfirm', {'name': ws.name}),
      confirmText: t('actionDelete'),
      isDanger: true,
      onConfirm: () {
        context.read<WorkspaceBloc>().add(WorkspaceDeleteEvent(ws.id));
      },
    );
  }

  void _handleToggleStatus(WorkspaceModel ws, bool value) {
    if (!value) {
      AppConfirmDialog.show(
        context,
        title: t('workspaceStatusConfirmTitle'),
        message: t('workspaceStatusDeactivateConfirm', {'name': ws.name}),
        confirmText: t('actionDeactivate'),
        isDanger: true,
        onConfirm: () {
          context.read<WorkspaceBloc>().add(
                WorkspaceToggleStatusEvent(id: ws.id, status: 0),
              );
        },
      );
    } else {
      context.read<WorkspaceBloc>().add(
            WorkspaceToggleStatusEvent(id: ws.id, status: 1),
          );
    }
  }

  Widget _buildCardMenu(WorkspaceModel ws) {
    return AppPopupMenu<String>(
      items: [
        AppMenuItem(
          value: 'detail',
          title: t('actionViewDetail'),
          icon: Icons.visibility_outlined,
          iconColor: DefaultColors.primary,
          onTap: () => _handleViewDetail(ws),
        ),
        AppMenuItem(
          value: 'edit',
          title: t('actionEdit'),
          icon: Icons.edit_outlined,
          iconColor: DefaultColors.secondary,
          onTap: () => _handleEdit(ws),
        ),
        AppMenuItem(
          value: 'delete',
          title: t('actionDelete'),
          icon: Icons.delete_outline_rounded,
          isDanger: true,
          onTap: () => _handleDelete(ws),
        ),
      ],
    );
  }

  String _getWorkspaceTypeLabel(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.apartmentMiniHouse:
        return t('workspaceTypeApartment');
      case WorkspaceType.dormitory:
        return t('workspaceTypeDormitory');
      case WorkspaceType.rentedRoom:
        return t('workspaceTypeRentedRoom');
    }
  }

  IconData _getWorkspaceTypeIcon(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.apartmentMiniHouse:
        return Icons.apartment_outlined;
      case WorkspaceType.dormitory:
        return Icons.hotel_outlined;
      case WorkspaceType.rentedRoom:
        return Icons.meeting_room_outlined;
    }
  }

  String _formatAddress(WorkspaceModel ws) {
    final parts = <String>[];
    if (ws.address.isNotEmpty) parts.add(ws.address);
    if (ws.ward?.fullName != null && ws.ward!.fullName.isNotEmpty) {
      parts.add(ws.ward!.fullName);
    }
    if (ws.province?.fullName != null && ws.province!.fullName.isNotEmpty) {
      parts.add(ws.province!.fullName);
    }
    return parts.join(', ');
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.domain_disabled_rounded,
      title: t('workspaceEmpty'),
      subtitle: t('workspaceSubtitle'),
    );
  }

  Widget _buildErrorState(String message) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      iconColor: DefaultColors.danger,
      title: message,
      action: SizedBox(
        width: 140,
        child: AppButton(
          text: t('retry'),
          type: AppButtonType.outline,
          onPressed: _loadWorkspaces,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: DefaultColors.primary),
    );
  }

  Widget _buildWorkspaceCard(WorkspaceModel ws) {
    return Container(
      decoration: BoxDecoration(
        color: DefaultColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DefaultColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleViewDetail(ws),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DefaultColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getWorkspaceTypeIcon(ws.type),
                        size: 24,
                        color: DefaultColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ws.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: FontSizes.medium,
                              fontWeight: FontWeight.bold,
                              color: DefaultColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DefaultColors.secondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getWorkspaceTypeLabel(ws.type),
                              style: const TextStyle(
                                fontSize: FontSizes.small - 1,
                                fontWeight: FontWeight.w600,
                                color: DefaultColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: DefaultColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatAddress(ws),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: FontSizes.small,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ws.contactName.isNotEmpty ||
                    ws.contactPhone.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: DefaultColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ws.contactName.isNotEmpty &&
                                  ws.contactPhone.isNotEmpty
                              ? '${ws.contactName} - ${ws.contactPhone}'
                              : (ws.contactName.isNotEmpty
                                  ? ws.contactName
                                  : ws.contactPhone),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: FontSizes.small,
                            color: DefaultColors.textSecondary,
                          ),
                        ),
                      ),
                      if (ws.contactZalo != null &&
                          ws.contactZalo!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DefaultColors.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Zalo',
                            style: TextStyle(
                              fontSize: FontSizes.small - 2,
                              fontWeight: FontWeight.bold,
                              color: DefaultColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 1, color: DefaultColors.border),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.aspect_ratio_rounded,
                          size: 16,
                          color: DefaultColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ws.area} m²',
                          style: const TextStyle(
                            fontSize: FontSizes.small,
                            fontWeight: FontWeight.w600,
                            color: DefaultColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.door_front_door_outlined,
                          size: 16,
                          color: DefaultColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ws.numberOfRooms} phòng',
                          style: const TextStyle(
                            fontSize: FontSizes.small,
                            fontWeight: FontWeight.w600,
                            color: DefaultColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: ws.isActive,
                          activeTrackColor: DefaultColors.primary,
                          activeThumbColor: DefaultColors.white,
                          inactiveThumbColor: DefaultColors.white,
                          inactiveTrackColor: DefaultColors.disabled,
                          trackOutlineColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.transparent,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) => _handleToggleStatus(ws, val),
                        ),
                      ),
                    ),
                    _buildCardMenu(ws),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DefaultColors.white,
      appBar: AppSearchAppBar(
        title: t('workspaceTitle'),
        searchHint: t('searchWorkspaceHint'),
        initialSearch: _searchKeyword,
        activeFilterCount: _activeFilterCount,
        onSearchChanged: (keyword) {
          setState(() {
            _searchKeyword = keyword;
          });
          _loadWorkspaces();
        },
        onFilterTap: () {
          setState(() {
            _isFilterOpen = !_isFilterOpen;
          });
        },
      ),
      floatingActionButton: _isFilterOpen
          ? null
          : FloatingActionButton(
              backgroundColor: DefaultColors.primary,
              foregroundColor: DefaultColors.white,
              tooltip: t('createWorkspace'),
              onPressed: _openCreateWorkspace,
              child: const Icon(Icons.add),
            ),
      body: PopScope(
        canPop: !_isFilterOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _isFilterOpen) {
            setState(() {
              _isFilterOpen = false;
            });
          }
        },
        child: Stack(
          children: [
            BlocConsumer<WorkspaceBloc, WorkspaceState>(
              listener: (context, state) {
                if (state is WorkspaceDeleteSuccess) {
                  AppNotification.showSuccess(
                    context,
                    t('deleteWorkspaceSuccess'),
                  );
                  _loadWorkspaces();
                } else if (state is WorkspaceFailure) {
                  AppNotification.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is WorkspaceLoading) {
                  return _buildLoadingState();
                }

                if (state is WorkspaceFailure) {
                  return _buildErrorState(state.message);
                }

                final workspaces = state is WorkspaceLoaded
                    ? state.workspaces
                    : const <WorkspaceModel>[];

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadWorkspaces();
                  },
                  color: DefaultColors.primary,
                  child: Column(
                    children: [
                      if (workspaces.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t('common.totalRecords', {
                                  'count': (state is WorkspaceLoaded
                                          ? state.total
                                          : workspaces.length)
                                      .toString(),
                                }),
                                style: const TextStyle(
                                  fontSize: FontSizes.small,
                                  fontWeight: FontWeight.w500,
                                  color: DefaultColors.textSecondary,
                                ),
                              ),
                              Text(
                                t('common.showOf', {
                                  'count': workspaces.length.toString(),
                                  'total': (state is WorkspaceLoaded
                                          ? state.total
                                          : workspaces.length)
                                      .toString(),
                                }),
                                style: const TextStyle(
                                  fontSize: FontSizes.small,
                                  fontWeight: FontWeight.w500,
                                  color: DefaultColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: workspaces.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: (state is WorkspaceLoaded &&
                                        !state.hasReachedMax)
                                    ? workspaces.length + 1
                                    : workspaces.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= workspaces.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: DefaultColors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final ws = workspaces[index];
                                  return _buildWorkspaceCard(ws);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
            AppFilterDrawer(
              isOpen: _isFilterOpen,
              onClose: () {
                setState(() {
                  _isFilterOpen = false;
                });
              },
              configs: _getFilterConfigs(),
              initialFilters: _filters,
              onApply: (newFilters) {
                setState(() {
                  _filters = Map<String, dynamic>.from(newFilters);
                });
                _loadWorkspaces();
              },
              onReset: () {
                setState(() {
                  _filters = _getDefaultFilters();
                });
                _loadWorkspaces();
              },
            ),
          ],
        ),
      ),
    );
  }
}
