# Roomee — Quy tắc dự án

> File này được `AGENTS.md` import qua `@./.agents/rule/roomee.md`. Mọi thay đổi code trong repo phải tuân theo các quy tắc dưới đây.

## 1. Bối cảnh

- **Dự án:** Roomee (`roomee`) — ứng dụng quản lý nhà trọ / cho thuê trọ.
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
- **Các package đã cài đặt:** Argon2 (`argon2`), JWT (`jsonwebtoken`), Cron scheduler (`node-cron`), Hàng đợi BullMQ (`bullmq`).
- **Các package trong roadmap nhưng CHƯA cài:** Socket.io, Resend, Cloudinary (chỉ cài khi triển khai tính năng tương ứng).

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
    commands/                    # CLI commands độc lập (seeder.ts, cleanExpiredRedis.ts)
      seeder.ts
      cleanExpiredRedis.ts       # Script dọn dẹp các record cache hết hạn trong persist_redis
    config/                      # data-source.ts (TypeORM), redis.ts (ioredis lazyConnect)
    cron/                        # Quản lý Cronjob định kỳ nền bằng node-cron
      cleanExpiredRedisCron.ts   # Cronjob quét xóa cache hết hạn mỗi ngày (hoặc theo cấu hình)
      index.ts                   # Export startCronJobs() & stopCronJobs()
    entities/                    # Entity TypeORM (PascalCase), kế thừa Mixin(AuditableTrait)
      user.ts
      refreshToken.ts            # Quản lý phiên đăng nhập theo thiết bị & Refresh Token
      persistRedis.ts            # Lưu trữ dữ liệu dự phòng từ Redis (key, value jsonb, ttl, expiredAt)
    locales/                     # vi.json, en.json (từ điển đa ngôn ngữ cho API)
    middlewares/                 # i18nMiddleware.ts, validateMiddleware.ts, authMiddleware.ts
    migrations/                  # TypeORM migrations
    mixins/                      # auditableTrait.ts (createdAt, updatedAt, createdBy, updatedBy)
    modules/<module>/            # Mỗi tính năng 1 module thư mục
      <module>Controller.ts      # Controller xử lý req/res
      <module>Routes.ts          # Express Router đóng gói trong class @injectable()
      <module>Service.ts         # Business logic
      <module>Schema.ts          # Zod schema & DTO types (z.infer)
    queues/                      # Quản lý Hàng đợi tác vụ nền (BullMQ: Queue & Worker)
      baseQueue.ts               # Lớp cơ sở trừu tượng cho mọi Queue (tự động retry, backoff)
      baseWorker.ts              # Lớp cơ sở trừu tượng cho mọi Worker (concurrency, log, lifecycle)
      <queue_name>/              # Mỗi loại queue gom vào 1 thư mục riêng (<name>Queue.ts, <name>Worker.ts)
        mailQueue.ts
        mailWorker.ts
      index.ts                   # Export startQueueWorkers(), stopQueueWorkers(), closeAllQueues()
    repositories/                # Repository tùy biến kế thừa Repository<Entity>
      userRepository.ts
      refreshTokenRepository.ts  # Truy vấn phiên, thu hồi session theo id hoặc tokenHash
      persistRedisRepository.ts  # Thao tác bảng persist_redis (set, get còn hạn, lazy delete, clean)
    seeders/                     # Seed dữ liệu khởi tạo (DataUnitsSeeder, UserSeeder)
    services/                    # Các service hạ tầng dùng chung (Cross-cutting infrastructure)
      cacheService.ts            # Cache Layer: ghi song song Redis+DB, fallback DB & auto-rehydrate
    types/                       # express.d.ts (mở rộng Express.Request: locale, t)
    utils/
      constanst.ts               # Hằng số, Enum UserRole, Gender (chú ý chính tả file)
      customResponse.ts          # Chuẩn hoá response API
      functionHelper.ts          # Hàm tiện ích chung
      i18n.ts                    # Cơ chế i18n qua AsyncLocalStorage & hàm t() toàn cục
      ruleValidate.ts            # Reusable rules Zod (requiredString, emailRule,...)
    routes.ts                    # Class Routes @injectable() gom toàn bộ route vào API_PREFIX
    app.ts                       # Class App cấu hình Express middleware, health check, 404, error handler
    index.ts                     # Bootstrap server: kết nối DB, Redis, khởi động Cron rồi lắng nghe port
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

