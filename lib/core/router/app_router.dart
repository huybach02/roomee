import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/screens/home_screen.dart';
import 'package:roomee/core/screens/landlord_screen.dart';
import 'package:roomee/core/screens/tenant_screen.dart';
import 'package:roomee/core/screens/welcome_screen.dart';
import 'package:roomee/core/screens/wrapper_screen.dart';
import 'package:roomee/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:roomee/features/auth/presentation/screens/login_screen.dart';
import 'package:roomee/features/auth/presentation/screens/otp_screen.dart';
import 'package:roomee/features/auth/presentation/screens/register_screen.dart';
import 'package:roomee/features/auth/presentation/screens/reset_password_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String wrapper = '/wrapper';
  static const String home = '/home';
  static const String tenant = '/tenant';
  static const String landlord = '/landlord';
}

Page<void> _buildSlidePage(GoRouterState state, Widget child) {
  return CupertinoPage<void>(
    key: state.pageKey,
    child: child,
  );
}

GoRouter createAppRouter({
  String initialLocation = AppRoutes.wrapper,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => _buildSlidePage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildSlidePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => _buildSlidePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? destination;
          String? purpose;
          if (extra is Map<String, dynamic>) {
            destination = extra['destination'] as String?;
            purpose = extra['purpose'] as String?;
          } else if (extra is String) {
            destination = extra;
          }
          return _buildSlidePage(
            state,
            OtpScreen(
              destination: destination,
              purpose: purpose,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final resetToken = extra is String ? extra : '';
          return _buildSlidePage(
            state,
            ResetPasswordScreen(resetToken: resetToken),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.wrapper,
        name: 'wrapper',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const WrapperScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.tenant,
        name: 'tenant',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const TenantScreen()),
      ),
      GoRoute(
        path: AppRoutes.landlord,
        name: 'landlord',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const LandlordScreen()),
      ),
    ],
  );
}

final GoRouter appRouter = createAppRouter();
