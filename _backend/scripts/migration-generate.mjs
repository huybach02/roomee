import { spawn } from "node:child_process";

// Lấy tên migration từ tham số dòng lệnh, mặc định là "AutoMigration" nếu không truyền
const inputName = process.argv[2] || "AutoMigration";
const targetPath = inputName.startsWith("src/migrations")
  ? inputName
  : `src/migrations/${inputName}`;

const args = [
  "./node_modules/tsx/dist/cli.mjs",
  "./node_modules/typeorm/cli.js",
  "migration:generate",
  "-d",
  "src/config/data-source.ts",
  targetPath,
];

const child = spawn(process.execPath, args, {
  stdio: "inherit",
});

child.on("exit", (code) => {
  process.exit(code ?? 0);
});
