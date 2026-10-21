import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_client.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.preload();
  Locale initialLocale = const Locale('vi');

  const storage = FlutterSecureStorage();
  final savedCode = await storage.read(key: 'app_locale');
  if (savedCode == 'en' || savedCode == 'vi') {
    initialLocale = Locale(savedCode!);
  }

  final authBloc = AuthBloc()..add(const AuthCheckEvent());

  // Hook tự động đăng xuất khi gặp lỗi 401 Unauthorized từ bất kỳ API nào
  ApiClient(
    onUnauthorized: () {
      authBloc.add(const AuthLogoutEvent());
    },
  );

  runApp(MyApp(initialLocale: initialLocale, authBloc: authBloc));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  final GoRouter? router;
  final AuthBloc? authBloc;
  final GeneralBloc? generalBloc;

  const MyApp({
    super.key,
    this.initialLocale = const Locale('vi'),
    this.router,
    this.authBloc,
    this.generalBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(initialLocale: initialLocale),
        ),
        BlocProvider(
          create: (_) => generalBloc ?? GeneralBloc(),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => authBloc ?? (AuthBloc()..add(const AuthCheckEvent())),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.mainTheme,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router ?? appRouter,
          );
        },
      ),
    );
  }
}
