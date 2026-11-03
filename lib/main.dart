import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/api_client.dart';
import 'package:roomee/core/offline/hive/cache_boxes.dart';
import 'package:roomee/core/offline/hive/hive_initializer.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/no_internet_screen.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cacheBoxes = await HiveInitializer.initialize();
  await AppLocalizations.preload();
  Locale initialLocale = const Locale('vi');

  const storage = FlutterSecureStorage();
  final savedCode = await storage.read(key: 'app_locale');
  if (savedCode == 'en' || savedCode == 'vi') {
    initialLocale = Locale(savedCode!);
  }

  final authRepository = AuthRepository(cacheBoxes: cacheBoxes);
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const AuthCheckEvent());

  // Hook tự động đăng xuất khi gặp lỗi 401 Unauthorized từ bất kỳ API nào,
  // và hiển thị màn hình NoInternetScreen khi mất mạng mà không bị đăng xuất
  ApiClient(
    onUnauthorized: () {
      authBloc.add(const AuthLogoutEvent());
    },
    onNetworkError: () {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        NoInternetScreen.show(context);
      }
    },
  );

  runApp(
    MyApp(
      initialLocale: initialLocale,
      authBloc: authBloc,
      cacheBoxes: cacheBoxes,
    ),
  );
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  final GoRouter? router;
  final AuthBloc? authBloc;
  final GeneralBloc? generalBloc;
  final WorkspaceBloc? workspaceBloc;
  final CacheBoxes? cacheBoxes;

  const MyApp({
    super.key,
    this.initialLocale = const Locale('vi'),
    this.router,
    this.authBloc,
    this.generalBloc,
    this.workspaceBloc,
    this.cacheBoxes,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authBloc = widget.authBloc ?? (AuthBloc()..add(const AuthCheckEvent()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi ứng dụng chuyển từ Background lên Foreground:
      // Tự động kích hoạt AuthCheckEvent() để làm mới thông tin mới nhất từ server
      _authBloc.add(const AuthCheckEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(initialLocale: widget.initialLocale),
        ),
        if (widget.generalBloc != null)
          BlocProvider.value(value: widget.generalBloc!)
        else
          BlocProvider(create: (_) => GeneralBloc()),
        BlocProvider.value(value: _authBloc),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) {
          final prevUserId = prev is Authenticated ? prev.user?.id : null;
          final currUserId = curr is Authenticated ? curr.user?.id : null;
          return prevUserId != currUserId;
        },
        builder: (context, authState) {
          final sessionKey = authState is Authenticated
              ? (authState.user?.id ?? 'authenticated')
              : 'guest';

          return MultiBlocProvider(
            key: ValueKey(sessionKey),
            providers: [
              if (widget.workspaceBloc != null)
                BlocProvider.value(value: widget.workspaceBloc!)
              else
                BlocProvider(
                  create: (_) => WorkspaceBloc(
                    repository: widget.cacheBoxes != null
                        ? WorkspaceRepository.fromBoxes(widget.cacheBoxes!)
                        : WorkspaceRepository(),
                  ),
                ),
              // Sau này có thêm module mới (Room, Contract, Invoice...), chỉ cần thêm 1 dòng ở đây:
              // BlocProvider(create: (_) => RoomBloc(...)),
              // BlocProvider(create: (_) => ContractBloc(...)),
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
                  routerConfig: widget.router ?? appRouter,
                );
              },
            ),
          );
        },
      ),
    );

    final cacheBoxes = widget.cacheBoxes;
    if (cacheBoxes == null) {
      return app;
    }

    return RepositoryProvider.value(value: cacheBoxes, child: app);
  }
}
