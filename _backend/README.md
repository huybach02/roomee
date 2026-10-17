# Roomee Backend Server

Server backend được xây dựng với **Node.js**, **Express.js**, **TypeScript**, và **TypeORM** (kết nối PostgreSQL).

---

## 📁 Cấu trúc thư mục

```text
_backend/
├── src/
│   ├── config/
│   │   ├── data-source.ts # Khai báo DataSource chính của TypeORM
│   │   └── redis.ts      # Redis client (ioredis) khởi tạo từ REDIS_URL
│   ├── entities/         # Khai báo TypeORM Entities
│   │   ├── index.ts      # Export tất cả entities
│   │   └── user.ts       # Entity người dùng mẫu
│   ├── middlewares/      # Middleware dùng chung (validate Zod,...)
│   ├── migrations/       # Các file migration do TypeORM sinh ra
│   ├── modules/          # Các module tính năng (auth, room,...)
│   │   └── auth/         # authController.ts, authRoutes.ts, authService.ts, authSchema.ts
│   ├── app.ts            # Cấu hình Express app, middlewares, error handler
│   └── index.ts          # Entry point khởi chạy HTTP server và kết nối DB
├── scripts/
│   └── dev.mjs           # Dev runner đa nền tảng (tsc --watch + node --watch)
├── dist/                 # Mã JavaScript sau khi biên dịch (tsc)
├── .env                  # Biến môi trường cục bộ (PORT, DATABASE_URL,...)
├── .env.example          # Mẫu file cấu hình môi trường
├── .gitignore            # Bỏ qua node_modules, dist, .env,...
├── tsconfig.json         # Cấu hình TypeScript compiler (experimentalDecorators,...)
├── package.json          # Dependencies và scripts
└── README.md             # Hướng dẫn sử dụng
```

---

## 🚀 Hướng dẫn cài đặt & khởi chạy

### 1. Cài đặt dependencies

```bash
cd _backend
npm install
```

### 2. Thiết lập biến môi trường

Nếu chưa có file `.env`:

```bash
cp .env.example .env
```

Cấu hình các biến trong `.env`:

```env
PORT=5000
NODE_ENV=development
DATABASE_URL="postgresql://username:password@host:port/database"
REDIS_URL="redis://username:password@host:port/database"
```

---

## 🗄️ Quản lý Database & Migrations với TypeORM

Hệ thống sử dụng cơ chế **Migration** của TypeORM để quản lý schema database mà không cần bật `synchronize: true` (an toàn cho dữ liệu).

### 1. Tự động sinh file migration từ Entity (`migration:generate`)

Khi bạn thêm mới entity hoặc thay đổi các cột trong thư mục `src/entities/`:

```bash
npm run migration:generate -- src/migrations/<TenMigration>
```

_Ví dụ:_

```bash
npm run migration:generate -- src/migrations/CreateUsersTable
```

### 2. Thực thi các migrations chưa chạy (`migration:run`)

Áp dụng các thay đổi vào database:

```bash
npm run migration:run
```

### 3. Rollback migration gần nhất (`migration:revert`)

Hoàn tác migration vừa thực thi gần nhất:

```bash
npm run migration:revert
```

### 4. Kiểm tra trạng thái các migration (`migration:show`)

Hiển thị danh sách migration đã chạy `[X]` hoặc chưa chạy `[ ]`:

```bash
npm run migration:show
```

### 5. Tạo một file migration rỗng thủ công (`migration:create`)

Nếu muốn viết SQL trực tiếp:

```bash
npm run migration:create -- src/migrations/<TenMigration>
```

### 6. Chạy migration trên môi trường Production (sau khi build `tsc`)

```bash
npm run migration:run:prod
npm run migration:revert:prod
npm run migration:show:prod
```

---

## 🧠 Redis

Client Redis dùng **ioredis**, khởi tạo trong `src/config/redis.ts` từ biến môi trường `REDIS_URL` (không hardcode cấu hình).

```env
# redis://user:password@host:port/db  — dùng rediss:// nếu server bật TLS
REDIS_URL="redis://username:password@host:port/0"
```

- Client được tạo với `lazyConnect: true`, kết nối tường minh qua `connectRedis()` khi server khởi động (sau khi kết nối PostgreSQL). Nếu không kết nối được, server dừng ngay (`exit 1`) để phát hiện lỗi cấu hình sớm.
- Runtime tự động reconnect khi mất kết nối; đóng kết nối trong graceful shutdown (`closeRedis()`).
- Trạng thái Redis được phản ánh ở `GET /api/health` (field `redis`).
- Dùng chung client `redis` (import từ `src/config/redis.ts`) cho cache, Socket.io adapter, BullMQ,...

---

