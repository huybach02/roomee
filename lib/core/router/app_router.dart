import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/screens/welcome_screen.dart';
import 'package:roomee/features/auth/presentation/screens/login_screen.dart';
import 'package:roomee/features/auth/presentation/screens/register_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
}

Page<void> _buildSlidePage(GoRouterState state, Widget child) {
  return CupertinoPage<void>(
    key: state.pageKey,
    child: child,
  );
}

GoRouter createAppRouter({
  String initialLocation = AppRoutes.welcome,
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
    ],
  );
}

final GoRouter appRouter = createAppRouter();