### 3.5 Format Response chuẩn & Xử lý lỗi (Error Handling)
- Luôn dùng `CustomResponse` (`src/utils/customResponse.ts`). **Không** tự `res.json(...)` thủ công.
- **Lưu ý thứ tự tham số:**
  - Thành công: `CustomResponse.success(res, data, message = "Success", statusCode = 200)` *(data là tham số thứ 2, đứng trước message)*.
    Format: `{ success: true, message: string, data: any }`
  - Thất bại: `CustomResponse.error(res, message = "Internal Server Error", errors = null, statusCode = 500)`.
    Format: `{ success: false, message: string, errors: any }`
- **Quy chuẩn xử lý lỗi nghiệp vụ (`AppError`):**
  - Mọi lỗi nghiệp vụ tại tầng Service phải sử dụng `AppError` (`src/utils/appError.ts`) kèm mã HTTP chuẩn:
    - `AppError.badRequest(message)`: `400` (dữ liệu/OTP/token không hợp lệ).
    - `AppError.unauthorized(message)`: `401` (sai thông tin đăng nhập, token phiên không hợp lệ/hết hạn).
    - `AppError.forbidden(message)`: `403` (tài khoản bị vô hiệu hóa, không có quyền).
    - `AppError.notFound(message)`: `404` (không tìm thấy tài nguyên/user).
    - `AppError.conflict(message)`: `409` (email/tài nguyên đã tồn tại).
    - `AppError.locked(message)`: `423` (tài khoản bị tạm khóa do nhập sai nhiều lần).
    - `AppError.tooManyRequests(message)`: `429` (vượt tần suất gửi OTP / rate limit).
  - Controller bắt lỗi và chuyển giao cho Express qua `next(error)`.
  - **Global Error Handler** (`src/app.ts`) tự động phân loại:
    - Nếu là `AppError`: Trả đúng status code và message nghiệp vụ tương ứng.
    - Nếu là lỗi hệ thống / DB không mong muốn: Ghi log chi tiết trên server (`console.error`), trả về `500` kèm message chung `t("common.internalServerError")`, tuyệt đối **không để lộ chi tiết câu lệnh SQL hay stack trace** ra client.

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

### 3.8 Cache, Redis & Cơ chế Persist/Fallback
- Cấu hình qua `REDIS_URL` trong `.env`, khởi tạo trong `src/config/redis.ts` với `lazyConnect: true`.
- Kết nối tường minh khi start server (`connectRedis()`) và đóng gracefully khi tắt (`closeRedis()`).
- **Quy tắc bắt buộc khi thao tác Cache:** Mọi controller, service, middleware **bắt buộc sử dụng `CacheService`** (`src/services/cacheService.ts`), không gọi trực tiếp `redis` (trừ health check hoặc ngoại lệ đặc thù).
- **Cơ chế Persist xuống Database (`persist_redis`):**
  - Mọi thao tác ghi (`cacheService.set`, `setNx`, `incr`) đều được ghi đồng thời vào bảng `persist_redis` (PostgreSQL) với `key` (PK), `value` (`jsonb`), `ttl` (giây) và `expiredAt` (timestamp).
- **Cơ chế Fallback & Auto-Rehydration:**
  - Khi gọi `cacheService.get<T>(key)`: Ưu tiên đọc từ Redis.
  - **Phân biệt Cache Miss vs Cache Failure:** Nếu Redis đang online và trả về `null` (Cache Miss), `CacheService` trả về `null` ngay lập tức (< 1ms), **tuyệt đối không query xuống Postgres**.
  - **Chỉ fallback xuống DB khi Redis sập/lỗi kết nối:** Khi Redis xảy ra sự cố không thể kết nối, hệ thống mới truy vấn bảng `persist_redis` (`expiredAt IS NULL OR expiredAt > NOW()`).
  - Nếu tìm thấy dữ liệu còn hạn trong DB: tự động tính TTL còn lại và nạp ngược lại (**rehydrate**) lên Redis khi Redis online trở lại.
- **Tự động nhận diện kiểu dữ liệu (JSON vs String):**
  - `cacheService.get<T>(key)` tự động parse thành Object/Array nếu dữ liệu bắt đầu bằng `{` hoặc `[`.
  - Giữ nguyên kiểu chuỗi (`string`) nếu là chuỗi thông thường (OTP, email, token, cờ boolean) để tránh lỗi ép kiểu ngoài ý muốn.