## 🖥️ Các lệnh chạy server

- **Chế độ phát triển (tự build lại và tự khởi động lại khi sửa file `.ts`):**

  ```bash
  npm run dev
  ```

  Chạy được trên **Windows / macOS / Linux** (không phụ thuộc cú pháp shell `&`).
  Cơ chế: `predev` build một lần vào `dist/`, sau đó chạy song song `tsc --watch` (biên dịch lại khi file trong `src/` thay đổi) và `node --watch dist/index.js` (khởi động lại server khi `dist/` thay đổi).

  > Dev và Production dùng **cùng một runtime** là `node dist/index.js` trên output của `tsc`, nên kết quả ở local phản ánh đúng hành vi production.

- **Kiểm tra kiểu dữ liệu (Type check):**

  ```bash
  npm run typecheck
  ```

- **Biên dịch sang JavaScript (Build):**

  ```bash
  npm run build
  ```

- **Chế độ Production (chạy bản build trong `dist/`):**
  ```bash
  npm start
  ```

---

## 📡 Các endpoint có sẵn

| Phương thức | Đường dẫn     | Mô tả                                                       |
| ----------- | ------------- | ----------------------------------------------------------- |
| `GET`       | `/`           | Thông tin cơ bản server                                     |
| `GET`       | `/api`        | Root endpoint của API                                       |
| `GET`       | `/api/health` | Kiểm tra tình trạng server, kết nối PostgreSQL và Redis     |
| `POST`      | `/api/v1/auth/register` | Đăng ký tài khoản (body: `username`, `email`, `password`) |
| `POST`      | `/api/v1/auth/login`    | Đăng nhập (body: `email`, `password`) |

---

## ✅ Validate dữ liệu đầu vào (Zod)

Mọi input từ client (`req.body`) đều được validate bằng **Zod** qua middleware `validate` (`src/middlewares/validateMiddleware.ts`) trước khi vào controller.

- Schema khai báo theo module, ví dụ `src/modules/auth/authSchema.ts`; type DTO suy ra trực tiếp từ schema bằng `z.infer` (`RegisterDto`, `LoginDto`).
- Các rule dùng chung khai báo tại `src/utils/ruleValidate.ts` để tái sử dụng giữa các module, ví dụ:

  ```ts
  username: requiredString("Username", { min: 3, max: 50 }),
  email: emailRule,
  password: passwordRule(),
  gender: enumRule("Gender", ["male", "female", "other"]),
  phoneNumber: phoneRule(),
  ```

  - `requiredString(label, { min, max, trim })`: chuỗi bắt buộc, tự trim (mặc định), tự sinh message theo `label` (`"Username is required"`, `"Username must be at least 3 characters"`,...). `min` mặc định là 1 nên chuỗi rỗng luôn bị chặn.
  - `optionalString(label, { min, max, trim })`: như `requiredString` nhưng cho phép bỏ qua field hoặc gửi `null`.
  - `emailRule`: `requiredString("Email", { max: 255 })` rồi `.pipe(z.email(...))` — trim trước, kiểm tra định dạng sau.
  - `passwordRule({ label, min, max })`: mật khẩu không trim, mặc định `min = 6`, `max = 255`; field đăng nhập dùng `passwordRule({ min: 1 })`.
  - `phoneRule(label)`: số điện thoại VN (`0xxxxxxxxx` hoặc `+84xxxxxxxxx`).
  - `uuidRule(label)`: UUID, `label` mặc định là `Id`.
  - `enumRule(label, values)`: enum theo mảng giá trị, dùng được với TS enum qua `Object.values(UserRole)`.
  - `numberRule(label, { min, max, int })`: số; `int: true` để bắt buộc số nguyên.
  - `dateRule(label)`: ngày dạng `YYYY-MM-DD`.
- Gắn vào route, ví dụ:

  ```ts
  this.router.post("/login", validate(loginSchema), this.authController.loginUser);
  ```

- Sau khi parse hợp lệ, dữ liệu sạch được gán lại vào `req.body` (các field không khai báo trong schema bị loại bỏ).
- Lỗi validate trả về `400` theo format `CustomResponse.error`:

  ```json
  {
    "success": false,
    "message": "Validation failed",
    "errors": [{ "field": "email", "message": "Invalid email address" }]
  }
  ```

---

## 📦 Các gói chính

- **Runtime:** `express`, `cors`, `dotenv`
- **Database & ORM:** `typeorm`, `reflect-metadata`, `pg`
- **Redis:** `ioredis` (client Redis, dùng chung cho BullMQ/Valkey, Socket.io adapter,...)
- **Validation:** `zod`
- **TypeScript & Tooling:** `typescript`, `@types/node`, `@types/express`, `@types/pg`, `tsx`
