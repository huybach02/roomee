import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/bloc/locale/locale_cubit.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/features/general/data/general_repository.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';
import 'package:roomee/core/screens/welcome_screen.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_card_select.dart';
import 'package:roomee/core/widgets/app_date_picker_field.dart';
import 'package:roomee/core/widgets/app_dropdown_field.dart';
import 'package:roomee/core/widgets/app_segmented_select.dart';
import 'package:roomee/core/widgets/app_text_field.dart';
import 'package:roomee/features/auth/presentation/screens/login_screen.dart';
import 'package:roomee/features/auth/presentation/screens/register_screen.dart';
import 'package:roomee/main.dart';
import 'package:roomee/utils/constanst.dart';

class _FakeGeneralRepository implements IGeneralRepository {
  @override
  Future<List<ProvinceModel>> getProvinces() async => const [
        ProvinceModel(id: 1, code: 79, fullName: 'TP HCM', codeName: 'hcm'),
      ];

  @override
  Future<List<WardModel>> getWardsByProvince(int provinceId) async => const [
        WardModel(
          id: 10,
          code: 1,
          provinceId: 1,
          fullName: 'Phường 1',
          codeName: 'p1',
        ),
      ];
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

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that MyApp builds successfully.
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('WelcomeScreen displays logo and action buttons', (
    WidgetTester tester,
  ) async {
    bool registerPressed = false;
    bool loginPressed = false;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: WelcomeScreen(
                onRegisterPressed: () => registerPressed = true,
                onLoginPressed: () => loginPressed = true,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final imageWidget = tester.widget<Image>(imageFinder);
    expect(
      (imageWidget.image as AssetImage).assetName,
      'assets/images/logo.png',
    );

    // Verify welcome greeting text is displayed
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(
      find.text('Giải pháp quản lý phòng trọ tiện lợi & hiệu quả'),
      findsOneWidget,
    );

    // Verify 'Đăng ký' button exists and is clickable
    final registerButton = find.widgetWithText(AppButton, 'Đăng ký');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    expect(registerPressed, isTrue);

    // Verify 'Đăng nhập' button exists and is clickable
    final loginButton = find.widgetWithText(AppButton, 'Đăng nhập');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    expect(loginPressed, isTrue);
  });

  testWidgets('WelcomeScreen toggles language between VI and EN', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const WelcomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially in Vietnamese
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    // Tap EN option
    final enButton = find.text('EN');
    expect(enButton, findsOneWidget);
    await tester.tap(enButton);
    await tester.pumpAndSettle();

    // Now text changes to English
    expect(find.text('Welcome to Roomee'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    // Tap VI option
    final viButton = find.text('VI');
    expect(viButton, findsOneWidget);
    await tester.tap(viButton);
    await tester.pumpAndSettle();

    // Text returns to Vietnamese
    expect(find.text('Chào mừng bạn đến với Roomee'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
  });

  testWidgets('AppButton shows loading indicator when isLoading is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(text: 'Tiếp tục', isLoading: true)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tiếp tục'), findsNothing);
  });

  testWidgets(
    'WelcomeScreen navigates to LoginScreen and RegisterScreen using router',
    (WidgetTester tester) async {
      final router = createAppRouter();
      await tester.pumpWidget(
        MyApp(
          router: router,
          generalBloc: GeneralBloc(repository: _FakeGeneralRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);

      final loginButton = find.widgetWithText(AppButton, 'Đăng nhập');
      await tester.tap(loginButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      router.go(AppRoutes.welcome);
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      final registerButton = find.widgetWithText(AppButton, 'Đăng ký');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    },
  );

  testWidgets('RegisterScreen displays all form fields and validates inputs', (
    WidgetTester tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.register);
    await tester.pumpWidget(
      MyApp(
        router: router,
        generalBloc: GeneralBloc(repository: _FakeGeneralRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);

    // Verify title and role selector
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Người thuê trọ'), findsOneWidget);
    expect(find.text('Chủ trọ / Quản lý trọ'), findsOneWidget);

    // Verify fields
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Địa chỉ'), findsNothing);
    expect(find.text('Tỉnh/Thành phố'), findsOneWidget);
    expect(find.text('Phường/Xã'), findsOneWidget);
    expect(find.text('Ngày sinh'), findsOneWidget);
    expect(find.text('Giới tính'), findsOneWidget);

    // Verify gender options
    expect(find.text('Nam'), findsOneWidget);
    expect(find.text('Nữ'), findsOneWidget);
    expect(find.text('Khác'), findsOneWidget);

    // Tap submit button with empty form to trigger validation
    final submitButton = find.widgetWithText(AppButton, 'Đăng ký');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Vui lòng nhập trường này'), findsWidgets);

    // Verify phone number validation
    final phoneField = find.widgetWithText(AppTextField, 'Số điện thoại');
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '0123456789'); // Đầu số không hợp lệ theo chuẩn VN
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);

    await tester.enterText(phoneField, '0901234567'); // 10 số hợp lệ
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsNothing);

    await tester.enterText(phoneField, '+84901234567'); // Chuẩn +84 hợp lệ
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsNothing);

    // Select Province
    final provinceField = find.widgetWithText(AppTextField, 'Tỉnh/Thành phố');
    await tester.ensureVisible(provinceField);
    await tester.tap(provinceField);
    await tester.pumpAndSettle();
    expect(find.text('TP HCM'), findsOneWidget);
    await tester.tap(find.text('TP HCM'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'AppTextField renders properly and handles input and validation',
    (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      AppTextField(
                        controller: controller,
                        labelText: 'Họ và tên',
                        hintText: 'Nhập họ và tên',
                        prefixIcon: const Icon(Icons.person),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Form.of(context).validate();
                        },
                        child: const Text('Validate'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Nhập họ và tên'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt buộc nhập'), findsOneWidget);

      await tester.enterText(find.byType(AppTextField), 'Nguyễn Văn A');
      await tester.pumpAndSettle();
      expect(controller.text, 'Nguyễn Văn A');

      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt buộc nhập'), findsNothing);
    },
  );

  testWidgets(
    'AppDatePickerField renders formatted date and opens date picker on tap',
    (WidgetTester tester) async {
      DateTime? selectedDate = DateTime(2000, 5, 15);
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerField(
              controller: controller,
              selectedDate: selectedDate,
              labelText: 'Ngày sinh',
              hintText: 'Chọn ngày sinh',
              onDateSelected: (date) {
                selectedDate = date;
              },
            ),
          ),
        ),
      );

      expect(find.text('15/05/2000'), findsOneWidget);
      expect(find.text('Ngày sinh'), findsOneWidget);

      await tester.tap(find.byType(AppDatePickerField));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    },
  );

