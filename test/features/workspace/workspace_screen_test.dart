import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/screens/landlord_screen.dart';
import 'package:roomee/core/widgets/filter/app_search_app_bar.dart';
import 'package:roomee/features/auth/data/auth_dto.dart';
import 'package:roomee/features/auth/data/auth_repository.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:roomee/features/workspace/presentation/screens/detail_workspace_screen.dart';
import 'package:roomee/features/workspace/presentation/screens/list_workspace_screen.dart';
import 'package:roomee/features/workspace/presentation/screens/workspace_form_screen.dart';
import 'package:roomee/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:roomee/utils/constanst.dart';

class _FakeAuthRepo implements IAuthRepository {
  @override
  Future<AuthData> login(LoginRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<AuthData> register(RegisterRequest request) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel?> syncUserProfile() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<RefreshTokenResponse> refreshToken() async =>
      const RefreshTokenResponse(
        accessToken: 'fake_tok',
        refreshToken: 'fake_refresh_tok',
      );

  @override
  Future<void> logout() async {}

  @override
  Future<void> resendOtp(String email) async {}

  @override
  Future<AuthData> verifyOtp({required String email, required String otp}) async =>
      const AuthData(token: 't', code: null);

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<String> verifyResetOtp({required String email, required String otp}) async =>
      'token';

  @override
  Future<AuthData> resetPassword({required String resetToken, required String newPassword}) async =>
      const AuthData(token: 't', code: null);
}

class _FakeWorkspaceRepo implements IWorkspaceRepository {
  final List<WorkspaceModel> workspaces;
  final Map<int, PaginationModel<WorkspaceModel>>? pages;

  _FakeWorkspaceRepo({this.workspaces = const [], this.pages});

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({Map<String, dynamic>? queryParameters}) async {
    final page = queryParameters?['page'] as int? ?? 1;
    if (pages != null && pages!.containsKey(page)) {
      final p = pages![page]!;
      return OfflinePage(
        data: p.data,
        total: p.total,
        page: p.page,
        limit: p.limit,
        totalPages: p.totalPages,
        isComplete: true,
        source: DataSourceKind.remote,
      );
    }
    return OfflinePage(
      data: workspaces,
      total: workspaces.length,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: true,
      source: DataSourceKind.remote,
    );
  }

  @override
  Future<WorkspaceModel> getWorkspaceById(String id) async {
    return workspaces.first;
  }

  @override
  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> data) async {
    return WorkspaceModel.fromJson({...data, 'id': 'ws-99', 'userId': 'user-1'});
  }

  @override
  Future<WorkspaceModel> updateWorkspace(String id, Map<String, dynamic> data) async {
    final existingIndex = workspaces.indexWhere((w) => w.id == id);
    if (existingIndex != -1) {
      final existing = workspaces[existingIndex];
      final updated = existing.copyWith(
        status: data.containsKey('status') ? (data['status'] as num).toInt() : existing.status,
      );
      workspaces[existingIndex] = updated;
      return updated;
    }
    return WorkspaceModel.fromJson({...data, 'id': id, 'userId': 'user-1'});
  }

  @override
  Future<void> deleteWorkspace(String id) async {}
}

class _FakeLocalSourceWorkspaceRepo extends _FakeWorkspaceRepo {
  _FakeLocalSourceWorkspaceRepo({super.workspaces});

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({Map<String, dynamic>? queryParameters}) async {
    return OfflinePage(
      data: workspaces,
      total: workspaces.length,
      page: 1,
      limit: 20,
      totalPages: 1,
      isComplete: true,
      source: DataSourceKind.local,
      lastFetchedAt: DateTime(2026, 11, 1, 10, 30),
    );
  }
}

class _FakeSwitchingSourceWorkspaceRepo extends _FakeWorkspaceRepo {
  final List<WorkspaceModel> initialOnlineWorkspaces;
  final List<WorkspaceModel> fallbackLocalWorkspaces;
  bool switchToLocal = false;

