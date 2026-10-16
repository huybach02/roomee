# Roomee Backend Server

Server backend được xây dựng với **Node.js**, **Express.js**, và **TypeScript**.

---

## 📁 Cấu trúc thư mục

```text
_backend/
├── src/
│   ├── routes/
│   │   └── index.ts      # Khai báo các API routes
│   ├── app.ts            # Cấu hình Express app, middlewares, error handler
│   └── index.ts          # Entry point khởi chạy HTTP server
├── dist/                 # Mã JavaScript sau khi biên dịch (tsc)
├── .env                  # Biến môi trường cục bộ (PORT, NODE_ENV,...)
├── .env.example          # Mẫu file cấu hình môi trường
├── .gitignore            # Bỏ qua node_modules, dist, .env,...
├── tsconfig.json         # Cấu hình TypeScript compiler
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
Mặc định server chạy tại cổng `5000`.

### 3. Các lệnh chạy server

- **Chế độ phát triển (tự động reload khi sửa file `.ts` bằng `tsx watch`):**
  ```bash
  npm run dev
  ```

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

| Phương thức | Đường dẫn | Mô tả |
|-------------|-----------|-------|
| `GET` | `/` | Thông tin cơ bản server |
| `GET` | `/api` | Root endpoint của API |
| `GET` | `/api/health` | Kiểm tra tình trạng server (Health check) |

---

## 📦 Các gói chính
- **Runtime:** `express`, `cors`, `dotenv`
- **TypeScript:** `typescript`, `@types/node`, `@types/express`, `@types/cors`, `tsx`
