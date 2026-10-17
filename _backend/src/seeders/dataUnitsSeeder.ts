import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DataSource } from "typeorm";
import { Province } from "../entities/province.js";
import { Ward } from "../entities/ward.js";
import type { ISeeder } from "./index.js";

interface RawWard {
  Code: string;
  Name: string;
  NameEn: string;
  FullName: string;
  FullNameEn: string;
  CodeName: string;
  ProvinceCode: string;
}

interface RawProvince {
  Code: string;
  Name: string;
  NameEn: string;
  FullName: string;
  FullNameEn: string;
  CodeName: string;
  Wards?: RawWard[];
}

export class DataUnitsSeeder implements ISeeder {
  public readonly name = "DataUnitsSeeder";

  public async run(dataSource: DataSource): Promise<void> {
    const filePath = this.getDataUnitsPath();
    console.log(`[DataUnitsSeeder] 📖 Đang đọc dữ liệu từ: ${filePath}...`);
    const rawContent = await fs.readFile(filePath, "utf-8");
    const data: RawProvince[] = JSON.parse(rawContent);

    console.log(`[DataUnitsSeeder] 📍 Tìm thấy ${data.length} tỉnh/thành phố...`);

    const provinceRepo = dataSource.getRepository(Province);
    const wardRepo = dataSource.getRepository(Ward);

    // 1. Chuẩn bị dữ liệu provinces
    const provincesToUpsert = data.map((p) => ({
      code: parseInt(p.Code, 10),
      fullName: p.FullName,
      fullNameEn: p.FullNameEn || null,
      codeName: p.CodeName,
    }));

    // 2. Upsert provinces theo code
    console.log(`[DataUnitsSeeder] ⏳ Đang lưu ${provincesToUpsert.length} tỉnh/thành phố...`);
    await provinceRepo.upsert(provincesToUpsert, ["code"]);

    // Lấy mapping code -> id của province
    const savedProvinces = await provinceRepo.find({
      select: { id: true, code: true },
    });
    const provinceIdMap = new Map<number, number>();
    for (const sp of savedProvinces) {
      provinceIdMap.set(sp.code, sp.id);
    }

    // 3. Chuẩn bị dữ liệu wards
    const wardsToUpsert: Array<{
      code: number;
      provinceId: number;
      fullName: string;
      fullNameEn: string | null;
      codeName: string;
    }> = [];

    for (const p of data) {
      const pCode = parseInt(p.Code, 10);
      const provinceId = provinceIdMap.get(pCode);
      if (!provinceId) {
        throw new Error(`[DataUnitsSeeder] Không tìm thấy provinceId cho province code: ${pCode}`);
      }

      for (const w of p.Wards || []) {
        wardsToUpsert.push({
          code: parseInt(w.Code, 10),
          provinceId,
          fullName: w.FullName,
          fullNameEn: w.FullNameEn || null,
          codeName: w.CodeName,
        });
      }
    }

    console.log(`[DataUnitsSeeder] 🏘️ Tìm thấy ${wardsToUpsert.length} phường/xã. Đang lưu theo từng đợt...`);

    // 4. Upsert wards theo batch (500 records / batch)
    const chunkSize = 500;
    for (let i = 0; i < wardsToUpsert.length; i += chunkSize) {
      const chunk = wardsToUpsert.slice(i, i + chunkSize);
      await wardRepo.upsert(chunk, ["code"]);
      process.stdout.write(
        `[DataUnitsSeeder] Đã lưu ${Math.min(i + chunkSize, wardsToUpsert.length)}/${wardsToUpsert.length} phường/xã...\r`
      );
    }
    console.log("");
    console.log(`[DataUnitsSeeder] ✅ Hoàn tất seed ${provincesToUpsert.length} tỉnh/thành và ${wardsToUpsert.length} phường/xã!`);
  }

  private getDataUnitsPath(): string {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    const candidatePaths = [
      path.resolve(__dirname, "../utils/data_units.json"),
      path.resolve(__dirname, "../../src/utils/data_units.json"),
      path.resolve(process.cwd(), "src/utils/data_units.json"),
      path.resolve(process.cwd(), "_backend/src/utils/data_units.json"),
    ];

    for (const p of candidatePaths) {
      if (fsSync.existsSync(p)) {
        return p;
      }
    }
    return candidatePaths[0];
  }
}
