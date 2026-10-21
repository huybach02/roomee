import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';

/// Màn hình Home dành cho Người thuê trọ CHƯA có hợp đồng thuê trọ (hasContract = false).
/// Sau này sẽ là màn hình tìm kiếm phòng trọ, danh sách tin đăng cho thuê...
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.white,
      appBar: AppBar(
        backgroundColor: DefaultColors.white,
        elevation: 0,
        title: Text(
          t('homeTitle'),
          style: const TextStyle(
            color: DefaultColors.primary,
            fontSize: FontSizes.medium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go(AppRoutes.welcome);
          }
        },
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          final displayName = user?.fullName?.isNotEmpty == true
              ? user!.fullName!
              : (user?.email ?? 'User');

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 64,
                      color: DefaultColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('welcomeUser', {'name': displayName}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: FontSizes.medium,
                        fontWeight: FontWeight.bold,
                        color: DefaultColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('homeExploreRooms'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: FontSizes.standard,
                        color: DefaultColors.textSecondary,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        user!.email,
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          color: DefaultColors.textSecondary,
                        ),
                      ),
                    ],
                    if (user?.role != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${t('userRole')}: ',
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              color: DefaultColors.textSecondary,
                            ),
                          ),
                          Text(
                            user!.role.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: FontSizes.standard,
                              fontWeight: FontWeight.bold,
                              color: DefaultColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    AppButton(
                      text: t('logout'),
                      type: AppButtonType.outline,
                      onPressed: () {
                        context.read<AuthBloc>().add(const AuthLogoutEvent());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
