# Roomee Backend Server

Server backend được xây dựng với **Node.js**, **Express.js**, **TypeScript**, và **TypeORM** (kết nối PostgreSQL).

---

## 📁 Cấu trúc thư mục

```text
_backend/
├── src/
│   ├── config/           # Cấu hình hệ thống (nếu có)
│   ├── entities/         # Khai báo TypeORM Entities
│   │   ├── index.ts      # Export tất cả entities
│   │   └── user.ts       # Entity người dùng mẫu
│   ├── migrations/       # Các file migration do TypeORM sinh ra
│   ├── modules/          # Các module tính năng (auth, room,...)
│   │   └── auth/
│   ├── app.ts            # Cấu hình Express app, middlewares, error handler
│   ├── data-source.ts    # Khai báo DataSource chính của TypeORM
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
| `GET`       | `/api/health` | Kiểm tra tình trạng server và trạng thái kết nối PostgreSQL |

---

## 📦 Các gói chính

- **Runtime:** `express`, `cors`, `dotenv`
- **Database & ORM:** `typeorm`, `reflect-metadata`, `pg`
- **TypeScript & Tooling:** `typescript`, `@types/node`, `@types/express`, `@types/pg`, `tsx`
