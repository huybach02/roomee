# Roomee — Quy tắc dự án

> File này được `AGENTS.md` import qua `@./.agents/rule/roomee.md`. Mọi thay đổi code trong repo phải tuân theo các quy tắc dưới đây.

## 1. Bối cảnh

- **Dự án:** Roomee (`thue_tro`) — ứng dụng quản lý nhà trọ / cho thuê trọ.
- **Hai phần:**
  - `_backend/` — API server Node.js + TypeScript (Express, TypeORM, PostgreSQL).
  - `lib/` (repo root) — ứng dụng Flutter (mobile).
- **Roadmap & tech stack:** theo `Roomee1.xlsx` (sheet `Tech` và `Module`). Các module chính: đăng ký/đăng nhập/OTP/reset mật khẩu, quản lý workspace (chủ trọ + nhân sự), quản lý nhân sự, phân quyền theo role, gán/thu hồi quyền tạm (merge `true + false = true`), realtime cập nhật phân quyền.
- **Ngôn ngữ:** luôn phản hồi bằng **tiếng Việt**.

### Trạng thái Tech Stack & Package

**Backend (`_backend/`):**
- **Runtime/ngôn ngữ:** Node.js, TypeScript (ESM, `strict`)
- **Web framework:** Express (`express ^5.3.0`, `cors ^2.8.6`)
- **ORM/DB:** TypeORM (`^1.1.2`) + PostgreSQL (`pg ^8.23.1`)
- **Validation:** Zod (`^4.6.7`)
- **DI:** tsyringe (`^4.10.0`) + `reflect-metadata`
- **Mixin/trait:** ts-mixer (`^6.0.4`)
- **Cache/Redis:** ioredis (`^5.11.1`)
- **Đa ngôn ngữ (i18n):** Tự xây dựng trên `AsyncLocalStorage` (`node:async_hooks`) + JSON dictionaries (`src/locales/vi.json`, `en.json`)
- **Tooling:** `tsx`, `typescript`
- **Các package đã cài đặt:** Argon2 (`argon2`), JWT (`jsonwebtoken` & `@types/jsonwebtoken`).
- **Các package trong roadmap nhưng CHƯA cài:** Socket.io, BullMQ, node-cron, Resend, Cloudinary (chỉ cài khi triển khai tính năng tương ứng).

**Mobile (`lib/`):**
- **Framework:** Flutter + Dart (SDK `^3.13.5`)
- **State management:** `flutter_bloc` (`^9.1.1`)
- **Mạng / HTTP Client:** `dio` (`^5.9.1`)
- **Điều hướng:** `go_router` (`^18.1.0`)
- **Lưu trữ bảo mật:** `flutter_secure_storage` (`^11.2.0`)
- **Định dạng / Đa ngôn ngữ:** `intl` (`^0.20.3`) + `flutter_localizations` (SDK) + JSON dictionaries (`assets/translations/vi.json`, `en.json`)
- **Lint:** `flutter_lints` (`^6.0.0`)
- **Icons:** `cupertino_icons` (`^1.0.8`)
- **Các package trong roadmap nhưng CHƯA cài:** `freezed`, `json_serializable`, `get_it`, `socket_io_client`, `firebase_messaging`, `cached_network_image`, `image_picker`, `file_picker` (chỉ cài khi triển khai tính năng tương ứng).

## 2. Nguyên tắc chung (bắt buộc)

1. **Nghĩ trước khi code** — nêu giả định rõ ràng; nếu mơ hồ thì hỏi; nếu có nhiều cách hiểu thì trình bày trade-off, không tự chọn âm thầm; nếu có cách đơn giản hơn thì đề xuất.
2. **Đơn giản trước** — code tối thiểu giải quyết đúng yêu cầu; không thêm feature/abstraction/config ngoài yêu cầu; không xử lý lỗi cho tình huống bất khả thi.
3. **Thay đổi tối thiểu (surgical)** — chỉ sửa đúng chỗ cần; không "cải thiện" code/comment/format xung quanh; giữ style hiện có; chỉ xóa import/biến mồ côi do chính thay đổi của mình tạo ra; không xóa dead code sẵn có trừ khi được yêu cầu.
4. **Hướng mục tiêu** — biến task thành mục tiêu kiểm chứng được (`[step] → verify: [check]`) và lặp tới khi pass.

