import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/validation/app_validators.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginEvent(
          LoginRequest(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        ),
      );
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  void _onForgotPassword() {
    context.push(AppRoutes.forgotPassword);
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous is AuthLoading,
        listener: (context, state) {
          if (state is Authenticated) {
            AppNotification.showSuccess(context, t('loginSuccess'));
            context.go(AppRoutes.wrapper);
          } else if (state is AuthOtpRequired) {
            context.push(
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
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Image.asset(
                          logoAssetPath,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t('loginTitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.medium,
                          fontWeight: FontWeight.bold,
                          color: DefaultColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('loginSubtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

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
                        validator: FieldRules.email(required: true),
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      AppTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                        validator: FieldRules.loginPassword(),
                      ),
                      const SizedBox(height: 8),

                      // Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            t('forgotPassword'),
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              fontWeight: FontWeight.w500,
                              color: DefaultColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Nút Đăng nhập
                      AppButton(
                        text: t('login'),
                        onPressed: _submitLogin,
                        type: AppButtonType.primary,
                      ),
                      const SizedBox(height: 20),

                      // Link chuyển sang Đăng ký
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t('dontHaveAccount'),
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              color: DefaultColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.register);
                            },
                            child: Text(
                              t('registerNow'),
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
    );
  }
}
