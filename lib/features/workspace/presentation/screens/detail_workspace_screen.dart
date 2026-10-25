import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/widgets/app_confirm_dialog.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:roomee/utils/constanst.dart';
import 'package:roomee/utils/function_helper.dart';

class DetailWorkspaceScreen extends StatefulWidget {
  final WorkspaceModel workspace;

  const DetailWorkspaceScreen({super.key, required this.workspace});

  @override
  State<DetailWorkspaceScreen> createState() => _DetailWorkspaceScreenState();
}

class _DetailWorkspaceScreenState extends State<DetailWorkspaceScreen> {
  late WorkspaceModel _workspace;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workspace = widget.workspace;
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

  Future<void> _navigateToEdit() async {
    final updated = await context.push<bool>(
      AppRoutes.editWorkspace,
      extra: _workspace,
    );
    if (updated == true && mounted) {
      context.pop(true);
    }
  }

  void _confirmDelete() {
    AppConfirmDialog.show(
      context,
      title: t('deleteConfirmTitle'),
      message: t('deleteWorkspaceConfirm', {'name': _workspace.name}),
      confirmText: t('actionDelete'),
      isDanger: true,
      onConfirm: () {
        context.read<WorkspaceBloc>().add(WorkspaceDeleteEvent(_workspace.id));
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: DefaultColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DefaultColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: FontSizes.standard,
              fontWeight: FontWeight.bold,
              color: DefaultColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: DefaultColors.border),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: DefaultColors.textSecondary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: FontSizes.standard,
                color: DefaultColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: FontSizes.standard,
                fontWeight: FontWeight.w600,
                color: DefaultColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullAddress = [
      if (_workspace.address.isNotEmpty) _workspace.address,
      if (_workspace.ward?.fullName != null) _workspace.ward!.fullName,
      if (_workspace.province?.fullName != null) _workspace.province!.fullName,
    ].join(', ');

    return BlocConsumer<WorkspaceBloc, WorkspaceState>(
      listener: (context, state) {
        if (state is WorkspaceLoading) {
          setState(() {
            _isLoading = true;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }

        if (state is WorkspaceDeleteSuccess && state.id == _workspace.id) {
          AppNotification.showSuccess(context, t('deleteWorkspaceSuccess'));
          context.pop(true);
        } else if (state is WorkspaceFailure) {
          AppNotification.showError(context, state.message);
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: _isLoading,
          child: Scaffold(
            backgroundColor: DefaultColors.background,
            appBar: AppBar(
              backgroundColor: DefaultColors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: DefaultColors.primary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                t('detailWorkspaceTitle'),
                style: const TextStyle(
                  color: DefaultColors.primary,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: DefaultColors.primary,
                  ),
                  tooltip: t('actionEdit'),
                  onPressed: _navigateToEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: DefaultColors.danger,
                  ),
                  tooltip: t('actionDelete'),
                  onPressed: _confirmDelete,
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Header Card
                    Container(
                      padding: const EdgeInsets.all(20.0),
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
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: DefaultColors.primary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getWorkspaceTypeIcon(_workspace.type),
                              size: 32,
                              color: DefaultColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _workspace.name,
                                  style: const TextStyle(
                                    fontSize: FontSizes.large,
                                    fontWeight: FontWeight.bold,
                                    color: DefaultColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            DefaultColors.secondary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getWorkspaceTypeLabel(_workspace.type),
                                        style: const TextStyle(
                                          fontSize: FontSizes.small,
                                          fontWeight: FontWeight.bold,
                                          color: DefaultColors.secondary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_workspace.isActive
                                                ? DefaultColors.success
                                                : DefaultColors.danger)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _workspace.isActive
                                            ? t('workspaceStatusActive')
                                            : t('workspaceStatusInactive'),
                                        style: TextStyle(
                                          fontSize: FontSizes.small,
                                          fontWeight: FontWeight.bold,
                                          color: _workspace.isActive
                                              ? DefaultColors.success
                                              : DefaultColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Thông tin cơ bản
                    _buildSection(
                      title: t('basicInfo'),
                      children: [
                        _buildInfoRow(
                          t('fields.workspaceArea'),
                          '${_workspace.area} m²',
                          icon: Icons.aspect_ratio_rounded,
                        ),
                        _buildInfoRow(
                          t('fields.numberOfRooms'),
                          '${_workspace.numberOfRooms} phòng',
                          icon: Icons.door_front_door_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Địa điểm & Vị trí
                    _buildSection(
                      title: t('locationInfo'),
                      children: [
                        _buildInfoRow(
                          t('fields.workspaceAddress'),
                          _workspace.address,
                          icon: Icons.location_on_outlined,
                        ),
                        _buildInfoRow(
                          t('fields.ward'),
                          _workspace.ward?.fullName ?? '-',
                          icon: Icons.map_outlined,
                        ),
                        _buildInfoRow(
                          t('fields.province'),
                          _workspace.province?.fullName ?? '-',
                          icon: Icons.location_city_outlined,
                        ),
                        _buildInfoRow(
                          'Địa chỉ đầy đủ',
                          fullAddress,
                          icon: Icons.signpost_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Thông tin liên hệ
                    _buildSection(
                      title: t('contactInfo'),
                      children: [
                        _buildInfoRow(
                          t('fields.contactName'),
                          _workspace.contactName,
                          icon: Icons.person_outline_rounded,
                        ),
                        _buildInfoRow(
                          t('fields.contactPhone'),
                          _workspace.contactPhone,
                          icon: Icons.phone_outlined,
                        ),
                        if (_workspace.contactZalo != null &&
                            _workspace.contactZalo!.isNotEmpty)
                          _buildInfoRow(
                            t('fields.contactZalo'),
                            _workspace.contactZalo!,
                            icon: Icons.chat_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Mô tả / Ghi chú
                    if (_workspace.description != null &&
                        _workspace.description!.isNotEmpty) ...[
                      _buildSection(
                        title: t('fields.workspaceDescription'),
                        children: [
                          Text(
                            _workspace.description!,
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              height: 1.5,
                              color: DefaultColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section 5: Thông tin hệ thống
                    _buildSection(
                      title: t('systemInfo'),
                      children: [
                        _buildInfoRow(
                          t('fields.status'),
                          _workspace.isActive
                              ? t('workspaceStatusActive')
                              : t('workspaceStatusInactive'),
                          icon: Icons.toggle_on_outlined,
                        ),
                        _buildInfoRow(
                          t('createdAtLabel'),
                          FunctionHelper.formatDateTime(_workspace.createdAt),
                          icon: Icons.calendar_today_outlined,
                        ),
                        _buildInfoRow(
                          t('updatedAtLabel'),
                          FunctionHelper.formatDateTime(_workspace.updatedAt),
                          icon: Icons.history_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
