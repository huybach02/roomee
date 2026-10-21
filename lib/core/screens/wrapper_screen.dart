import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

/// Màn hình điều phối (Wrapper / Router Dispatcher).
/// Sau khi đăng nhập thành công, app sẽ chuyển đến screen này.
/// Screen này kiểm tra vai trò (role) và trạng thái hợp đồng (hasContract) của user
/// để tự động chuyển tiếp tới màn hình tương ứng:
/// - Tenant + hasContract == false -> HomeScreen (Tìm trọ, xem tin đăng)
/// - Tenant + hasContract == true  -> TenantScreen (Dashboard quản lý phòng thuê)
/// - Landlord / Staff              -> LandlordScreen (Dashboard quản lý nhà trọ)
class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  State<WrapperScreen> createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect(context.read<AuthBloc>().state);
    });
  }

  void _redirect(AuthState state) {
    if (!mounted) return;

    if (state is Authenticated) {
      final user = state.user;
      if (user == null) {
        context.go(AppRoutes.welcome);
        return;
      }

      if (user.role == UserRole.landlord || user.role == UserRole.staff) {
        context.go(AppRoutes.landlord);
      } else if (user.role == UserRole.tenant) {
        if (user.hasContract) {
          context.go(AppRoutes.tenant);
        } else {
          context.go(AppRoutes.home);
        }
      } else {
        context.go(AppRoutes.home);
      }
    } else if (state is Unauthenticated) {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _redirect(state),
      child: const Scaffold(
        backgroundColor: DefaultColors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DefaultColors.primary),
          ),
        ),
      ),
    );
  }
}
