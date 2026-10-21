import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

/// Màn hình Dashboard dành cho Chủ trọ / Nhân viên quản lý (role = landlord | staff | admin).
/// Sau này sẽ là phần dashboard quản lý tòa nhà, phòng trọ, danh sách khách thuê, thu chi...
class LandlordScreen extends StatefulWidget {
  const LandlordScreen({super.key});

  @override
  State<LandlordScreen> createState() => _LandlordScreenState();
}

class _LandlordScreenState extends State<LandlordScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.white,
      appBar: AppBar(
        backgroundColor: DefaultColors.white,
        elevation: 0,
        title: Text(
          t('landlordDashboardTitle'),
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
              : (user?.email ?? 'Landlord');

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.domain_rounded,
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
                      t('landlordDashboardSubtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: FontSizes.standard,
                        color: DefaultColors.textSecondary,
                      ),
                    ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: DefaultColors.white,
        selectedItemColor: DefaultColors.primary,
        unselectedItemColor: DefaultColors.textSecondary,
        selectedFontSize: FontSizes.small,
        unselectedFontSize: FontSizes.small,
        elevation: 8,
        items: landlordNavItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: t(item.labelKey),
              ),
            )
            .toList(),
      ),
    );
  }
}