## 3. Backend (`_backend/`)

### 3.1 Module system & ngôn ngữ
- ESM: `"type": "module"`, `moduleResolution: NodeNext`. Mọi import nội bộ **phải có đuôi `.js`** (ví dụ: `import { App } from "./app.js"`).
- TypeScript `strict`; hạn chế `any`; decorators đã bật (`experimentalDecorators`, `emitDecoratorMetadata`).

### 3.2 Cấu trúc thư mục thực tế
```text
_backend/
  scripts/
    dev.mjs                      # Dev runner đa nền tảng (tsc --watch + node --watch)
  src/
    config/                      # data-source.ts (TypeORM), redis.ts (ioredis lazyConnect)
    entities/                    # Entity TypeORM (PascalCase), kế thừa Mixin(AuditableTrait)
      user.ts
      refreshToken.ts            # Quản lý phiên đăng nhập theo thiết bị & Refresh Token
    locales/                     # vi.json, en.json (từ điển đa ngôn ngữ cho API)
    middlewares/                 # i18nMiddleware.ts, validateMiddleware.ts, authMiddleware.ts
    migrations/                  # TypeORM migrations
    mixins/                      # auditableTrait.ts (createdAt, updatedAt, createdBy, updatedBy)
    modules/<module>/            # Mỗi tính năng 1 module thư mục
      <module>Controller.ts      # Controller xử lý req/res
      <module>Routes.ts          # Express Router đóng gói trong class @injectable()
      <module>Service.ts         # Business logic
      <module>Schema.ts          # Zod schema & DTO types (z.infer)
    repositories/                # Repository tùy biến kế thừa Repository<Entity>
      userRepository.ts
      refreshTokenRepository.ts  # Truy vấn phiên, thu hồi session theo id hoặc tokenHash
    seeders/                     # Seed dữ liệu khởi tạo (DataUnitsSeeder, UserSeeder)
    types/                       # express.d.ts (mở rộng Express.Request: locale, t)
    utils/
      constanst.ts               # Hằng số, Enum UserRole, Gender (chú ý chính tả file)
      customResponse.ts          # Chuẩn hoá response API
      functionHelper.ts          # Hàm tiện ích chung
      i18n.ts                    # Cơ chế i18n qua AsyncLocalStorage & hàm t() toàn cục
      ruleValidate.ts            # Reusable rules Zod (requiredString, emailRule,...)
    routes.ts                    # Class Routes @injectable() gom toàn bộ route vào API_PREFIX
    app.ts                       # Class App cấu hình Express middleware, health check, 404, error handler
    index.ts                     # Bootstrap server: kết nối DB, Redis rồi lắng nghe port
```

### 3.3 DI (tsyringe)
- Dùng `@injectable()` cho Controller, Service, Repository, Routes.
- Inject qua constructor: `constructor(private authService: AuthService) {}`.
- Repository tùy biến kế thừa `Repository<Entity>` và gọi `super(Entity, AppDataSource.manager)` (theo `src/repositories/userRepository.ts`).
- Khởi tạo route tập trung trong `src/routes.ts` và resolve qua `container.resolve(Routes).register(this.app)`.

### 3.4 Validation (Zod & Middleware)
- Mọi input (`req.body`) phải validate bằng Zod trước khi tới Controller.
- Sử dụng rule chuẩn hóa tại `src/utils/ruleValidate.ts` (`ruleValidates.requiredString`, `emailRule`, `passwordRule`, `phoneRule`, `uuidRule`, `enumRule`, `numberRule`, `dateRule`).
- Định nghĩa schema theo từng module trong file `<module>Schema.ts`.
- Gắn validator vào route bằng middleware `validate(schema)` (`src/middlewares/validateMiddleware.ts`):
  `this.router.post("/login", validate(loginSchema), this.authController.loginUser);`
- Dữ liệu sau parse được gán lại vào `req.body`. Nếu lỗi, tự động trả về `400` qua `CustomResponse.error` với danh sách chi tiết các field vi phạm.

