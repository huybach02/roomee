import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_card_select.dart';
import 'package:roomee/core/widgets/app_date_picker_field.dart';
import 'package:roomee/core/widgets/app_segmented_select.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  DateTime? _selectedDate;
  Gender _selectedGender = Gender.male;
  UserRole _selectedRole = UserRole.tenant;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('registerTitle')),
          backgroundColor: DefaultColors.primary,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: DefaultColors.primary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  labelText: t('accountType'),
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
                  labelText: t('fullName'),
                  hintText: t('fullNameHint'),
                  prefixIcon: const Icon(Icons.person_outline, color: DefaultColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('fieldRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                AppTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  labelText: t('email'),
                  hintText: t('emailHint'),
                  prefixIcon: const Icon(Icons.email_outlined, color: DefaultColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('fieldRequired');
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return t('invalidEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Số điện thoại
                AppTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  labelText: t('phoneNumber'),
                  hintText: t('phoneNumberHint'),
                  prefixIcon: const Icon(Icons.phone_outlined, color: DefaultColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('fieldRequired');
                    }
                    final phoneRegex = RegExp(r'^[0-9]{9,11}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return t('invalidPhone');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mật khẩu
                AppTextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  labelText: t('password'),
                  hintText: t('passwordHint'),
                  prefixIcon: const Icon(Icons.lock_outline, color: DefaultColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: DefaultColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('fieldRequired');
                    }
                    if (value.length < 6) {
                      return t('passwordTooShort');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Xác nhận mật khẩu
                AppTextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  labelText: t('confirmPassword'),
                  hintText: t('confirmPasswordHint'),
                  prefixIcon: const Icon(Icons.lock_outline, color: DefaultColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: DefaultColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('fieldRequired');
                    }
                    if (value != _passwordController.text) {
                      return t('passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Địa chỉ
                AppTextField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  labelText: t('address'),
                  hintText: t('addressHint'),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: DefaultColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('fieldRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Ngày sinh
                AppDatePickerField(
                  controller: _dobController,
                  selectedDate: _selectedDate,
                  lastDate: DateTime.now(),
                  initialDate: DateTime(DateTime.now().year - 20),
                  labelText: t('dateOfBirth'),
                  hintText: t('dateOfBirthHint'),
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('fieldRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Giới tính
                AppSegmentedSelect<Gender>(
                  labelText: t('gender'),
                  selected: _selectedGender,
                  options: [
                    AppSelectOption(value: Gender.male, label: t('genderMale')),
                    AppSelectOption(value: Gender.female, label: t('genderFemale')),
                    AppSelectOption(value: Gender.other, label: t('genderOther')),
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
  }


}
