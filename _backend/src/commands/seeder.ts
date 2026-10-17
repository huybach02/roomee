import "reflect-metadata";
import { AppDataSource } from "../config/data-source.js";
import { seeders, type ISeeder } from "../seeders/index.js";

function parseArgs(): { targetName?: string; showHelp: boolean } {
  const rawArgs = process.argv.slice(2);
  let targetName: string | undefined;
  let showHelp = false;

  for (let i = 0; i < rawArgs.length; i++) {
    const arg = rawArgs[i];

    if (arg === "--help" || arg === "-h") {
      showHelp = true;
    } else if (arg.startsWith("--name=")) {
      targetName = arg.split("=")[1];
    } else if (arg.startsWith("-n=")) {
      targetName = arg.split("=")[1];
    } else if (arg === "--name" || arg === "-n") {
      targetName = rawArgs[++i];
    } else if (!arg.startsWith("-") && !targetName) {
      targetName = arg;
    }
  }

  return { targetName, showHelp };
}

function printHelp(): void {
  console.log(`
🌱 Roomee Database Seeder CLI

Cách dùng:
  npm run seed                     # Chạy TẤT CẢ các seeders
  npm run seed <SeederName>        # Chạy 1 seeder chỉ định
  npm run seed -- --name=<Name>    # Chạy 1 seeder chỉ định theo cờ --name

Danh sách các seeders có sẵn:
${seeders.map((s) => `  - ${s.name}`).join("\n")}
`);
}

async function runSingleSeeder(seeder: ISeeder): Promise<void> {
  const startTime = Date.now();
  console.log(`\n------------------------------------------------------------`);
  console.log(`🚀 [Bắt đầu] Seeder: ${seeder.name}`);
  console.log(`------------------------------------------------------------`);

  await seeder.run(AppDataSource);

  const duration = ((Date.now() - startTime) / 1000).toFixed(2);
  console.log(`✨ [Hoàn thành] Seeder: ${seeder.name} (${duration}s)`);
}

async function main(): Promise<void> {
  const { targetName, showHelp } = parseArgs();

  if (showHelp) {
    printHelp();
    return;
  }

  let selectedSeeders: ISeeder[] = [];

  if (targetName) {
    const normalizedTarget = targetName.toLowerCase();
    const matched = seeders.filter(
      (s) =>
        s.name.toLowerCase() === normalizedTarget ||
        s.name.toLowerCase().replace(/seeder$/, "") === normalizedTarget
    );

    if (matched.length === 0) {
      console.error(`\n❌ Không tìm thấy seeder nào có tên: "${targetName}"`);
      console.log(`\nDanh sách seeders có sẵn:`);
      seeders.forEach((s) => console.log(`  - ${s.name}`));
      process.exit(1);
    }

    selectedSeeders = matched;
  } else {
    selectedSeeders = seeders;
  }

  console.log(`\n🌱 [Roomee Seeder] Đang kết nối database...`);
  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }
  console.log(`✅ Kết nối database thành công!`);
  console.log(`📋 Số lượng seeder sẽ thực thi: ${selectedSeeders.length}`);

  const totalStartTime = Date.now();

  try {
    for (const seeder of selectedSeeders) {
      await runSingleSeeder(seeder);
    }

    const totalDuration = ((Date.now() - totalStartTime) / 1000).toFixed(2);
    console.log(`\n🎉 Toàn bộ seeder đã thực thi thành công trong ${totalDuration}s!\n`);
  } catch (error) {
    console.error(`\n❌ Có lỗi xảy ra trong quá trình seed dữ liệu:`, error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

main().catch((err) => {
  console.error("Unhandled error:", err);
  process.exit(1);
});