### 3.5 Format Response chuẩn
- Luôn dùng `CustomResponse` (`src/utils/customResponse.ts`). **Không** tự `res.json(...)` thủ công.
- **Lưu ý thứ tự tham số:**
  - Thành công: `CustomResponse.success(res, data, message = "Success", statusCode = 200)` *(data là tham số thứ 2, đứng trước message)*.
    Format: `{ success: true, message: string, data: any }`
  - Thất bại: `CustomResponse.error(res, message = "Internal Server Error", errors = null, statusCode = 500)`.
    Format: `{ success: false, message: string, errors: any }`

### 3.6 Đa ngôn ngữ (i18n Backend)
- Từ điển lưu tại `src/locales/vi.json` và `src/locales/en.json`.
- Ngôn ngữ mặc định: `"vi"`. Hỗ trợ `"vi"`, `"en"`.
- Nhận diện locale từ header `Accept-Language` hoặc query param `?lang=`, lưu vào `AsyncLocalStorage` qua `i18nMiddleware`.
- Sử dụng hàm dịch toàn cục `t(key, params)` ở bất kỳ tầng nào (Controller, Service, Middleware,...) mà không cần truyền `req`.
- Hỗ trợ format key lồng nhau (`"auth.loginSuccess"`) và param nội suy (`"notFound": "Không tìm thấy: {path}"`).