  _FakeSwitchingSourceWorkspaceRepo({
    required this.initialOnlineWorkspaces,
    required this.fallbackLocalWorkspaces,
  }) : super(workspaces: initialOnlineWorkspaces);

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({Map<String, dynamic>? queryParameters}) async {
    if (switchToLocal) {
      return OfflinePage(
        data: fallbackLocalWorkspaces,
        total: fallbackLocalWorkspaces.length,
        page: 2,
        limit: 20,
        totalPages: 2,
        isComplete: true,
        source: DataSourceKind.local,
      );
    }
    return OfflinePage(
      data: initialOnlineWorkspaces,
      total: 30,
      page: 1,
      limit: 20,
      totalPages: 2,
      isComplete: false,
      source: DataSourceKind.remote,
    );
  }
}

class _FakeDelayedWorkspaceRepo extends _FakeWorkspaceRepo {
  Completer<OfflinePage<WorkspaceModel>>? loadMoreCompleter;
  Completer<OfflinePage<WorkspaceModel>>? loadCompleter;
  final int initialTotalPages;

  _FakeDelayedWorkspaceRepo({
    super.workspaces,
    this.initialTotalPages = 1,
  });

  @override
  Future<OfflinePage<WorkspaceModel>> getWorkspaces({Map<String, dynamic>? queryParameters}) async {
    if (loadCompleter != null) {
      return loadCompleter!.future;
    }
    final page = queryParameters?['page'] as int? ?? 1;
    if (page > 1 && loadMoreCompleter != null) {
      return loadMoreCompleter!.future;
    }
    final search = queryParameters?['search'] as String?;
    if (search != null) {
      return const OfflinePage(
        data: [
          WorkspaceModel(
            id: 'ws-search',
            userId: 'user-1',
            name: 'Hoa Sen',
            area: 80.0,
            provinceId: 1,
            wardId: 1,
            address: 'Đường S',
            contactName: 'S',
            contactPhone: '0902',
          ),
        ],
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
        isComplete: true,
        source: DataSourceKind.remote,
      );
    }
    return OfflinePage(
      data: workspaces,
      total: initialTotalPages > 1 ? 30 : workspaces.length,
      page: 1,
      limit: 20,
      totalPages: initialTotalPages,
      isComplete: initialTotalPages == 1,
      source: DataSourceKind.remote,
    );
  }
}

