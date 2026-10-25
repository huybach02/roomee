import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/validation/app_validators.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_card_select.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class WorkspaceFormScreen extends StatefulWidget {
  final WorkspaceModel? workspace;

  const WorkspaceFormScreen({super.key, this.workspace});

  bool get isEditMode => workspace != null;

  @override
  State<WorkspaceFormScreen> createState() => _WorkspaceFormScreenState();
}

class _WorkspaceFormScreenState extends State<WorkspaceFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _numberOfRoomsController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactZaloController;

  late WorkspaceType _selectedType;
  ProvinceModel? _selectedProvince;
  WardModel? _selectedWard;
  bool _isLoading = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final ws = widget.workspace;

    _nameController = TextEditingController(text: ws?.name ?? '');
    _areaController = TextEditingController(
      text: ws != null ? ws.area.toString() : '',
    );
    _numberOfRoomsController = TextEditingController(
      text: ws != null ? ws.numberOfRooms.toString() : '',
    );
    _addressController = TextEditingController(text: ws?.address ?? '');
    _descriptionController = TextEditingController(text: ws?.description ?? '');
    _contactNameController = TextEditingController(text: ws?.contactName ?? '');
    _contactPhoneController = TextEditingController(
      text: ws?.contactPhone ?? '',
    );
    _contactZaloController = TextEditingController(text: ws?.contactZalo ?? '');
    _selectedType = ws?.type ?? WorkspaceType.rentedRoom;
    _selectedProvince = ws?.province;
    _selectedWard = ws?.ward;

    context.read<GeneralBloc>().add(const GeneralProvincesLoadEvent());
    if (ws?.provinceId != null && ws!.provinceId > 0) {
      context.read<GeneralBloc>().add(GeneralWardsLoadEvent(ws.provinceId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _numberOfRoomsController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactZaloController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final provinceId = _selectedProvince?.id ?? widget.workspace?.provinceId;
    final wardId = _selectedWard?.id ?? widget.workspace?.wardId;

    if (provinceId == null || wardId == null) {
      return;
    }

    final area = double.tryParse(_areaController.text.trim()) ?? 0.0;
    final numberOfRooms =
        int.tryParse(_numberOfRoomsController.text.trim()) ?? 0;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _selectedType.value,
      'area': area,
      'numberOfRooms': numberOfRooms,
      'provinceId': provinceId,
      'wardId': wardId,
      'address': _addressController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      'contactName': _contactNameController.text.trim(),
      'contactPhone': _contactPhoneController.text.trim(),
      if (_contactZaloController.text.trim().isNotEmpty)
        'contactZalo': _contactZaloController.text.trim(),
    };

    if (widget.isEditMode) {
      context.read<WorkspaceBloc>().add(
        WorkspaceUpdateEvent(widget.workspace!.id, data),
      );
    } else {
      context.read<WorkspaceBloc>().add(WorkspaceCreateEvent(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditMode
        ? t('editWorkspaceTitle')
        : t('createWorkspaceTitle');
    final subtitle = widget.isEditMode
        ? t('editWorkspaceSubtitle')
        : t('createWorkspaceSubtitle');
    final buttonText = widget.isEditMode
        ? t('common.saveChanges')
        : t('common.createButton');

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

        if (state is WorkspaceCreateSuccess) {
          AppNotification.showSuccess(context, t('common.createdSuccess'));
          context.pop(true);
        } else if (state is WorkspaceUpdateSuccess) {
          AppNotification.showSuccess(context, t('common.editedSuccess'));
          context.pop(true);
        } else if (state is WorkspaceFailure) {
          AppNotification.showError(context, state.message);
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: _isLoading,
          child: Scaffold(
            backgroundColor: DefaultColors.white,
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
                title,
                style: const TextStyle(
                  color: DefaultColors.primary,
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tên nhà trọ
                      AppTextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.workspaceName'),
                        hintText: t('fields.workspaceNameHint'),
                        prefixIcon: const Icon(
                          Icons.domain_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: Validators.required(),
                      ),
                      const SizedBox(height: 20),

                      // Loại hình bất động sản
                      AppCardSelect<WorkspaceType>(
                        selected: _selectedType,
                        labelText: t('fields.workspaceType'),
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val;
                          });
                        },
                        options: [
                          AppCardOption(
                            value: WorkspaceType.rentedRoom,
                            title: t('workspaceTypeRentedRoom'),
                            subtitle: t('workspaceTypeRentedRoomDesc'),
                            icon: Icons.meeting_room_outlined,
                          ),
                          AppCardOption(
                            value: WorkspaceType.apartmentMiniHouse,
                            title: t('workspaceTypeApartment'),
                            subtitle: t('workspaceTypeApartmentDesc'),
                            icon: Icons.apartment_outlined,
                          ),
                          AppCardOption(
                            value: WorkspaceType.dormitory,
                            title: t('workspaceTypeDormitory'),
                            subtitle: t('workspaceTypeDormitoryDesc'),
                            icon: Icons.hotel_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Diện tích & Số phòng (cùng hàng)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _areaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              labelText: t('fields.workspaceArea'),
                              hintText: t('fields.workspaceAreaHint'),
                              prefixIcon: const Icon(
                                Icons.square_foot_outlined,
                                color: DefaultColors.textSecondary,
                              ),
                              validator: Validators.required(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _numberOfRoomsController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              labelText: t('fields.numberOfRooms'),
                              hintText: t('fields.numberOfRoomsHint'),
                              prefixIcon: const Icon(
                                Icons.format_list_numbered,
                                color: DefaultColors.textSecondary,
                              ),
                              validator: Validators.required(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tỉnh / Thành phố & Phường / Xã
                      BlocBuilder<GeneralBloc, GeneralState>(
                        builder: (context, generalState) {
                          final generalLoaded = generalState is GeneralLoaded
                              ? generalState
                              : const GeneralLoaded();

                          final targetProvinceId =
                              _selectedProvince?.id ??
                              widget.workspace?.provinceId;
                          final targetWardId =
                              _selectedWard?.id ?? widget.workspace?.wardId;

                          // Tự động đồng bộ selected province nếu đã có từ trước
                          if (generalLoaded.provinces.isNotEmpty &&
                              targetProvinceId != null) {
                            final match = generalLoaded.provinces
                                .where((p) => p.id == targetProvinceId)
                                .firstOrNull;
                            if (match != null) {
                              _selectedProvince = match;
                            }
                          }

                          // Tự động đồng bộ selected ward nếu đã có từ trước
                          if (generalLoaded.wards.isNotEmpty &&
                              targetWardId != null) {
                            final match = generalLoaded.wards
                                .where((w) => w.id == targetWardId)
                                .firstOrNull;
                            if (match != null) {
                              _selectedWard = match;
                            }
                          }

                          final provinceOptions = generalLoaded.provinces
                              .map(
                                (p) => AppDropdownOption<int>(
                                  value: p.id,
                                  label: p.fullName,
                                ),
                              )
                              .toList();
                          final wardOptions = generalLoaded.wards
                              .map(
                                (w) => AppDropdownOption<int>(
                                  value: w.id,
                                  label: w.fullName,
                                ),
                              )
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppDropdownField<int>(
                                value:
                                    _selectedProvince?.id ?? targetProvinceId,
                                initialLabel:
                                    _selectedProvince?.fullName ??
                                    widget.workspace?.province?.fullName,
                                options: provinceOptions,
                                isLoading: generalLoaded.isLoadingProvinces,
                                prefixIcon: const Icon(
                                  Icons.location_city_outlined,
                                  color: DefaultColors.textSecondary,
                                ),
                                onTap: () {
                                  if (provinceOptions.isEmpty) {
                                    context.read<GeneralBloc>().add(
                                      const GeneralProvincesLoadEvent(),
                                    );
                                  }
                                },
                                labelText: t('fields.province'),
                                hintText: t('fields.provinceHint'),
                                searchHint: t('fields.searchHint'),
                                emptyText: t('fields.noOptions'),
                                validator: Validators.required(),
                                onChanged: (provinceId) {
                                  final prov = generalLoaded.provinces
                                      .where((p) => p.id == provinceId)
                                      .firstOrNull;
                                  if (prov != null) {
                                    setState(() {
                                      _selectedProvince = prov;
                                      _selectedWard = null;
                                    });
                                    context.read<GeneralBloc>().add(
                                      GeneralWardsLoadEvent(provinceId),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              AppDropdownField<int>(
                                value: _selectedWard?.id ?? targetWardId,
                                initialLabel:
                                    _selectedWard?.fullName ??
                                    widget.workspace?.ward?.fullName,
                                options: wardOptions,
                                enabled:
                                    (_selectedProvince?.id ??
                                        targetProvinceId) !=
                                    null,
                                isLoading: generalLoaded.isLoadingWards,
                                prefixIcon: const Icon(
                                  Icons.map_outlined,
                                  color: DefaultColors.textSecondary,
                                ),
                                labelText: t('fields.ward'),
                                hintText: t('fields.wardHint'),
                                searchHint: t('fields.searchHint'),
                                emptyText: t('fields.noOptions'),
                                validator: Validators.required(),
                                onChanged: (wardId) {
                                  final ward = generalLoaded.wards
                                      .where((w) => w.id == wardId)
                                      .firstOrNull;
                                  if (ward != null) {
                                    setState(() {
                                      _selectedWard = ward;
                                    });
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Địa chỉ chi tiết
                      AppTextField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.workspaceAddress'),
                        hintText: t('fields.workspaceAddressHint'),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: Validators.required(),
                      ),
                      const SizedBox(height: 20),

                      // Mô tả (không bắt buộc)
                      AppTextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.workspaceDescription'),
                        hintText: t('fields.workspaceDescriptionHint'),
                        prefixIcon: const Icon(
                          Icons.notes_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tên người liên hệ
                      AppTextField(
                        controller: _contactNameController,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.contactName'),
                        hintText: t('fields.contactNameHint'),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: Validators.required(),
                      ),
                      const SizedBox(height: 20),

                      // Số điện thoại liên hệ
                      AppTextField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.contactPhone'),
                        hintText: t('fields.contactPhoneHint'),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: FieldRules.phone(required: true),
                      ),
                      const SizedBox(height: 20),

                      // Số Zalo liên hệ (không bắt buộc)
                      AppTextField(
                        controller: _contactZaloController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        labelText: t('fields.contactZalo'),
                        hintText: t('fields.contactZaloHint'),
                        prefixIcon: const Icon(
                          Icons.chat_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: FieldRules.phone(required: false),
                      ),
                      const SizedBox(height: 32),

                      // Nút Submit
                      AppButton(
                        text: buttonText,
                        type: AppButtonType.primary,
                        onPressed: _submitForm,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
