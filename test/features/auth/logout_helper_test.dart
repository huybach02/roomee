import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/auth/presentation/logout_helper.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';

class _RecordingAuthRepository implements IAuthRepository {
  bool? lastPreservePendingChanges;

  @override
  Future<void> logout({bool preservePendingChanges = false}) async {
    lastPreservePendingChanges = preservePendingChanges;
  }

  @override
  Future<AuthData> login(LoginRequest request) async =>
      const AuthData(token: 't', code: null);
  @override
  Future<AuthData> register(RegisterRequest request) async =>
      const AuthData(token: 't', code: null);
  @override
  Future<void> resendOtp(String email) async {}
  @override
  Future<AuthData> verifyOtp({
    required String email,
    required String otp,
  }) async => const AuthData(token: 't', code: null);
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async => 'reset';
  @override
  Future<AuthData> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async => const AuthData(token: 't', code: null);
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Future<UserModel?> syncUserProfile() async => null;
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<String?> getToken() async => 'token';
  @override
  Future<String?> getRefreshToken() async => 'refresh';
  @override
  Future<RefreshTokenResponse> refreshToken() async =>
      const RefreshTokenResponse(accessToken: 'a', refreshToken: 'r');
}

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  int pending;
  bool flushSucceeds;

  _FakeWorkspaceRepository({required this.pending, this.flushSucceeds = false});

  @override
  ValueListenable<bool>? get isSyncingNotifier => null;

  @override
  ValueListenable<bool?>? get syncSuccessNotifier => null;

  @override
  Future<int> pendingMutationCount() async => pending;

  @override
  Future<void> flushPendingMutations() async {
    if (flushSucceeds) pending = 0;
  }

  @override
  Future<void> syncIfPending() async {}

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({
    Map<String, dynamic>? queryParameters,
  }) async =>
      throw UnimplementedError();
  @override
  Future<WorkspaceModel> getWorkspaceById(String id) async =>
      throw UnimplementedError();
  @override
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<WorkspaceModel> updateWorkspace(
    String id,
    Map<String, dynamic> data,
  ) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteWorkspace(String id) async {}
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppLocalizations.preload();
  });

  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Future<_RecordingAuthRepository> pumpScreen(
    WidgetTester tester,
    _FakeWorkspaceRepository workspaceRepo,
  ) async {
    final authRepo = _RecordingAuthRepository();
    final authBloc = AuthBloc(authRepository: authRepo);
    final workspaceBloc = WorkspaceBloc(repository: workspaceRepo);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<WorkspaceBloc>.value(value: workspaceBloc),
          BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => confirmAndLogout(context),
                child: const Text('logout'),
              ),
            ),
          ),
        ),
      ),
    );

    return authRepo;
  }

  testWidgets('logs out directly when there are no pending mutations', (
    tester,
  ) async {
    final authRepo = await pumpScreen(
      tester,
      _FakeWorkspaceRepository(pending: 0),
    );

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    expect(authRepo.lastPreservePendingChanges, isFalse);
  });

  testWidgets('syncs pending mutations before logging out', (tester) async {
    final authRepo = await pumpScreen(
      tester,
      _FakeWorkspaceRepository(pending: 2, flushSucceeds: true),
    );

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    // Đẩy thành công -> không hỏi người dùng, xoá sạch như bình thường
    expect(find.text('Còn thay đổi chưa gửi'), findsNothing);
    expect(authRepo.lastPreservePendingChanges, isFalse);
  });

  testWidgets('asks the user to keep or discard when sync fails', (
    tester,
  ) async {
    final authRepo = await pumpScreen(
      tester,
      _FakeWorkspaceRepository(pending: 2),
    );

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    expect(find.text('Còn thay đổi chưa gửi'), findsOneWidget);

    await tester.tap(find.text('Giữ lại'));
    await tester.pumpAndSettle();

    expect(authRepo.lastPreservePendingChanges, isTrue);
  });
}