Widget _buildTestApp({
  required Widget child,
  AuthBloc? authBloc,
  WorkspaceBloc? workspaceBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(storage: const FlutterSecureStorage()),
      ),
      BlocProvider<GeneralBloc>(create: (_) => GeneralBloc()),
      if (workspaceBloc != null)
        BlocProvider<WorkspaceBloc>.value(value: workspaceBloc)
      else
        BlocProvider<WorkspaceBloc>(create: (_) => WorkspaceBloc()),
      if (authBloc != null)
        BlocProvider<AuthBloc>.value(value: authBloc)
      else
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: _FakeAuthRepo()),
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppLocalizations.preload();
  });

  group('WorkspaceScreen & ListWorkspaceScreen', () {
    test('WorkspaceBloc emits isOffline true when repository returns local source', () async {
      const sample = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Offline',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường A',
        contactName: 'A',
        contactPhone: '0901',
      );
      final localRepo = _FakeLocalSourceWorkspaceRepo(workspaces: [sample]);
      final bloc = WorkspaceBloc(repository: localRepo);

      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const WorkspaceLoading(),
          isA<WorkspaceLoaded>().having((s) => s.isOffline, 'isOffline', isTrue),
        ]),
      );
      await bloc.close();
    });

    test('WorkspaceResetEvent resets state from WorkspaceLoaded to WorkspaceInitial', () async {
      const sample = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ 1',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường A',
        contactName: 'A',
        contactPhone: '0901',
      );
      final repo = _FakeWorkspaceRepo(workspaces: [sample]);
      final bloc = WorkspaceBloc(repository: repo);

      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const WorkspaceLoading(),
          isA<WorkspaceLoaded>(),
        ]),
      );

      bloc.add(const WorkspaceResetEvent());
      await expectLater(
        bloc.stream,
        emits(isA<WorkspaceInitial>()),
      );
      await bloc.close();
    });

    test('WorkspaceBloc smooth refresh preserves workspaces and sets isRefreshing without WorkspaceLoading', () async {
      const sample = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ 1',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường A',
        contactName: 'A',
        contactPhone: '0901',
      );
      final repo = _FakeWorkspaceRepo(workspaces: [sample]);
      final bloc = WorkspaceBloc(repository: repo);

      // First load
      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const WorkspaceLoading(),
          isA<WorkspaceLoaded>().having((s) => s.workspaces.length, 'length', 1),
        ]),
      );

      // Second load (pull to refresh) -> emits isRefreshing: true, then isRefreshing: false, NO WorkspaceLoading!
      final completer = Completer<void>();
      bloc.add(WorkspaceLoadEvent(completer: completer));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkspaceLoaded>().having((s) => s.isRefreshing, 'isRefreshing', isTrue),
          isA<WorkspaceLoaded>().having((s) => s.isRefreshing, 'isRefreshing', isFalse),
        ]),
      );
      expect(completer.isCompleted, isTrue);
      await bloc.close();
    });

    test('WorkspaceBloc source guard on load more does not append local data to online list', () async {
      const sampleOnline = WorkspaceModel(
        id: 'ws-online',
        userId: 'user-1',
        name: 'Nhà trọ Online',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường A',
        contactName: 'A',
        contactPhone: '0901',
      );
      final repo = _FakeSwitchingSourceWorkspaceRepo(
        initialOnlineWorkspaces: [sampleOnline],
        fallbackLocalWorkspaces: [
          const WorkspaceModel(
            id: 'ws-local',
            userId: 'user-1',
            name: 'Nhà trọ Local',
            area: 100.0,
            provinceId: 1,
            wardId: 1,
            address: 'Đường B',
            contactName: 'B',
            contactPhone: '0902',
          ),
        ],
      );
      final bloc = WorkspaceBloc(repository: repo);

      // Page 1 is online
      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const WorkspaceLoading(),
          isA<WorkspaceLoaded>().having((s) => s.isOffline, 'isOffline', isFalse),
        ]),
      );

      // Now load more, but repository switches to local
      repo.switchToLocal = true;
      bloc.add(const WorkspaceLoadMoreEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkspaceLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
          isA<WorkspaceLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse)
              .having((s) => s.workspaces.length, 'workspaces length', 1)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ]),
      );
      await bloc.close();
    });

    test('WorkspaceBloc load more does not overwrite subsequent load/search when load more completes later', () async {
      const sample1 = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Khu trọ 1',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường 1',
        contactName: 'A',
        contactPhone: '0901',
      );
      final repo = _FakeDelayedWorkspaceRepo(workspaces: [sample1], initialTotalPages: 2);
      final bloc = WorkspaceBloc(repository: repo);

      // Initial load page 1
      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const WorkspaceLoading(),
          isA<WorkspaceLoaded>().having((s) => s.workspaces.single.id, 'id', 'ws-1'),
        ]),
      );

      // Prepare delayed load more
      final loadMoreCompleter = Completer<OfflinePage<WorkspaceModel>>();
      repo.loadMoreCompleter = loadMoreCompleter;

      // Trigger load more
      bloc.add(const WorkspaceLoadMoreEvent());
      await pumpEventQueue();

      // Trigger search before load more finishes
      bloc.add(const WorkspaceLoadEvent(queryParameters: {'search': 'Hoa Sen'}));
      await pumpEventQueue();

      // Complete the delayed load more
      loadMoreCompleter.complete(
        const OfflinePage(
          data: [
            WorkspaceModel(
              id: 'ws-page2',
              userId: 'user-1',
              name: 'Khu trọ 2',
              area: 100.0,
              provinceId: 1,
              wardId: 1,
              address: 'Đường 2',
              contactName: 'B',
              contactPhone: '0903',
            ),
          ],
          total: 2,
          page: 2,
          limit: 20,
          totalPages: 2,
          isComplete: true,
          source: DataSourceKind.remote,
        ),
      );
      await pumpEventQueue();

      // The final state should be the search result ('ws-search'), NOT overwritten by page 2 items!
      final currentState = bloc.state as WorkspaceLoaded;
      expect(currentState.workspaces.map((w) => w.id).toList(), ['ws-search']);
      await bloc.close();
    });

    testWidgets('renders LinearProgressIndicator when state isRefreshing is true', (tester) async {
      final fakeRepo = _FakeDelayedWorkspaceRepo(
        workspaces: const [
          WorkspaceModel(
            id: 'ws-1',
            userId: 'user-1',
            name: 'Nhà trọ 1',
            area: 100.0,
            provinceId: 1,
            wardId: 1,
            address: 'Đường 1',
            contactName: 'A',
            contactPhone: '0901',
          ),
        ],
      );
      final bloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      // Delay the next load
      final completer = Completer<OfflinePage<WorkspaceModel>>();
      fakeRepo.loadCompleter = completer;

      // Second load triggers isRefreshing: true
      bloc.add(const WorkspaceLoadEvent());
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete(
        const OfflinePage(
          data: [],
          total: 0,
          page: 1,
          limit: 20,
          totalPages: 1,
          isComplete: true,
          source: DataSourceKind.remote,
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('renders offline banner when isOffline is true', (tester) async {
      const sample = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Offline',
        area: 100.0,
        provinceId: 1,
        wardId: 1,
        address: 'Đường A',
        contactName: 'A',
        contactPhone: '0901',
      );
      final localRepo = _FakeLocalSourceWorkspaceRepo(workspaces: [sample]);
      final bloc = WorkspaceBloc(repository: localRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.textContaining(t('common.offlineModeNotice')), findsOneWidget);
    });

    testWidgets('renders empty search state with search_off icon when searching with no match',
        (tester) async {
      final fakeRepo = _FakeWorkspaceRepo(workspaces: []);
      final workspaceBloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: workspaceBloc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'KhongCoKetQua');
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text(t('noSearchResults')), findsOneWidget);
      expect(find.text(t('tryDifferentKeywords')), findsOneWidget);
    });

    testWidgets('renders ListWorkspaceScreen with search bar, empty state, and FAB when no workspaces',
        (tester) async {
      final fakeRepo = _FakeWorkspaceRepo(workspaces: []);
      final workspaceBloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: workspaceBloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.byType(ListWorkspaceScreen), findsOneWidget);

      // Icon tìm kiếm và icon bộ lọc trên AppBar
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppSearchAppBar),
          matching: find.byIcon(Icons.tune_rounded),
        ),
        findsOneWidget,
      );

      // Bấm vào icon tìm kiếm để mở Morphing AppBar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text(t('searchWorkspaceHint')), findsOneWidget);

      // Trạng thái trống
      expect(find.byIcon(Icons.domain_disabled_rounded), findsOneWidget);
      expect(find.text(t('workspaceEmpty')), findsOneWidget);
      expect(find.text(t('workspaceSubtitle')), findsOneWidget);

      // Nút floating action button thêm mới
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders list of workspace cards when workspaces are loaded',
        (tester) async {
      const sampleWorkspace = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Hoa Hồng',
        type: WorkspaceType.apartmentMiniHouse,
        area: 150.0,
        numberOfRooms: 15,
        provinceId: 1,
        wardId: 1,
        address: '123 Đường Láng',
        contactName: 'Bác Hoa',
        contactPhone: '0901234567',
        province: ProvinceModel(id: 1, code: 1, fullName: 'Hà Nội', codeName: 'hn'),
        ward: WardModel(id: 1, code: 1, provinceId: 1, fullName: 'Phường Láng Thượng', codeName: 'lt'),
      );

      final fakeRepo = _FakeWorkspaceRepo(workspaces: [sampleWorkspace]);
      final workspaceBloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: workspaceBloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListWorkspaceScreen), findsOneWidget);
      expect(find.text(t('common.totalRecords', {'count': '1'})), findsOneWidget);
      expect(find.text(t('common.showOf', {'count': '1', 'total': '1'})), findsOneWidget);
      expect(find.text('Nhà trọ Hoa Hồng'), findsOneWidget);
      expect(find.text('150.0 m²'), findsOneWidget);
      expect(find.text('15 phòng'), findsOneWidget);
      expect(find.text('Bác Hoa - 0901234567'), findsOneWidget);
      expect(find.text('123 Đường Láng, Phường Láng Thượng, Hà Nội'), findsOneWidget);

      // Menu ba chấm ở góc phải của card item
      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);

      // Bấm vào nút menu ba chấm
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Xác nhận 3 option xuất hiện: Xem chi tiết, Chỉnh sửa, Xóa
      expect(find.text(t('actionViewDetail')), findsOneWidget);
      expect(find.text(t('actionEdit')), findsOneWidget);
      expect(find.text(t('actionDelete')), findsOneWidget);

      // Chọn option Xóa -> hiển thị hộp thoại xác nhận
      await tester.tap(find.text(t('actionDelete')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t('deleteConfirmTitle')), findsOneWidget);
      expect(find.text(t('cancel')), findsOneWidget);

      // Bấm Hủy đóng dialog
      await tester.tap(find.text(t('cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('workspace card shows switch and toggling from true to false shows confirm dialog',
        (tester) async {
      final sampleWorkspace = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Hoa Hồng',
        type: WorkspaceType.apartmentMiniHouse,
        area: 150.0,
        numberOfRooms: 15,
        status: 1,
        provinceId: 1,
        wardId: 1,
        address: '123 Đường Láng',
        contactName: 'Bác Hoa',
        contactPhone: '0901234567',
        province: const ProvinceModel(id: 1, code: 1, fullName: 'Hà Nội', codeName: 'hn'),
        ward: const WardModel(id: 1, code: 1, provinceId: 1, fullName: 'Phường Láng Thượng', codeName: 'lt'),
      );

      final fakeRepo = _FakeWorkspaceRepo(workspaces: [sampleWorkspace]);
      final workspaceBloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: workspaceBloc,
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Gạt switch từ true sang false -> Hiển thị confirm dialog
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t('workspaceStatusConfirmTitle')), findsOneWidget);
      expect(
        find.text(t('workspaceStatusDeactivateConfirm', {'name': 'Nhà trọ Hoa Hồng'})),
        findsOneWidget,
      );
      expect(find.text(t('actionDeactivate')), findsOneWidget);
      expect(find.text(t('cancel')), findsOneWidget);

      // Bấm Hủy -> Không đổi trạng thái
      await tester.tap(find.text(t('cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Gạt switch lại và xác nhận Tạm dừng
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text(t('actionDeactivate')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('toggling switch from false to true activates directly without confirm dialog',
        (tester) async {
      final sampleInactive = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Tạm Dừng',
        type: WorkspaceType.rentedRoom,
        area: 100.0,
        numberOfRooms: 5,
        status: 0,
        provinceId: 1,
        wardId: 1,
        address: '123 Đường Láng',
        contactName: 'Bác Hoa',
        contactPhone: '0901234567',
        province: const ProvinceModel(id: 1, code: 1, fullName: 'Hà Nội', codeName: 'hn'),
        ward: const WardModel(id: 1, code: 1, provinceId: 1, fullName: 'Phường Láng Thượng', codeName: 'lt'),
      );

      final fakeRepo = _FakeWorkspaceRepo(workspaces: [sampleInactive]);
      final workspaceBloc = WorkspaceBloc(repository: fakeRepo);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkspaceScreen(),
          workspaceBloc: workspaceBloc,
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      // Gạt switch từ false sang true -> Kích hoạt ngay, không hiện dialog
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('tapping Workspace item in LandlordScreen switches tab and displays WorkspaceScreen with FAB',
        (tester) async {
      final fakeAuth = _FakeAuthRepo();
      final authBloc = AuthBloc(authRepository: fakeAuth);
      authBloc.emit(
        const Authenticated(
          token: 'fake_tok',
          user: UserModel(
            id: '1',
            email: 'landlord@roomee.vn',
            role: UserRole.landlord,
          ),
        ),
      );

      final router = createAppRouter(initialLocation: AppRoutes.landlord);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>(
              create: (_) => LocaleCubit(storage: const FlutterSecureStorage()),
            ),
            BlocProvider<GeneralBloc>(create: (_) => GeneralBloc()),
            BlocProvider<WorkspaceBloc>(
              create: (_) => WorkspaceBloc(repository: _FakeWorkspaceRepo(workspaces: [])),
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi'), Locale('en')],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LandlordScreen), findsOneWidget);

      // Nhấn vào item Workspace trên Bottom Navigation Bar
      final workspaceNavItem = find.text('Workspace');
      expect(workspaceNavItem, findsOneWidget);

      await tester.tap(workspaceNavItem);
      await tester.pumpAndSettle();

      // Xác nhận LandlordScreen và BottomNavigationBar vẫn hiển thị cố định
      expect(find.byType(LandlordScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Xác nhận view ở giữa đã đổi sang WorkspaceScreen và có nút FAB
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.byType(ListWorkspaceScreen), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Nhấn vào nút FAB -> mở WorkspaceFormScreen đè lên màn hình hiện tại
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceFormScreen), findsOneWidget);

      // Nhấn nút Back trên AppBar của WorkspaceFormScreen -> quay lại WorkspaceScreen
      final backButton = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceFormScreen), findsNothing);
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('WorkspaceFormScreen in create mode renders form fields properly', (tester) async {
      await tester.pumpWidget(_buildTestApp(child: const WorkspaceFormScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceFormScreen), findsOneWidget);
      expect(find.text(t('createWorkspaceTitle')), findsOneWidget);
      expect(find.text(t('fields.workspaceName')), findsOneWidget);
      expect(find.text(t('fields.workspaceType')), findsOneWidget);
      expect(find.text(t('fields.workspaceArea')), findsOneWidget);
      expect(find.text(t('fields.numberOfRooms')), findsOneWidget);
      expect(find.text(t('fields.workspaceAddress')), findsOneWidget);
      expect(find.text(t('fields.contactName')), findsOneWidget);
      expect(find.text(t('fields.contactPhone')), findsOneWidget);
      expect(find.text(t('common.createButton')), findsOneWidget);
    });

    testWidgets('DetailWorkspaceScreen renders details and navigates to edit mode', (tester) async {
      const sampleWorkspace = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Minh Khai',
        type: WorkspaceType.apartmentMiniHouse,
        area: 120.0,
        numberOfRooms: 10,
        provinceId: 1,
        wardId: 1,
        address: '45 Minh Khai',
        description: 'Phòng trọ cao cấp có gác xép',
        contactName: 'Bác Chủ Trọ',
        contactPhone: '0987654321',
        contactZalo: '0987654321',
        province: ProvinceModel(id: 1, code: 1, fullName: 'Hà Nội', codeName: 'hn'),
        ward: WardModel(id: 1, code: 1, provinceId: 1, fullName: 'Phường Minh Khai', codeName: 'mk'),
      );

      await tester.pumpWidget(
        _buildTestApp(child: const DetailWorkspaceScreen(workspace: sampleWorkspace)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DetailWorkspaceScreen), findsOneWidget);
      expect(find.text(t('detailWorkspaceTitle')), findsOneWidget);
      expect(find.text('Nhà trọ Minh Khai'), findsOneWidget);
      expect(find.text('120.0 m²'), findsOneWidget);
      expect(find.text('10 phòng'), findsOneWidget);
      expect(find.text('45 Minh Khai'), findsOneWidget);
      expect(find.text('Phường Minh Khai'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('Bác Chủ Trọ'), findsOneWidget);
      expect(find.text('0987654321'), findsWidgets);
      expect(find.text('Phòng trọ cao cấp có gác xép'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      // Nút xóa hiển thị trên AppBar
      final deleteIconButton = find.byTooltip(t('actionDelete'));
      expect(deleteIconButton, findsOneWidget);

      // Nhấn nút xóa trên AppBar -> hiển thị hộp thoại xác nhận xóa
      await tester.tap(deleteIconButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t('deleteConfirmTitle')), findsOneWidget);
      expect(find.text(t('cancel')), findsOneWidget);

      await tester.tap(find.text(t('cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('WorkspaceFormScreen in edit mode pre-populates existing data', (tester) async {
      const sampleWorkspace = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ Đã Có Sẵn',
        type: WorkspaceType.dormitory,
        area: 85.5,
        numberOfRooms: 6,
        provinceId: 1,
        wardId: 1,
        address: '77 Xã Đàn',
        description: 'Gần trường đại học',
        contactName: 'Anh Quản Lý',
        contactPhone: '0912345678',
        contactZalo: '0912345678',
        province: ProvinceModel(id: 1, code: 1, fullName: 'Hà Nội', codeName: 'hn'),
        ward: WardModel(id: 1, code: 1, provinceId: 1, fullName: 'Phường Phương Liên', codeName: 'pl'),
      );

      await tester.pumpWidget(
        _buildTestApp(child: const WorkspaceFormScreen(workspace: sampleWorkspace)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceFormScreen), findsOneWidget);
      expect(find.text(t('editWorkspaceTitle')), findsOneWidget);
      expect(find.text(t('common.saveChanges')), findsOneWidget);
      expect(find.text('Nhà trọ Đã Có Sẵn'), findsOneWidget);
      expect(find.text('85.5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('77 Xã Đàn'), findsOneWidget);
      expect(find.text('Anh Quản Lý'), findsOneWidget);
      expect(find.text('0912345678'), findsWidgets);
    });

    test('WorkspaceBloc loads first page and appends data on WorkspaceLoadMoreEvent', () async {
      const ws1 = WorkspaceModel(
        id: 'ws-1',
        userId: 'user-1',
        name: 'Nhà trọ 1',
        area: 50,
        numberOfRooms: 5,
        provinceId: 1,
        wardId: 1,
        address: 'Địa chỉ 1',
        contactName: 'Người quản lý 1',
        contactPhone: '0901',
      );
      const ws2 = WorkspaceModel(
        id: 'ws-2',
        userId: 'user-1',
        name: 'Nhà trọ 2',
        area: 60,
        numberOfRooms: 6,
        provinceId: 1,
        wardId: 1,
        address: 'Địa chỉ 2',
        contactName: 'Người quản lý 2',
        contactPhone: '0902',
      );

      final bloc = WorkspaceBloc(
        repository: _FakeWorkspaceRepo(pages: {
          1: const PaginationModel(
            data: [ws1],
            total: 2,
            page: 1,
            limit: 1,
            totalPages: 2,
          ),
          2: const PaginationModel(
            data: [ws2],
            total: 2,
            page: 2,
            limit: 1,
            totalPages: 2,
          ),
        }),
      );

      bloc.add(const WorkspaceLoadEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<WorkspaceLoading>(),
          predicate<WorkspaceLoaded>((s) =>
              s.workspaces.length == 1 &&
              s.workspaces.first.id == 'ws-1' &&
              s.total == 2 &&
              s.page == 1 &&
              !s.hasReachedMax &&
              !s.isLoadingMore),
        ]),
      );

      bloc.add(const WorkspaceLoadMoreEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<WorkspaceLoaded>((s) => s.isLoadingMore && s.workspaces.length == 1),
          predicate<WorkspaceLoaded>((s) =>
              !s.isLoadingMore &&
              s.workspaces.length == 2 &&
              s.workspaces.last.id == 'ws-2' &&
              s.page == 2 &&
              s.hasReachedMax),
        ]),
      );

      await bloc.close();
    });
  });
}
