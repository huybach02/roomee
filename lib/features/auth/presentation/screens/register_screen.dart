import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/validation/app_validators.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_card_select.dart';
import 'package:roomee/core/widgets/app_date_picker_field.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/core/widgets/app_segmented_select.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  DateTime? _selectedDate;
  Gender _selectedGender = Gender.male;
  UserRole _selectedRole = UserRole.tenant;
  ProvinceModel? _selectedProvince;
  WardModel? _selectedWard;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    context.read<GeneralBloc>().add(const GeneralProvincesLoadEvent());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterEvent(
          RegisterRequest(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phoneNumber: _phoneController.text.trim(),
            gender: _selectedGender,
            role: _selectedRole,
            provinceId: _selectedProvince?.id,
            wardId: _selectedWard?.id,
            birthday: _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.white,
      appBar: AppBar(
        backgroundColor: DefaultColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DefaultColors.primary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
      body: BlocListener<GeneralBloc, GeneralState>(
        listener: (context, generalState) {
          final message = generalState is GeneralFailure
              ? generalState.message
              : generalState is GeneralLoaded
              ? generalState.error
              : null;
          if (message != null) {
            AppNotification.showError(context, message);
          }
        },
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous is AuthLoading,
          listener: (context, state) {
            if (state is AuthOtpRequired) {
              AppNotification.showSuccess(
                context,
                t('registerSuccessMessage'),
              );
              context.pushReplacement(
                AppRoutes.otp,
                extra: {
                  'destination': state.destination,
                  'purpose': state.purpose,
                },
              );
            } else if (state is AuthFailure) {
              AppNotification.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return LoadingOverlay(
              isLoading: isLoading,
              child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          logoAssetPath,
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('registerTitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.medium,
                          fontWeight: FontWeight.bold,
                          color: DefaultColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('registerSubtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Chọn loại tài khoản
                      AppCardSelect<UserRole>(
                        labelText: t('fields.accountType'),
                        selected: _selectedRole,
                        options: [
                          AppCardOption(
                            value: UserRole.tenant,
                            title: t('roleTenant'),
                            icon: Icons.person_outline,
                          ),
                          AppCardOption(
                            value: UserRole.landlord,
                            title: t('roleLandlord'),
                            icon: Icons.apartment_outlined,
                          ),
                        ],
                        onChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Họ và tên
                      AppTextField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.fullName'),
                        hintText: t('fields.fullNameHint'),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: FieldRules.fullName(),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.email'),
                        hintText: t('fields.emailHint'),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: FieldRules.email(),
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại
                      AppTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.phoneNumber'),
                        hintText: t('fields.phoneNumberHint'),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: DefaultColors.textSecondary,
                        ),
                        validator: FieldRules.phone(required: true),
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      AppTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.password'),
                        hintText: t('fields.passwordHint'),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: DefaultColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: DefaultColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: FieldRules.password(),
                      ),
                      const SizedBox(height: 16),

                      // Xác nhận mật khẩu
                      AppTextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        labelText: t('fields.confirmPassword'),
                        hintText: t('fields.confirmPasswordHint'),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: DefaultColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: DefaultColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: FieldRules.confirmPassword(
                          () => _passwordController.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tỉnh/Thành phố & Phường/Xã
                      BlocBuilder<GeneralBloc, GeneralState>(
                        builder: (context, generalState) {
                          final generalLoaded = generalState is GeneralLoaded
                              ? generalState
                              : const GeneralLoaded();
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
                                value: _selectedProvince?.id,
                                options: provinceOptions,
                                isLoading: generalLoaded.isLoadingProvinces,
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
                                prefixIcon: const Icon(
                                  Icons.location_city_outlined,
                                  color: DefaultColors.textSecondary,
                                ),
                                validator: Validators.required(),
                                onChanged: (id) {
                                  final province = generalLoaded.provinces
                                      .firstWhere((p) => p.id == id);
                                  setState(() {
                                    _selectedProvince = province;
                                    _selectedWard = null;
                                  });
                                  context.read<GeneralBloc>().add(
                                    GeneralWardsLoadEvent(id),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              AppDropdownField<int>(
                                value: _selectedWard?.id,
                                options: wardOptions,
                                enabled: _selectedProvince != null,
                                isLoading: generalLoaded.isLoadingWards,
                                onTap: () {
                                  if (_selectedProvince != null &&
                                      wardOptions.isEmpty) {
                                    context.read<GeneralBloc>().add(
                                      GeneralWardsLoadEvent(
                                        _selectedProvince!.id,
                                      ),
                                    );
                                  }
                                },
                                labelText: t('fields.ward'),
                                hintText: t('fields.wardHint'),
                                searchHint: t('fields.searchHint'),
                                emptyText: t('fields.noOptions'),
                                prefixIcon: const Icon(
                                  Icons.map_outlined,
                                  color: DefaultColors.textSecondary,
                                ),
                                validator: Validators.required(),
                                onChanged: (id) {
                                  setState(() {
                                    _selectedWard = generalLoaded.wards
                                        .firstWhere((w) => w.id == id);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ngày sinh
                      AppDatePickerField(
                        controller: _dobController,
                        selectedDate: _selectedDate,
                        lastDate: DateTime.now(),
                        initialDate: DateTime(DateTime.now().year - 20),
                        labelText: t('fields.dateOfBirth'),
                        hintText: t('fields.dateOfBirthHint'),
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        validator: Validators.required(),
                      ),
                      const SizedBox(height: 16),

                      // Giới tính
                      AppSegmentedSelect<Gender>(
                        labelText: t('fields.gender'),
                        selected: _selectedGender,
                        options: [
                          AppSelectOption(
                            value: Gender.male,
                            label: t('genderMale'),
                          ),
                          AppSelectOption(
                            value: Gender.female,
                            label: t('genderFemale'),
                          ),
                          AppSelectOption(
                            value: Gender.other,
                            label: t('genderOther'),
                          ),
                        ],
                        onChanged: (gender) {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                      ),
                      const SizedBox(height: 28),

                      // Nút Đăng ký
                      AppButton(
                        text: t('register'),
                        onPressed: _submitForm,
                        type: AppButtonType.primary,
                      ),
                      const SizedBox(height: 16),

                      // Link chuyển sang Đăng nhập
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t('alreadyHaveAccount'),
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              color: DefaultColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.login);
                            },
                            child: Text(
                              t('loginNow'),
                              style: const TextStyle(
                                fontSize: FontSizes.standard,
                                fontWeight: FontWeight.bold,
                                color: DefaultColors.primary,
                              ),
                            ),
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
        ),
      ),
    );
  }
}
