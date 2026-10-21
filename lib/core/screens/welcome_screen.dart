import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onLoginPressed;

  const WelcomeScreen({super.key, this.onRegisterPressed, this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    AuthBloc? authBloc;
    try {
      authBloc = context.read<AuthBloc>();
    } catch (_) {}

    final scaffold = Scaffold(
      backgroundColor: DefaultColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _buildLanguageToggle(context),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        logoAssetPath,
                        width: 260,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t('welcomeTitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.medium,
                          fontWeight: FontWeight.bold,
                          color: DefaultColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('welcomeSubtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: t('register'),
                    onPressed: onRegisterPressed ?? () => context.push(AppRoutes.register),
                    type: AppButtonType.primary,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: t('login'),
                    onPressed: onLoginPressed ?? () => context.push(AppRoutes.login),
                    type: AppButtonType.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (authBloc != null) {
      return BlocListener<AuthBloc, AuthState>(
        bloc: authBloc,
        listener: (context, state) {
          if (state is Authenticated) {
            context.go(AppRoutes.wrapper);
          }
        },
        child: scaffold,
      );
    }

    return scaffold;
  }

  Widget _buildLanguageToggle(BuildContext context) {
    final currentLocale = context.watch<LocaleCubit>().state;
    final isVi = currentLocale.languageCode == 'vi';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DefaultColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DefaultColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocaleOption(
            text: 'VI',
            isSelected: isVi,
            onTap: () => context.read<LocaleCubit>().setLocale(const Locale('vi')),
          ),
          const SizedBox(width: 4),
          _buildLocaleOption(
            text: 'EN',
            isSelected: !isVi,
            onTap: () => context.read<LocaleCubit>().setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }

  Widget _buildLocaleOption({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DefaultColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: FontSizes.small,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? DefaultColors.textOnPrimary : DefaultColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