- **Xóa đồng bộ (`cacheService.del`):**
  - Luôn xóa key ở cả Redis và Database cùng lúc, chống tái sử dụng token hoặc OTP cũ khi có sự cố.
- **Thao tác đếm tăng dần (`cacheService.incr` - Chống lệch TTL):**
  - Khi tăng `count > 1`, phương thức `setKey(..., { preserveTtl: true })` chỉ cập nhật cột `value` trên PostgreSQL (`ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value"`) và giữ nguyên `expiredAt` ban đầu, chống triệt để lỗi cộng dồn thời gian (TTL Drift) giữa Redis và Database.
- **Dọn dẹp cache hết hạn (Expiration Cleanup):**
  - **In-app Cron (`node-cron`):** Tự động kích hoạt khi server start (`src/cron/`), cấu hình qua `CLEAN_PERSIST_REDIS_CRON` (mặc định chạy 00:00 hàng ngày: `"0 0 * * *"`), có cờ `noOverlap: true`.
  - **CLI Command:** Chạy độc lập qua `src/commands/cleanExpiredRedis.ts` (`npm run clean:redis` / `npm run clean:redis:prod`).
  - **Lazy Delete:** Khi `getValidKey` phát hiện record đã hết hạn nhưng cronjob chưa kịp chạy, hệ thống tự động xóa record đó trong background và trả về `null`.

### 3.9 Lệnh thường dùng
- `npm run dev` (chạy song song tsc và node qua `scripts/dev.mjs`, tự copy locales)
- `npm run typecheck` (`tsc --noEmit`)
- `npm run build` (`tsc && cp -r src/locales dist/locales`)
- `npm run start` (`node dist/index.js`)
- `npm run clean:redis` (chạy command quét và dọn dẹp các record cache hết hạn trong `persist_redis`)
- `npm run clean:redis:prod` (chạy command dọn dẹp cache hết hạn trên môi trường production)
- Migration: `npm run migration:generate|run|revert|show`

### 3.10 Authentication & Security
- **Mật khẩu & Băm:** Bắt buộc băm mật khẩu bằng Argon2 (`argon2.hash`). Khi query kiểm tra mật khẩu trong `AuthService`, dùng `userRepository.findByEmailWithPassword()` do trường `password` có cấu hình `{ select: false }`.
- **JWT Security & Chuẩn hóa Token:**
  - `jwt.verify()` bắt buộc chỉ định rõ `{ algorithms: ["HS256"] }` trong `authMiddleware` để triệt tiêu lỗ hổng Algorithm Confusion và None Algorithm Attack.
  - Response đăng nhập và refresh token chuẩn hóa theo RFC 6749, chỉ sử dụng cặp trường `accessToken` và `refreshToken` (không trả trường `token` trùng lặp).
- **Cặp Token (Access Token & Refresh Token) & Quản lý Phiên (Session Management):**
  - **Access Token:** Hạn ngắn **15 phút** (`ACCESS_TOKEN_EXPIRES_IN = "15m"`). Payload chứa: `{ sub: user.id, email: user.email, role: user.role, sid: session.id }`.
  - **Refresh Token:** Hạn **7 ngày** (`REFRESH_TOKEN_EXPIRES_IN_DAYS = 7`, sliding session). Được sinh ngẫu nhiên 64 ký tự hex an toàn, băm mã hóa SHA-256 (`tokenHash`, đánh `UNIQUE`) và lưu trữ trong bảng `refresh_tokens` (đại diện cho một phiên thiết bị duy nhất, không tạo dòng mới khi refresh).
  - **Xoay vòng Token (Refresh Token Rotation - RTR) & Giữ nguyên `sid`:**
    - Mỗi khi gọi `POST /api/v1/auth/refresh-token`, hệ thống **giữ nguyên `sid` (`session.id`)** và cập nhật nguyên tử trên DB: `previousTokenHash = currentTokenHash`, `tokenHash = newTokenHash`, `rotatedAt = NOW()`, gia hạn `expiresAt` thêm 7 ngày.
    - **Không blacklist `sid` khi refresh:** Các request đang bay dở mang Access Token cũ vẫn hoàn tất bình thường vì `sid` của chúng không bị đưa vào blacklist.
    - **Phát hiện dùng lại Token (Token Reuse Detection) & Grace Period:**
      - Nếu token gửi lên khớp với `previousTokenHash` trong vòng **15 giây** (`rotatedAt` Grace Period do mạng lag gửi lại): Cấp lại Access Token hợp lệ mà không khóa phiên.
      - Nếu gửi lại token cũ sau 15 giây hoặc câu update không thành công: Phát hiện kẻ gian đánh cắp token $\rightarrow$ Lập tức thu hồi toàn bộ phiên của người dùng (`revokeAllUserSessions`) và blacklist `sid` ngay lập tức.