### 3.7 Database & Migration
- **Không bật `synchronize: true`** trong `data-source.ts`. Mọi thay đổi schema phải qua migration.
- Quy trình: sửa entity → `npm run migration:generate -- src/migrations/<TenMigration>` → review file migration → `npm run migration:run`.
- Entity dùng `Mixin(AuditableTrait)` (`src/mixins/auditableTrait.ts`) để tự động có các cột: `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
- Bảng đặt tên snake_case số nhiều (`users`); cột dùng camelCase (`fullName`, `phoneNumber`, `isActive`).

### 3.8 Redis
- Cấu hình qua `REDIS_URL` trong `.env`, khởi tạo trong `src/config/redis.ts` với `lazyConnect: true`.
- Kết nối tường minh khi start server (`connectRedis()`) và đóng gracefully khi tắt (`closeRedis()`).

### 3.9 Lệnh thường dùng
- `npm run dev` (chạy song song tsc và node qua `scripts/dev.mjs`, tự copy locales)
- `npm run typecheck` (`tsc --noEmit`)
- `npm run build` (`tsc && cp -r src/locales dist/locales`)
- `npm run start` (`node dist/index.js`)
- Migration: `npm run migration:generate|run|revert|show`

### 3.10 Authentication & Security
- **Mật khẩu & Băm:** Bắt buộc băm mật khẩu bằng Argon2 (`argon2.hash`). Khi query kiểm tra mật khẩu trong `AuthService`, dùng `userRepository.findByEmailWithPassword()` do trường `password` có cấu hình `{ select: false }`.
- **Cặp Token (Access Token & Refresh Token) & Quản lý Phiên (Session Management):**
  - **Access Token:** Hạn ngắn **15 phút** (`ACCESS_TOKEN_EXPIRES_IN = "15m"`). Payload chứa: `{ sub: user.id, email: user.email, role: user.role, sid: session.id }`.
  - **Refresh Token:** Hạn **7 ngày** (`REFRESH_TOKEN_EXPIRES_IN_DAYS = 7`, sliding session). Được sinh ngẫu nhiên 64 ký tự hex an toàn, băm mã hóa SHA-256 (`tokenHash`) và lưu trữ trong bảng `refresh_tokens` (đại diện cho phiên đăng nhập theo thiết bị, lưu `deviceInfo`, `ipAddress`, `isRevoked`, `lastActiveAt`).
  - **Xoay vòng Token (Refresh Token Rotation - RTR):** Mỗi khi gọi `POST /api/v1/auth/refresh-token`, phiên cũ bị đánh dấu `isRevoked = true`, đưa `blacklist:session:{oldSession.id}` vào Redis (TTL 900s), đồng thời tạo phiên mới mang `sid` mới và cấp cặp token mới (Single-Use Token).
- **Thu hồi phiên tức thời (Instant Revocation qua Redis):**
  - Trong `authMiddleware`, ngoài việc kiểm tra `blacklist:token:${token}`, còn kiểm tra nhanh trong Redis `blacklist:session:${decoded.sid}`.
  - Khi một thiết bị bị đăng xuất từ xa, server chỉ cần đưa session ID đó vào Redis blacklist là thiết bị đó bị chặn đứng ngay lập tức (< 1ms) ở request tiếp theo.
- **Cơ chế Tạm khóa tài khoản (Account Lockout qua Redis):**
  - Giới hạn: `MAX_LOGIN_ATTEMPTS = 5`.
  - Khi người dùng đăng nhập sai quá 5 lần, tài khoản bị tạm khóa 15 phút (`LOGIN_LOCKOUT_SECONDS = 900`).
  - Sử dụng Redis `login:lockout:{email}` (TTL 15p) để chặn trực tiếp từ đầu hàm `login()` mà không tốn CPU chạy Argon2.
  - Bộ đếm `login:attempts:{email}` được xóa sạch ngay khi đăng nhập đúng.
- **Quên mật khẩu (Forgot Password qua OTP + Reset Token):**
  - Bước 1: `POST /auth/forgot-password` -> Gửi mã OTP 6 số qua email (Redis TTL 10p, cooldown 60s, chống user enumeration).
  - Bước 2: `POST /auth/verify-reset-otp` -> Xác thực OTP -> Cấp `resetToken` (UUID, Redis TTL 15p).
  - Bước 3: `POST /auth/reset-password` -> Đặt mật khẩu mới với `resetToken` (dùng 1 lần duy nhất, cập nhật Argon2, xóa token và giải phóng lockout).
- **Đăng xuất (Logout & Thu hồi Phiên):**
  - Endpoint `POST /auth/logout` bảo vệ bằng `authMiddleware`.
  - Server giải mã JWT, lấy `sid` và thời gian sống còn lại (`exp - now`).
  - Đánh dấu phiên `isRevoked = true` trong database.
  - Đưa cả `blacklist:token:{token}` và `blacklist:session:{sid}` vào Redis với TTL tương ứng.
- **Tài khoản Seed dữ liệu mẫu (Seeder Accounts):**
  - `UserSeeder` cung cấp sẵn 3 tài khoản kiểm thử (mật khẩu chung: `"password"`):
    1. `minhtuan@roomee.vn` — `tenant` (Người thuê), `hasContract: true` (Tự động vào `TenantScreen`).
    2. `vantoan@roomee.vn` — `tenant` (Người thuê), `hasContract: false` (Tự động vào `HomeScreen`).
    3. `huybach2002ct@gmail.com` — `landlord` (Chủ trọ), `hasContract: false` (Tự động vào `LandlordScreen`).

## 4. Flutter (root `lib/`)

### 4.1 Cấu trúc thư mục thực tế
```text
lib/
  main.dart                      # Bootstrap: nạp preload AppLocalizations, đọc saved locale, bọc LocaleCubit
  core/
    bloc/locale/
      locale_cubit.dart          # Quản lý Locale ('vi'/'en'), persist vào FlutterSecureStorage ('app_locale')
    configs/
      app_theme.dart             # DefaultColors, FontSizes, AppTheme
    localization/
      app_localizations.dart     # Engine dịch, preload cache JSON, hàm toàn cục t() và context.tr()
    models/                      # Models chuyển đổi dữ liệu (user_model.dart kèm hasContract, province, ward)
      models.dart
      user_model.dart
      province_model.dart
      ward_model.dart
    network/                     # Cấu hình mạng Dio, interceptors (auth, logging), exceptions, ApiResponse
      api_client.dart
      api_exceptions.dart
      api_response.dart
    router/
      app_router.dart            # Định nghĩa AppRoutes, hàm createAppRouter() (initialLocation: AppRoutes.wrapper)
    screens/                     # Màn hình gốc & điều phối luồng người dùng
      welcome_screen.dart        # Màn hình chào mừng / chọn luồng ban đầu
      loading_screen.dart        # LoadingScreen (.show/.hide) & LoadingOverlay (wrapper)
      wrapper_screen.dart        # Router Dispatcher tự động điều phối theo role & hasContract
      home_screen.dart           # Màn hình tìm trọ (Tenant chưa có hợp đồng)
      tenant_screen.dart         # Dashboard quản lý trọ (Tenant đã có hợp đồng)
      landlord_screen.dart       # Dashboard quản lý nhà trọ (Chủ trọ & Nhân viên)
    types/                       # Các model/types tiện ích dùng chung
      app_nav_item.dart          # AppNavItem (labelKey, icon, activeIcon)
      types.dart
    validation/                  # Chuẩn hóa validation 2 tầng (ValidationConfig, Validators, FieldRules)
      app_validators.dart
    widgets/                     # UI components chuẩn hóa của Design System
      app_button.dart            # AppButton (primary, secondary, outline, isLoading)
      app_text_field.dart        # AppTextField (label, hint, error, prefix/suffix, obscure toggle)
      app_card_select.dart       # AppCardSelect (thẻ chọn vai trò/loại có icon và radio check)
      app_date_picker_field.dart # AppDatePickerField (chọn ngày tháng hiển thị theo định dạng)
      app_dropdown_field.dart    # AppDropdownField (chọn danh mục bottom sheet có search)
      app_notification.dart      # AppNotification (thông báo SnackBar chuẩn Design System)
      app_segmented_select.dart  # AppSegmentedSelect (chọn nút gạt đơn hoặc .multiple)
  features/<feature>/            # Feature-first module (ví dụ: auth)
    data/                        # datasource, model, repository implementation
    presentation/
      bloc/                      # BLoC / Cubit cho feature
      screens/                   # login_screen, register_screen, otp_screen, forgot_password_screen, reset_password_screen
  utils/
    constanst.dart               # Hằng số frontend (apiBaseUrl, logoAssetPath, UserRole, Gender)
    function_helper.dart         # Helper chung