  testWidgets('AppSegmentedSelect renders options and notifies when selected', (
    WidgetTester tester,
  ) async {
    String selectedValue = 'male';

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: AppSegmentedSelect<String>(
                labelText: 'Giới tính',
                selected: selectedValue,
                options: const [
                  AppSelectOption(value: 'male', label: 'Nam'),
                  AppSelectOption(value: 'female', label: 'Nữ'),
                  AppSelectOption(value: 'other', label: 'Khác'),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedValue = val;
                  });
                },
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Giới tính'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);
    expect(find.text('Nữ'), findsOneWidget);
    expect(find.text('Khác'), findsOneWidget);

    await tester.tap(find.text('Nữ'));
    await tester.pumpAndSettle();
    expect(selectedValue, 'female');

    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();
    expect(selectedValue, 'other');
  });

  testWidgets(
    'AppSegmentedSelect.multiple supports selecting and deselecting multiple options',
    (WidgetTester tester) async {
      Set<String> selectedValues = {'wifi'};

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppSegmentedSelect<String>.multiple(
                  labelText: 'Tiện ích',
                  selectedValues: selectedValues,
                  options: const [
                    AppSelectOption(value: 'wifi', label: 'Wifi'),
                    AppSelectOption(value: 'parking', label: 'Bãi đỗ xe'),
                    AppSelectOption(value: 'ac', label: 'Điều hòa'),
                  ],
                  onMultiChanged: (newSet) {
                    setState(() {
                      selectedValues = newSet;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Tiện ích'), findsOneWidget);
      expect(find.text('Wifi'), findsOneWidget);
      expect(find.text('Bãi đỗ xe'), findsOneWidget);
      expect(find.text('Điều hòa'), findsOneWidget);

      expect(selectedValues, {'wifi'});

      await tester.tap(find.text('Bãi đỗ xe'));
      await tester.pumpAndSettle();
      expect(selectedValues, {'wifi', 'parking'});

      await tester.tap(find.text('Wifi'));
      await tester.pumpAndSettle();
      expect(selectedValues, {'parking'});
    },
  );

  testWidgets('AppCardSelect renders cards and toggles selection properly', (
    WidgetTester tester,
  ) async {
    UserRole selectedRole = UserRole.tenant;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: AppCardSelect<UserRole>(
                labelText: 'Loại tài khoản',
                selected: selectedRole,
                options: const [
                  AppCardOption(
                    value: UserRole.tenant,
                    title: 'Người thuê trọ',
                    icon: Icons.person_outline,
                  ),
                  AppCardOption(
                    value: UserRole.landlord,
                    title: 'Chủ trọ / Quản lý trọ',
                    icon: Icons.apartment_outlined,
                  ),
                ],
                onChanged: (role) {
                  setState(() {
                    selectedRole = role;
                  });
                },
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Loại tài khoản'), findsOneWidget);
    expect(find.text('Người thuê trọ'), findsOneWidget);
    expect(find.text('Chủ trọ / Quản lý trọ'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.apartment_outlined), findsOneWidget);

    expect(selectedRole, UserRole.tenant);

    await tester.tap(find.text('Chủ trọ / Quản lý trọ'));
    await tester.pumpAndSettle();
    expect(selectedRole, UserRole.landlord);

    await tester.tap(find.text('Người thuê trọ'));
    await tester.pumpAndSettle();
    expect(selectedRole, UserRole.tenant);
  });

  testWidgets('LoginScreen renders all fields and validates inputs', (
    WidgetTester tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.login);
    await tester.pumpWidget(
      MyApp(
        router: router,
        generalBloc: GeneralBloc(repository: _FakeGeneralRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Chưa có tài khoản?'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);

    final loginButton = find.widgetWithText(AppButton, 'Đăng nhập');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập trường này'), findsWidgets);

    final registerNow = find.text('Đăng ký ngay');
    await tester.tap(registerNow);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('AppDropdownField opens sheet and selects an option', (
    WidgetTester tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppDropdownField<String>(
                value: selected,
                labelText: 'Tỉnh/Thành phố',
                hintText: 'Chọn tỉnh/thành phố',
                searchHint: 'Tìm kiếm...',
                emptyText: 'Không có dữ liệu',
                options: const [
                  AppDropdownOption(value: 'hcm', label: 'TP Hồ Chí Minh'),
                  AppDropdownOption(value: 'hn', label: 'Hà Nội'),
                ],
                onChanged: (value) {
                  setState(() {
                    selected = value;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Tỉnh/Thành phố'), findsOneWidget);

    await tester.tap(find.byType(AppDropdownField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Hà Nội'), findsOneWidget);

    await tester.tap(find.text('Hà Nội'));
    await tester.pumpAndSettle();

    expect(selected, 'hn');
    expect(find.text('Hà Nội'), findsOneWidget);
  });
}