- **Thu hồi phiên tức thời (Instant Revocation qua Redis):**
  - Trong `authMiddleware`, kiểm tra nhanh trong Redis `blacklist:session:${decoded.sid}`.
  - **Chỉ đưa `sid` vào Redis blacklist khi:** Người dùng chủ động Đăng xuất (`POST /auth/logout`), Admin thu hồi phiên từ xa, hoặc khi phát hiện Token Reuse Attack. Tuyệt đối không blacklist `sid` trong quá trình Refresh Token Rotation thông thường.
- **Cơ chế Tạm khóa tài khoản (Account Lockout qua Redis - Chống DoS):**
  - Giới hạn: `MAX_LOGIN_ATTEMPTS = 5`.
  - Khóa theo cặp `email + IP`: `login:lockout:{email}:{ip}` (TTL 15p) và `login:attempts:{email}:{ip}`. Nếu kẻ xấu cố tình spam sai mật khẩu, chỉ có IP của kẻ xấu bị khóa, chủ tài khoản thật từ IP khác vẫn đăng nhập bình thường.
  - Bộ đếm `login:attempts:{email}:{ip}` được xóa sạch ngay khi đăng nhập đúng mật khẩu.
  - Khi đặt lại mật khẩu thành công (`resetPassword`), toàn bộ key lockout trên các IP của email đó được xóa sạch (`login:*:{email}:*`).
- **Chống dò quét tài khoản (User Enumeration Defense):**
  - Trạng thái tài khoản `isActive` **bắt buộc kiểm tra SAU KHI** đã xác thực đúng mật khẩu qua `argon2.verify()`. Nếu sai mật khẩu, luôn trả về `401 Unauthorized` chung nhằm che giấu sự tồn tại hoặc trạng thái kích hoạt của tài khoản.
  - Khi đăng nhập vào tài khoản chưa xác thực email (`!user.isEmailVerified`), nếu việc gửi mail OTP thất bại, lập tức xóa `cooldownKey` để người dùng không bị kẹt 60 giây và có thể gửi lại.
- **Quên mật khẩu (Forgot Password qua OTP + Reset Token):**
  - Bước 1: `POST /auth/forgot-password` -> Gửi mã OTP 6 số qua email (Redis TTL 10p, cooldown 60s, chống user enumeration).
  - Bước 2: `POST /auth/verify-reset-otp` -> Xác thực OTP -> Cấp `resetToken` (UUID, Redis TTL 15p).
  - Bước 3: `POST /auth/reset-password` -> Đặt mật khẩu mới với `resetToken` (dùng 1 lần duy nhất, cập nhật Argon2, thu hồi toàn bộ session đang đăng nhập qua `revokeAllUserSessions(user.id)`, xóa token và giải phóng lockout).
- **Đăng xuất (Logout & Thu hồi Phiên):**
  - Endpoint `POST /auth/logout` bảo vệ bằng `authMiddleware`.
  - Server giải mã JWT, lấy `sid` và thời gian sống còn lại (`exp - now`).
  - Đánh dấu phiên `isRevoked = true` trong database qua `refreshTokenRepository.revokeBySessionId(sid)`.
  - Đưa `blacklist:session:{sid}` vào Redis + DB (CacheService) với TTL tương ứng (thời gian sống còn lại của Access Token).
- **Rate Limiting & Proxy Trust:**
  - Cấu hình `app.set("trust proxy", ...)` qua biến môi trường `TRUST_PROXY` (mặc định: `1`) để Express nhận diện chính xác `req.ip` khi đứng sau Nginx / Reverse Proxy.
  - Rate Limiter (`rateLimitMiddleware.ts`) sử dụng `express-rate-limit` theo dõi IP client qua `req.ip` với cấu hình theo từng endpoint (login: 10/phút, register: 10/15p, OTP: 3-10/phút).
  - Cắt ngắn độ dài đầu vào của `ipAddress` (tối đa 45 ký tự) và `deviceInfo` (tối đa 255 ký tự) ở cả Controller và Service để bảo đảm không bị lỗi DB overflow (500).