assets/
  images/                        # Logo, icon, ảnh tĩnh
  translations/                  # vi.json, en.json (từ điển dịch cho app mobile)
test/
  widget_test.dart               # Test suite toàn diện cho widgets và luồng màn hình
```

### 4.2 Đa ngôn ngữ (i18n Mobile)
- File dịch: `assets/translations/vi.json` và `assets/translations/en.json`.
- Khởi tạo nạp trước vào cache tại `main.dart` bằng `await AppLocalizations.preload()`.
- **Cấu trúc phân nhóm key trong từ điển (`vi.json` & `en.json`):**
  - `fields`: Gom nhãn trường nhập liệu (`label`) và gợi ý (`hint`), ví dụ: `t('fields.fullName')`, `t('fields.emailHint')`.
  - `validateErrors`: Gom thông báo lỗi validation dữ liệu form, ví dụ: `t('validateErrors.fieldRequired')`, `t('validateErrors.invalidEmail')`.
  - `errors`: Gom thông báo lỗi hệ thống, mạng, HTTP status và ngoại lệ API (`api_exceptions.dart`), ví dụ: `t('errors.noInternet')`, `t('errors.timeout')`, `t('errors.unauthorized')`.
  - Cấp root (cấp ngoài): Gom các key chung như tiêu đề (`welcomeTitle`), nút bấm (`register`, `login`), tùy chọn lựa chọn vai trò/giới tính (`genderMale`, `roleTenant`,...).
- **Cú pháp dịch:**
  - Dùng hàm toàn cục `t('key', [params])`: **không cần `BuildContext`**, gọi được ở mọi nơi (Widget, Bloc, Repo, Service, Model, Utils).
  - Hoặc dùng extension `context.tr('key', [params])`.
- **Đổi ngôn ngữ:** Gọi `context.read<LocaleCubit>().setLocale(Locale('vi' | 'en'))` hoặc `toggleLocale()`. Trạng thái tự động lưu vào `FlutterSecureStorage` (key `app_locale`).

### 4.3 Design System & Reusable Widgets
- **Bảng màu & kiểu chữ:** Luôn sử dụng `DefaultColors` và `FontSizes` từ `lib/core/configs/app_theme.dart`.
  - Brand colors: `DefaultColors.primary` (`0xFF092E5D` - Navy), `DefaultColors.secondary` (`0xFFED6B25` - Cam).
- **Quy tắc UI:** Khi phát triển tính năng mới, **bắt buộc ưu tiên tái sử dụng các component chuẩn** trong `lib/core/widgets/` và `lib/core/screens/`:
  - Nút bấm: `AppButton`
  - Input: `AppTextField`
  - Lựa chọn vai trò/thẻ: `AppCardSelect`
  - Chọn ngày: `AppDatePickerField`
  - Chọn danh mục/dropdown: `AppDropdownField`
  - Lựa chọn phân đoạn/segmented: `AppSegmentedSelect`
  - Thông báo nổi: `AppNotification` (`.showSuccess`, `.showError`, `.showWarning`, `.showInfo`)
  - Loading Overlay: `LoadingScreen` (imperative qua `.show(context)` / `context.showLoading()`, `.hide(context)`) và `LoadingOverlay(isLoading: ..., child: ...)` (declarative wrapper).
- **Bottom Navigation Bar:**
  - Định nghĩa model item: `AppNavItem` (`lib/core/types/app_nav_item.dart`).
  - Danh sách hằng số dùng chung trong `lib/utils/constanst.dart`:
    - `landlordNavItems` (5 items: Trang chủ, Workspace, Quản lý trọ, Nhắn tin, Menu).
    - `tenantNavItems` (4 items: Trang chủ, Trọ của tôi, Nhắn tin, Menu).
  - Tái sử dụng `BottomNavigationBar(type: BottomNavigationBarType.fixed)` map trực tiếp từ danh sách trên kèm `label: t(item.labelKey)`.
- **Xử lý Loading toàn màn hình:** Đối với các tác vụ async / submit form (như Đăng nhập, Đăng ký, Xác thực OTP,...), **bắt buộc dùng `LoadingOverlay`** bọc màn hình (hoặc `LoadingScreen.show(context)`). Lớp phủ này hiển thị indicator chuẩn Design System, khóa toàn bộ tương tác chạm và vô hiệu hóa nút back (`PopScope(canPop: false)`), chống hiện tượng submit đúp. Không lồng thêm spinner con trên `AppButton(isLoading: true)` khi đã dùng `LoadingOverlay` để tránh lặp 2 vòng xoay cùng lúc.
- Không viết đè style hoặc dựng widget nhập liệu/button riêng lẻ gây phân mảnh giao diện.

### 4.4 State Management & Điều hướng
- Quản lý state theo `flutter_bloc` (`Bloc` cho luồng nghiệp vụ phức tạp, `Cubit` cho state đơn giản).
- Điều hướng khai báo tập trung tại `lib/core/router/app_router.dart` qua `GoRouter`. Đặt route path trong `AppRoutes`.
- **Cơ chế điều phối tự động (Wrapper Router Dispatcher):**
  - Điểm khởi đầu mặc định của ứng dụng (`initialLocation`): **`AppRoutes.wrapper`** (`WrapperScreen`).
  - Khi mở app hoặc Hot Restart, `WrapperScreen` tự động kiểm tra phiên đăng nhập từ `AuthBloc`:
    - Nếu `Unauthenticated`: chuyển về `AppRoutes.welcome`.
    - Nếu `Authenticated`:
      - `landlord` / `staff` / `admin` -> `AppRoutes.landlord` (`LandlordScreen`).
      - `tenant` + `hasContract == true` (đã thuê trọ) -> `AppRoutes.tenant` (`TenantScreen`).
      - `tenant` + `hasContract == false` (chưa thuê trọ) -> `AppRoutes.home` (`HomeScreen`).
  - `WelcomeScreen` cũng tích hợp `BlocListener` kép để chuyển sang `AppRoutes.wrapper` nếu nhận thấy state `Authenticated`.
- **Cơ chế Refresh Token ngầm & Hàng đợi Retry (Lock & FIFO Retry Queue qua `AuthInterceptor`):**
  - **Lưu trữ bảo mật:** Lưu cả `access_token`, `refresh_token`, `cached_user` và `app_locale` trong `FlutterSecureStorage`.
  - **Tránh đệ quy vô hạn:** `AuthInterceptor` sử dụng một instance `_refreshDio` độc lập (không gắn `AuthInterceptor`) để gọi `POST /api/v1/auth/refresh-token`.
  - **Khóa & Xếp hàng đợi:** Khi nhiều request đồng thời gặp mã `401 Unauthorized` do Access Token hết hạn:
    - Request đầu tiên khóa cờ `_isRefreshing = true`, đưa chính nó vào `_retryQueue` và gọi refresh ngầm.
    - Các request tiếp theo khi thấy `_isRefreshing == true` sẽ được đưa vào cuối hàng đợi `_retryQueue` và tạm dừng chờ.
    - Bỏ qua các request 401 không có `Authorization: Bearer` (như đăng nhập sai mật khẩu) hoặc 401 trên chính endpoint `/auth/refresh-token`.
  - **Replay FIFO:** Khi refresh thành công, lưu cặp token mới vào `FlutterSecureStorage`, giải phóng cờ `_isRefreshing = false`, và lần lượt replay từng request trong `_retryQueue` theo đúng thứ tự FIFO với token mới (`clientDio.fetch(options)`), resolve trực tiếp về đúng caller ban đầu (trong suốt với UI/BLoC).
  - **Fail-safe:** Nếu refresh thất bại (hết hạn refresh token hoặc bị thu hồi), toàn bộ hàng đợi bị reject và kích hoạt `onUnauthorized?.call()`.
- **Quy trình Đăng xuất & Tự động Đăng xuất (Logout & Auto-Logout):**
  - Khi người dùng đăng xuất thủ công: gửi yêu cầu `POST /auth/logout` lên server (thu hồi session trong DB và đưa vào Redis blacklist), đồng thời luôn xóa sạch cả `access_token`, `refresh_token` và `cached_user` trong `FlutterSecureStorage` (kể cả khi offline) rồi chuyển về `AppRoutes.welcome`.
  - **Tự động Đăng xuất khi 401 Unauthorized:** `AuthInterceptor` liên kết với `AuthBloc` thông qua callback `onUnauthorized` tại `main.dart`. Khi Refresh Token bị từ chối hoặc hết hạn, ứng dụng tự động phát sinh `AuthLogoutEvent()` để dọn dẹp phiên và chuyển người dùng về màn hình chào mừng.

### 4.5 Chuẩn hoá Validation (Mobile)
- Toàn bộ validation phía client đặt tập trung tại `lib/core/validation/app_validators.dart`.
- **Kiến trúc 2 tầng:**
  - `ValidationConfig`: Chứa các hằng số validate và regex dùng chung (`emailMax: 255`, `passwordMin: 8`, `passwordMax: 255`, `fullNameMax: 100`, `bioMax: 500`, `otpLength: 6`, Regex `email`, `vnPhone`). **Bắt buộc giữ đồng bộ tuyệt đối** với backend (`_backend/src/utils/ruleValidate.ts` và `<module>Schema.ts`).
  - **Tầng 1 — `Validators` (Rule nguyên tử):** Mỗi hàm chỉ kiểm tra 1 điều kiện (`compose`, `required`, `requiredValue`, `minLength`, `maxLength`, `pattern`, `email`, `vnPhone`, `digits`, `matches`).
    - Quy ước (giống `.optional()` của Zod): Mọi rule, trừ `required`, đều bỏ qua giá trị rỗng/null. Muốn bắt buộc thì ghép thêm `required()`.
    - Message lỗi được dịch động lúc validate (`t(messageKey, params)`), hỗ trợ param nội suy (`{min}`, `{max}`).
    - `compose`: Chạy lần lượt các rule và dừng lại ở lỗi đầu tiên.
  - **Tầng 2 — `FieldRules` (Rule theo từng loại field):** Tương đương `ruleValidates.*` phía backend. Cung cấp sẵn: `email({required})`, `password()`, `loginPassword()`, `confirmPassword()`, `phone({required})`, `fullName({required})`, `bio()`, `otp()`.
- **Quy tắc áp dụng:**
  - Mọi màn hình form/input (Screen/Widget) **bắt buộc ưu tiên dùng `FieldRules`** thay vì tự viết logic validate inline.
  - Với các trường chọn lựa đơn giản (dropdown, date picker, v.v.): dùng `Validators.required()`.
  - Mọi message lỗi bắt buộc khai báo trong `validateErrors.*` của cả `assets/translations/vi.json` và `en.json`.

## 5. Workflow & Definition of Done

- Trước khi code: nêu kế hoạch ngắn dạng `[step] → verify: [check]`.
- Backend: `npm run typecheck` phải pass (chạy `npm run build` khi cần) trong `_backend/`.
- Flutter: `flutter analyze` và `flutter test` phải pass (bảo đảm không làm vỡ các widget test có sẵn trong `test/widget_test.dart`).
- Đổi schema DB ⇒ **bắt buộc** có migration TypeORM kèm theo.
- Không commit `.env`, `dist/`, `node_modules/`, `.commandcode/`, `build/`.
- Không tự ý `push`/`force-push` khi chưa được yêu cầu.

## 6. Database qua MCP (read-only)

- Khi cần xem schema/index/dữ liệu: ưu tiên MCP **dbhub** (`execute_sql`, `search_objects`).
- **CHỈ chạy query đọc** (`SELECT`, `SHOW`, `EXPLAIN`); luôn kèm `LIMIT`.
- **KHÔNG** chạy `INSERT/UPDATE/DELETE/DROP/ALTER/TRUNCATE` trừ khi user yêu cầu rõ.

## 7. Checklist cuối task

- [ ] Đúng scope, không thêm gì ngoài yêu cầu.
- [ ] Tái sử dụng đúng Design System widgets (`lib/core/widgets/`), `LoadingOverlay` / `LoadingScreen` (`lib/core/screens/`) & `DefaultColors`.
- [ ] Các tác vụ submit form async phía mobile sử dụng `LoadingOverlay` / `LoadingScreen` để khóa tương tác.
- [ ] Mọi chuỗi hiển thị đều qua i18n (`t(...)` / `context.tr(...)`), bổ sung đủ cả 2 file `vi.json` và `en.json` tuân thủ đúng cấu trúc phân nhóm (`fields`, `validateErrors`, `errors`).
- [ ] Form input phía mobile validate qua `FieldRules` / `Validators` (`lib/core/validation/app_validators.dart`), đồng bộ với BE schema.
- [ ] Backend input validate qua Zod & `ruleValidates`.
- [ ] Backend response chuẩn theo `CustomResponse.success(res, data, message)` / `CustomResponse.error(res, message, errors)`.
- [ ] Typecheck (`npm run typecheck`) / analyze (`flutter analyze`) / test (`flutter test`) đều pass.
- [ ] Có migration nếu đổi schema.
- [ ] Không lộ secret, không hardcode cấu hình.

## Ghi chú cần biết

- Cả `_backend/src/utils/constanst.ts` LẪN `lib/utils/constanst.dart` đều bị **sai chính tả** (`constanst` thừa chữ `s` trước `t`). Giữ nguyên tên file này để tránh làm hỏng các import liên quan trừ khi có yêu cầu refactor toàn diện.
- `_backend/README.md` mô tả cấu trúc cũ (`entities/index.ts`, `User.ts`), nhưng cấu trúc thực tế là `entities/user.ts` (không có `index.ts`), và `entities/` dùng mixin `AuditableTrait` (`ts-mixer`).
- Thực thể `User` (`_backend/src/entities/user.ts`): Cột `language` không lưu trong bảng `users` (ngôn ngữ được truyền và xác định động qua header/query `Accept-Language`/`?lang=` theo ngữ cảnh request thông qua `i18nMiddleware`).
- Thứ tự tham số trong `CustomResponse.success` là `(res, data, message?, statusCode = 200)` — chú ý `data` đứng trước `message`.
- Khi build backend: `npm run dev` và `npm run build` có bước sao chép locales (`cp -r src/locales dist/locales`). Khi thêm key dịch mới, cần cập nhật vào cả `vi.json` và `en.json`.
