# Roomee — Quy tắc dự án

> File này được `AGENTS.md` import qua `@./.agents/rule/roomee.md`. Mọi thay đổi code trong repo phải tuân theo các quy tắc dưới đây.

## 1. Bối cảnh

- **Dự án:** Roomee (`thue_tro`) — ứng dụng quản lý nhà trọ / cho thuê trọ.
- **Hai phần:**
  - `_backend/` — API server Node.js + TypeScript (Express, TypeORM, PostgreSQL).
  - `lib/` (repo root) — ứng dụng Flutter (mobile).
- **Roadmap & tech stack:** theo `Roomee1.xlsx` (sheet `Tech` và `Module`). Các module chính: đăng ký/đăng nhập/OTP/reset mật khẩu, quản lý workspace (chủ trọ + nhân sự), quản lý nhân sự, phân quyền theo role, gán/thu hồi quyền tạm (merge `true + false = true`), realtime cập nhật phân quyền.
- **Ngôn ngữ:** luôn phản hồi bằng **tiếng Việt**.

### Tech stack (theo sheet `Tech`)

**Backend (`_backend/`):**
- **Runtime/ngôn ngữ:** Node.js, TypeScript (ESM, `strict`)
- **Web framework:** Express
- **ORM/DB:** TypeORM + PostgreSQL
- **Validation:** Zod
- **Auth:** JWT + Argon2 (hash mật khẩu)
- **Realtime:** Socket.io
- **Queue/job nền:** BullMQ + Valkey (dùng env `REDIS_URL`)
- **Cronjob:** node-cron
- **Mail:** Resend
- **Upload file/ảnh:** Cloudinary
- **Mixin/trait:** ts-mixer
- **DI:** tsyringe

**Mobile (`lib/`):**
- **Framework:** Flutter + Dart (SDK `^3.13.5`) — phát triển Android/iOS
- **State management:** `flutter_bloc`; `bloc` + `bloc_concurrency` (xử lý sự kiện, kiểm soát tác vụ đồng thời)
- **Điều hướng / deep link:** `go_router` (route guard)
- **Network:** `dio` (REST API, interceptor, upload/download)
- **Model / DTO / JSON:** `freezed` + `json_serializable`
- **DI:** `get_it` (service, repository, dependency)
- **Lưu credential:** `flutter_secure_storage`
- **Realtime:** `socket_io_client` (chat, sự kiện realtime)
- **Push notification (nền):** `firebase_messaging`
- **Cache ảnh:** `cached_network_image`
- **Chọn ảnh/tệp:** `image_picker` + `file_picker`
- **Định dạng:** `intl` (ngày tháng, tiền tệ, hiển thị)
- **Lint:** `flutter_lints` (`analysis_options.yaml`)

> **Lưu ý:** các package backend trong sheet `Tech` (Zod, argon2, jsonwebtoken, socket.io, bullmq, ioredis, node-cron, resend, cloudinary) hiện **chưa cài** trong `_backend/package.json`, và các package mobile (flutter_bloc, go_router, dio, freezed, json_serializable, get_it, flutter_secure_storage, socket_io_client, firebase_messaging, cached_network_image, image_picker, file_picker, intl) cũng **chưa cài** trong `pubspec.yaml` — chỉ cài khi triển khai module/feature tương ứng, không cài thừa trước.

## 2. Nguyên tắc chung (bắt buộc)

1. **Nghĩ trước khi code** — nêu giả định rõ ràng; nếu mơ hồ thì hỏi; nếu có nhiều cách hiểu thì trình bày trade-off, không tự chọn âm thầm; nếu có cách đơn giản hơn thì đề xuất.
2. **Đơn giản trước** — code tối thiểu giải quyết đúng yêu cầu; không thêm feature/abstraction/config ngoài yêu cầu; không xử lý lỗi cho tình huống bất khả thi.
3. **Thay đổi tối thiểu (surgical)** — chỉ sửa đúng chỗ cần; không "cải thiện" code/comment/format xung quanh; giữ style hiện có; chỉ xóa import/biến mồ côi do chính thay đổi của mình tạo ra; không xóa dead code sẵn có trừ khi được yêu cầu.
4. **Hướng mục tiêu** — biến task thành mục tiêu kiểm chứng được (`[step] → verify: [check]`) và lặp tới khi pass.

## 3. Backend (`_backend/`)

### 3.1 Module system & ngôn ngữ
- ESM: `"type": "module"`, `moduleResolution: NodeNext`. Mọi import nội bộ **phải có đuôi `.js`** (vd `import { App } from "./app.js"`).
- TypeScript `strict`; hạn chế `any`; decorators đã bật (`experimentalDecorators`, `emitDecoratorMetadata`).

### 3.2 Cấu trúc thư mục
```text
src/
  entities/<ten>.ts              # TypeORM entity (class PascalCase)
  repositories/<ten>Repository.ts
  modules/<module>/
    <module>Controller.ts
    <module>Routes.ts
    <module>Service.ts           # + schema Zod của module nếu cần
  migrations/
  utils/                         # customResponse.ts, constanst.ts, functionHelper.ts
  config/                        # data-source.ts (TypeORM DataSource), redis.ts (ioredis client)
  routes.ts                      # nơi đăng ký toàn bộ routes
  app.ts                         # Express app, middleware, error handler
  index.ts                       # bootstrap (kết nối DB rồi listen)
```
- Mỗi feature mới = **1 thư mục trong `modules/`** gồm đủ Controller + Routes + Service.
- Đăng ký routes trong `src/routes.ts`, **không** rải vào `app.ts`.