- **Hàng đợi tác vụ nền (BullMQ Queue & Worker Architecture):**
  - Cấu trúc thư mục tại `src/queues/`: Gom theo từng tính năng (`src/queues/<feature>/`), ví dụ `src/queues/mail/mailQueue.ts` và `mailWorker.ts`.
  - Mọi Queue kế thừa `BaseQueue<T>` (`src/queues/baseQueue.ts`), tự động có kết nối Redis độc lập (`maxRetriesPerRequest: null`), cơ chế retry 3 lần kèm exponential backoff (2s, 4s, 8s) và tự động dọn dẹp job cũ.
  - Mọi Worker kế thừa `BaseWorker<T>` (`src/queues/baseWorker.ts`), tự động quản lý concurrency (mặc định 5), log sự kiện job completed/failed/error.
  - Quản lý vòng đời tập trung qua `src/queues/index.ts` (`startQueueWorkers()`, `stopQueueWorkers()`, `closeAllQueues()`), tích hợp đồng bộ vào `App.listen()` và Graceful Shutdown của Express.
  - Toàn bộ các luồng gửi OTP (`register`, `forgotPassword`, `resendOtp`, `login` chưa verify) đều đẩy qua `mailQueue.addSendOtpJob()`. Nhờ đó API phản hồi tức thì (< 5ms) và triệt tiêu hoàn toàn nguy cơ tấn công đo thời gian (Timing Attack) ở `forgotPassword`.
- **Lấy thông tin người dùng hiện tại (Endpoint `GET /api/v1/auth/me`):**
  - Bảo vệ bằng `authMiddleware`.
  - Lấy `userId = req.user.sub`, truy vấn DB kèm quan hệ `province`, `ward`, loại bỏ `password` và trả về profile người dùng mới nhất (`role`, `hasContract`, `isActive`,...).
  - Nếu user không tồn tại hoặc `isActive: false` $\rightarrow$ ném `AppError.forbidden`.
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
- **Cơ chế điều phối tự động (Wrapper Router Dispatcher) & Stale-While-Revalidate:**
  - Điểm khởi đầu mặc định của ứng dụng (`initialLocation`): **`AppRoutes.wrapper`** (`WrapperScreen`).
  - Khi mở app hoặc Hot Restart, `AuthBloc` kích hoạt `AuthCheckEvent` theo chiến lược **Stale-While-Revalidate**:
    - **Bước 1:** Đọc ngay `cachedUser` từ `FlutterSecureStorage` và emit `Authenticated(user: cachedUser)` tức thì (độ trễ 0ms) để UI render mượt mà, không bị màn hình trắng/spinner chờ mạng.
    - **Bước 2:** Gọi song song `GET /api/v1/auth/me` (`syncUserProfile`) lên server để làm tươi thông tin mới nhất:
      - Nếu `role` hoặc `hasContract` trên máy chủ đã thay đổi (ví dụ: tenant vừa ký hợp đồng mới $\rightarrow$ `hasContract: true`): Lưu đè `freshUser` vào storage và emit lại `Authenticated(user: freshUser)`. `WrapperScreen` sẽ tự động bắt sự kiện và chuyển tiếp người dùng sang đúng màn hình mới ([TenantScreen](lib/core/screens/tenant_screen.dart)).
      - Nếu token hết hạn hoặc tài khoản bị khóa (`401`/`403`): emit `Unauthenticated()` và chuyển về `WelcomeScreen`.
      - Nếu mất mạng (Offline): Giữ nguyên `cachedUser` để người dùng tiếp tục xem dữ liệu offline.
  - **Tự động làm tươi khi App chuyển từ Background lên Foreground:** `MyApp` (`lib/main.dart`) kế thừa `WidgetsBindingObserver` để lắng nghe `AppLifecycleState.resumed`. Khi người dùng chuyển app sang ứng dụng khác rồi quay lại, app tự động kích hoạt `AuthCheckEvent()` để làm tươi thông tin mới nhất (`hasContract`, `role`, `isActive`) từ server.
  - `WelcomeScreen` cũng tích hợp `BlocListener` kép để chuyển sang `AppRoutes.wrapper` nếu nhận thấy state `Authenticated`.
- **Cơ chế Refresh Token ngầm & Hàng đợi Retry (Lock & FIFO Retry Queue qua `AuthInterceptor`):**
  - **Lưu trữ bảo mật:** Lưu cả `access_token`, `refresh_token`, `cached_user` và `app_locale` trong `FlutterSecureStorage`.
  - **Tránh đệ quy vô hạn:** `AuthInterceptor` sử dụng một instance `_refreshDio` độc lập (không gắn `AuthInterceptor`) để gọi `POST /api/v1/auth/refresh-token`.
  - **Khóa & Xếp hàng đợi:** Khi nhiều request đồng thời gặp mã `401 Unauthorized` do Access Token hết hạn:
    - Request đầu tiên khóa cờ `_isRefreshing = true`, đưa chính nó vào `_retryQueue` và gọi refresh ngầm.
    - Các request tiếp theo khi thấy `_isRefreshing == true` sẽ được đưa vào cuối hàng đợi `_retryQueue` và tạm dừng chờ.
    - Bỏ qua các request 401 không có `Authorization: Bearer` (như đăng nhập sai mật khẩu) hoặc 401 trên chính endpoint `/auth/refresh-token`.
  - **Replay FIFO & Chốt chặn Vòng lặp Vô hạn (Circuit Breaker):**
    - **Chốt chặn lặp:** Đầu hàm `onError`, nếu `err.requestOptions.extra['retried'] == true` thì lập tức dừng lại và gọi `handler.next(err)`, đảm bảo mỗi request chỉ được retry tối đa 1 lần duy nhất, tránh nguy cơ lặp vô hạn nếu server vẫn trả về 401.
    - **Chống Refresh thừa (Fast-path Staleness Check):** So sánh `sent` token với `current` token trong `FlutterSecureStorage`. Nếu `sent != current` (nghĩa là token đã được một request khác refresh trước đó), lập tức gán token mới, đánh dấu `extra['retried'] = true` và fetch lại ngay mà KHÔNG gọi API refresh thừa thãi.
    - **Replay FIFO:** Khi refresh thành công, lưu cặp token mới vào `FlutterSecureStorage`, giải phóng cờ `_isRefreshing = false`, và lần lượt replay từng request trong `_retryQueue` theo đúng thứ tự FIFO với token mới và cờ `options.extra['retried'] = true` (`clientDio.fetch(options)`), resolve trực tiếp về đúng caller ban đầu (trong suốt với UI/BLoC).
  - **Fail-safe:** Nếu refresh thất bại do lỗi danh tính (401/403), toàn bộ hàng đợi bị reject và kích hoạt `onUnauthorized?.call()`.
  - **Xử lý Lỗi Môi trường (Transient Failure) & Màn hình NoInternetScreen:**
    - Khi quá trình refresh token gặp lỗi:
      - **Lỗi danh tính (401 / 403 / mất refresh token trong storage):** Hết hạn phiên thực sự $\rightarrow$ Reject hàng đợi và kích hoạt `onUnauthorized?.call()` để tự động đăng xuất.
      - **Lỗi môi trường (Mất mạng, Timeout, Server 5xx):** Tuyệt đối **KHÔNG** gọi `onUnauthorized`. Giữ nguyên `_retryQueue`, kích hoạt Timer 10 phút giải phóng bộ nhớ nếu không tương tác, đồng thời hiển thị `NoInternetScreen.show(context)` (`PopScope(canPop: false)` chặn nút back/cử chỉ vuốt để bảo vệ BLoC bên dưới không bị `close()`).
    - Nút **"Thử lại"** trên `NoInternetScreen`: Đặt `isLoading = true`, ping `/api/health` để kiểm tra kết nối Internet thực tế. Nếu thành công: Gọi `retryPendingQueue()` để replay toàn bộ request dang dở, đóng `NoInternetScreen` và hiển thị `AppNotification.showSuccess`. Nếu vẫn mất mạng: hiển thị `AppNotification.showWarning`.
    - **Lộ trình Offline Mode:** Thiết kế này hoàn toàn độc lập; khi sau này triển khai Offline Mode (Local DB + SyncManager), chỉ cần gỡ bỏ `NoInternetScreen` hoặc thay bằng thanh banner nhỏ trên cùng mà không làm ảnh hưởng tới core network logic.
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
- [ ] Thao tác Cache/Redis phía backend phải qua `CacheService` để đồng bộ persist và fallback DB.
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