### 3.3 DI (tsyringe)
- Dùng `@injectable()` cho Controller/Service/Repository; inject qua constructor.
- Repository tùy biến kế thừa `Repository<Entity>` và gọi `super(Entity, AppDataSource.manager)` (theo `userRepository.ts`).

### 3.4 Validation
- **Mọi input client (body/query/params) phải validate bằng Zod** trước khi dùng. Không đọc thẳng `req.body` mà không validate.
- Lỗi validate trả `CustomResponse.error(res, message, errors, 400)`.

### 3.5 Response
- Luôn dùng `CustomResponse.success(...)` / `CustomResponse.error(...)` (`src/utils/customResponse.ts`). Không `res.json(...)` thủ công.
- Format: `{ success: true, message, data }` hoặc `{ success: false, message, errors }`.

### 3.6 Xử lý lỗi
- Định nghĩa `AppError` (gồm `statusCode`, `message`, `errors?`) trong `src/utils/`.
- Service throw `AppError`; error handler trung tâm ở `app.ts` map ra response. Không try/catch rải rác trả 500 thủ công.

### 3.7 Auth & bảo mật
- Hash mật khẩu bằng **argon2** (KHÔNG dùng bcrypt).
- Token bằng **JWT**; secret lấy từ env (`JWT_SECRET`), **không hardcode**.
- OTP/gửi mail qua **Resend**; reset mật khẩu qua deep-link mở app.

### 3.8 Database & Migration
- **Không bật `synchronize`**. Mọi thay đổi schema phải qua migration.
- Quy trình: sửa entity → `npm run migration:generate -- src/migrations/<TenMigration>` → review file migration → `npm run migration:run`.
- Không sửa migration đã chạy; cần đổi thì tạo migration mới.
- Đặt tên bảng snake_case số nhiều (`users`); giữ cột camelCase như hiện có (`fullName`, `createdAt`...).

### 3.9 Realtime / queue / cron / upload / mixin
- Realtime: **Socket.io**.
- Job nền: **BullMQ** + **Valkey** (dùng env `REDIS_URL`).
- Cronjob: **node-cron**.
- Upload file/ảnh: **Cloudinary**.
- Mixin/trait: **ts-mixer**.

### 3.10 Naming
- File: camelCase (`authController.ts`, `userRepository.ts`); class/enum PascalCase; biến/hàm camelCase; hằng UPPER_SNAKE.
- Comment ngắn gọn, rõ nghĩa; không thêm comment thừa.

### 3.11 Lệnh thường dùng
- `npm run dev` · `npm run typecheck` · `npm run build`
- Migration: `npm run migration:generate|run|revert|show`

## 4. Flutter (root `lib/`)

- SDK `^3.13.5`; tuân thủ `flutter_lints` trong `analysis_options.yaml`; code mới **không để warning** từ `flutter analyze`.
- Cấu trúc feature-first (đề xuất, giữ `main.dart` làm entry):
```text
lib/
  main.dart
  app.dart
  core/                 # network, theme, constants, router
  features/<feature>/
    data/               # model, api client, repository
    domain/             # entity, usecase (nếu cần)
    presentation/       # page, widget, state
```
- **State management:** dùng **Bloc** (`flutter_bloc`, `bloc`, `bloc_concurrency`) — không tự ý thêm thư viện khác.
- **Điều hướng:** `go_router` (deep link, route guard).
- **Network:** 1 lớp tập trung dùng `dio` (interceptor, upload/download); base URL lấy từ config/env; giải mã response theo format backend `{ success, message, data }`.
- **Model/DTO:** `freezed` + `json_serializable`; **DI:** `get_it`; **credential:** `flutter_secure_storage`; **realtime:** `socket_io_client`; **push nền:** `firebase_messaging`; **cache ảnh:** `cached_network_image`; **chọn ảnh/tệp:** `image_picker` + `file_picker`; **định dạng:** `intl`.
- Naming Dart: file `snake_case`; class `PascalCase`; biến/hàm `camelCase`.
- Font/asset khai báo trong `pubspec.yaml`.

## 5. Workflow & Definition of Done

- Trước khi code: nêu kế hoạch ngắn dạng `[step] → verify: [check]`.
- Backend: `npm run typecheck` phải pass (chạy `npm run build` khi cần) trong `_backend/`.
- Flutter: `flutter analyze` và `flutter test` phải pass.
- Đổi schema ⇒ **bắt buộc** có migration kèm theo.
- Không commit `.env`, `dist/`, `node_modules/`, `.commandcode/`.
- Không tự ý `push`/`force-push` khi chưa được yêu cầu.

## 6. Database qua MCP (read-only)

- Khi cần xem schema/index/dữ liệu: ưu tiên MCP **dbhub** (`execute_sql`, `search_objects`).
- **CHỈ chạy query đọc** (`SELECT`, `SHOW`, `EXPLAIN`); luôn kèm `LIMIT`.
- **KHÔNG** chạy `INSERT/UPDATE/DELETE/DROP/ALTER/TRUNCATE` trừ khi user yêu cầu rõ.

## 7. Checklist cuối task

- [ ] Đúng scope, không thêm gì ngoài yêu cầu.
- [ ] Tuân thủ cấu trúc & convention ở trên.
- [ ] Typecheck / analyze / test pass.
- [ ] Có migration nếu đổi schema.
- [ ] Không lộ secret, không hardcode cấu hình.

## Ghi chú cần biết

- `_backend/src/utils/constanst.ts` bị **sai chính tả** (đúng ra là `constants.ts`). Giữ nguyên trừ khi được yêu cầu đổi tên — nếu đổi phải cập nhật mọi import liên quan.
- `_backend/README.md` mô tả cấu trúc có `entities/index.ts` và `User.ts` nhưng thực tế là `entities/user.ts` (không có `index.ts`) — bám theo code thực tế.
