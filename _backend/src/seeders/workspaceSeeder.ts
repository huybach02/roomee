import { DataSource } from "typeorm";
import { Workspace } from "../entities/workspace.js";
import { User } from "../entities/user.js";
import { Ward } from "../entities/ward.js";
import { WorkspaceType } from "../utils/constanst.js";
import type { ISeeder } from "./index.js";

export class WorkspaceSeeder implements ISeeder {
  public readonly name = "WorkspaceSeeder";

  public async run(dataSource: DataSource): Promise<void> {
    const workspaceRepository = dataSource.getRepository(Workspace);
    const userRepository = dataSource.getRepository(User);
    const wardRepository = dataSource.getRepository(Ward);

    // 1. Tìm user chủ trọ huybach2002ct@gmail.com
    const targetEmail = "huybach2002ct@gmail.com";
    const landlord = await userRepository.findOneBy({ email: targetEmail });

    if (!landlord) {
      console.error(
        `[WorkspaceSeeder] ❌ Không tìm thấy user với email: ${targetEmail}. Vui lòng chạy UserSeeder trước!`,
      );
      return;
    }

    console.log(
      `[WorkspaceSeeder] 🗑️ Bắt đầu dọn dẹp các record workspace hiện có...`,
    );
    // Xóa toàn bộ workspaces hiện có
    await workspaceRepository
      .createQueryBuilder()
      .delete()
      .from(Workspace)
      .execute();
    console.log(`[WorkspaceSeeder] ✅ Đã xóa sạch các workspace cũ.`);

    // 2. Lấy danh sách phường/xã kèm tỉnh/thành
    const sampleWards = await wardRepository
      .createQueryBuilder("ward")
      .innerJoinAndSelect("ward.province", "province")
      .take(40)
      .getMany();

    if (sampleWards.length === 0) {
      console.error(
        `[WorkspaceSeeder] ❌ Không tìm thấy dữ liệu Tỉnh/Phường. Vui lòng chạy DataUnitsSeeder trước!`,
      );
      return;
    }

    console.log(
      `[WorkspaceSeeder] 🏢 Đang khởi tạo 30 khu trọ mẫu cho "${landlord.fullName}" (${landlord.email})...`,
    );

    const workspaceTemplates = [
      {
        name: "Nhà trọ Minh Khai Green",
        type: WorkspaceType.RENTED_ROOM,
        area: 120.0,
        numberOfRooms: 12,
        address: "Số 45 Ngõ 191 Minh Khai",
        desc: "Phòng trọ khép kín có gác xép, giờ giấc tự do, camera 24/7.",
        status: 1,
      },
      {
        name: "Chung cư mini Cầu Giấy Skyline",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 250.5,
        numberOfRooms: 20,
        address: "Số 12 Ngách 34/2 Cầu Giấy",
        desc: "Căn hộ dịch vụ full đồ: điều hòa, nóng lạnh, máy giặt riêng, thang máy.",
        status: 1,
      },
      {
        name: "Ký túc xá Bách Khoa Hub",
        type: WorkspaceType.DORMITORY,
        area: 180.0,
        numberOfRooms: 32,
        address: "Tòa A3 Ngõ 84 Tạ Quang Bửu",
        desc: "Ký túc xá cao cấp sleepbox riêng tư cho sinh viên Bách Khoa - Xây Dựng.",
        status: 1,
      },
      {
        name: "Nhà trọ Mỹ Đình Sunshine",
        type: WorkspaceType.RENTED_ROOM,
        area: 160.0,
        numberOfRooms: 16,
        address: "Số 88 Đình Thôn, Nam Từ Liêm",
        desc: "Khu trọ yên tĩnh, sạch sẽ, an ninh tốt, gần bến xe Mỹ Đình.",
        status: 1,
      },
      {
        name: "Tòa nhà Roomee Landmark Tây Hồ",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 420.0,
        numberOfRooms: 28,
        address: "Số 68 Đường Lạc Long Quân",
        desc: "View Hồ Tây thoáng mát, full nội thất cao cấp, có hầm để xe rộng rãi.",
        status: 1,
      },
      {
        name: "Sleepbox Thanh Xuân Central",
        type: WorkspaceType.DORMITORY,
        area: 95.0,
        numberOfRooms: 24,
        address: "Số 102 Nguyễn Trãi, Thanh Xuân",
        desc: "Hộp ngủ thông minh đầy đủ tiện nghi, gần ga tàu điện Cát Linh.",
        status: 1,
      },
      {
        name: "Nhà trọ Hoàng Mai Eco House",
        type: WorkspaceType.RENTED_ROOM,
        area: 140.0,
        numberOfRooms: 14,
        address: "Số 23 Ngõ 553 Giải Phóng",
        desc: "Phòng trọ giá sinh viên, điện nước giá dân, bảo vệ trực đêm.",
        status: 0, // Tạm dừng hoạt động
      },
      {
        name: "Căn hộ dịch vụ Ba Đình Prime",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 310.0,
        numberOfRooms: 18,
        address: "Số 15 Đội Cấn, Ba Đình",
        desc: "Dành cho chuyên gia và người đi làm, dọn phòng tuần 2 lần.",
        status: 1,
      },
      {
        name: "Dormitory Đống Đa Campus",
        type: WorkspaceType.DORMITORY,
        area: 150.0,
        numberOfRooms: 36,
        address: "Số 79 Chùa Bộc, Đống Đa",
        desc: "Ký túc xá tiện nghi gần Đại học Ngân Hàng, Học viện Ngoại Giao.",
        status: 1,
      },
      {
        name: "Nhà trọ Hai Bà Trưng Garden",
        type: WorkspaceType.RENTED_ROOM,
        area: 110.0,
        numberOfRooms: 10,
        address: "Số 56 Lò Đúc, Hai Bà Trưng",
        desc: "Nhà trọ có sân phơi chung rộng, ban công thoáng gió.",
        status: 1,
      },
      {
        name: "Chung cư mini Hà Đông Riverside",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 280.0,
        numberOfRooms: 22,
        address: "KĐT Mỗ Lao, Hà Đông",
        desc: "Căn hộ 1 ngủ 1 khách hiện đại, khóa vân tay từng phòng.",
        status: 1,
      },
      {
        name: "Nhà trọ Hoàn Kiếm Old Town",
        type: WorkspaceType.RENTED_ROOM,
        area: 85.0,
        numberOfRooms: 8,
        address: "Số 22 Phố Hàng Buồm",
        desc: "Vị trí trung tâm phố cổ thuận tiện đi lại, phòng khép kín.",
        status: 0, // Tạm dừng
      },
      {
        name: "Sleepbox Cầu Giấy Station",
        type: WorkspaceType.DORMITORY,
        area: 130.0,
        numberOfRooms: 40,
        address: "Số 165 Cầu Giấy",
        desc: "Hộp ngủ hiện đại cách ĐH Quốc Gia 300m, điều hòa trung tâm 24/24.",
        status: 1,
      },
      {
        name: "Nhà trọ Long Biên Green Life",
        type: WorkspaceType.RENTED_ROOM,
        area: 190.0,
        numberOfRooms: 15,
        address: "Số 38 Ngõ 135 Nguyễn Văn Cừ",
        desc: "Không gian sống xanh mát, không chung chủ, có bếp nấu ăn riêng.",
        status: 1,
      },
      {
        name: "Căn hộ dịch vụ Nam Từ Liêm",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 350.0,
        numberOfRooms: 25,
        address: "Số 5 Lê Đức Thọ, Mỹ Đình 2",
        desc: "Gần sân vận động Mỹ Đình, đường lớn ô tô vào tận cửa.",
        status: 1,
      },
      {
        name: "Nhà trọ Bắc Từ Liêm Smart",
        type: WorkspaceType.RENTED_ROOM,
        area: 175.0,
        numberOfRooms: 18,
        address: "Số 40 Nhổn, Tây Tựu",
        desc: "Khu trọ sinh viên gần ĐH Công Nghiệp, wifi tốc độ cao miễn phí.",
        status: 1,
      },
      {
        name: "Tòa nhà mini Thanh Trì Star",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 220.0,
        numberOfRooms: 16,
        address: "Số 12 Tựu Liệt, Tam Hiệp",
        desc: "Căn hộ mini ban công riêng, hệ thống PCCC đạt chuẩn nghiệm thu.",
        status: 1,
      },
      {
        name: "Ký túc xá Xã Đàn Cozy Box",
        type: WorkspaceType.DORMITORY,
        area: 115.0,
        numberOfRooms: 26,
        address: "Số 205 Xã Đàn, Đống Đa",
        desc: "Phòng ký túc xá nam nữ riêng biệt, trang bị tủ đồ cá nhân an toàn.",
        status: 1,
      },
      {
        name: "Nhà trọ Gia Lâm VinCity View",
        type: WorkspaceType.RENTED_ROOM,
        area: 210.0,
        numberOfRooms: 20,
        address: "Khu Đô Thị Đặng Xá, Gia Lâm",
        desc: "Nhà trọ mới xây 100%, gạch men cao cấp, thiết bị vệ sinh Inax.",
        status: 0, // Tạm dừng
      },
      {
        name: "Chung cư mini Hoàng Mai Lakeview",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 390.0,
        numberOfRooms: 30,
        address: "Bán Đảo Linh Đàm, Hoàng Mai",
        desc: "Căn hộ view hồ Linh Đàm thoáng mát, đầy đủ tiện ích xung quanh.",
        status: 1,
      },
      {
        name: "Sleepbox Trung Hòa Nhân Chính",
        type: WorkspaceType.DORMITORY,
        area: 140.0,
        numberOfRooms: 35,
        address: "Số 58 Hoàng Đạo Thúy",
        desc: "Ký túc xá chuẩn Hàn Quốc, khu sinh hoạt chung có lò vi sóng, tủ lạnh.",
        status: 1,
      },
      {
        name: "Nhà trọ Kim Mã Golden",
        type: WorkspaceType.RENTED_ROOM,
        area: 130.0,
        numberOfRooms: 12,
        address: "Số 89 Ngõ 290 Kim Mã",
        desc: "Khu vực an ninh tốt gần đại sứ quán, cổng khóa thẻ từ bảo mật.",
        status: 1,
      },
      {
        name: "Căn hộ mini Thụy Khuê Sun Home",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 270.0,
        numberOfRooms: 19,
        address: "Số 122 Thụy Khuê, Tây Hồ",
        desc: "Cách Hồ Tây 50m, có sân thượng BBQ ngắm cảnh cực đẹp.",
        status: 1,
      },
      {
        name: "Nhà trọ Láng Hạ Peace",
        type: WorkspaceType.RENTED_ROOM,
        area: 105.0,
        numberOfRooms: 11,
        address: "Số 31 Ngõ 105 Láng Hạ",
        desc: "Phòng trọ yên tĩnh cho dân văn phòng, không tụ tập ồn ào.",
        status: 1,
      },
      {
        name: "Dormitory Cầu Giấy Student Box",
        type: WorkspaceType.DORMITORY,
        area: 125.0,
        numberOfRooms: 30,
        address: "Số 92 Trần Thái Tông",
        desc: "Phòng ngủ capsule tiện nghi, tủ khóa vân tay, phòng tắm nóng lạnh.",
        status: 0, // Tạm dừng
      },
      {
        name: "Chung cư mini Hà Đông Park View",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 320.0,
        numberOfRooms: 24,
        address: "Khu Căn Hộ Văn Phú, Hà Đông",
        desc: "Căn hộ khép kín full đồ cao cấp, cạnh công viên cây xanh thoáng đãng.",
        status: 1,
      },
      {
        name: "Nhà trọ Định Công Center",
        type: WorkspaceType.RENTED_ROOM,
        area: 155.0,
        numberOfRooms: 15,
        address: "Số 74 Ngõ 99 Định Công",
        desc: "Gần trường ĐH Y Hà Nội và Kinh Tế Quốc Dân, chợ họp ngay đầu ngõ.",
        status: 1,
      },
      {
        name: "Căn hộ dịch vụ Tây Hồ Westlake Luxury",
        type: WorkspaceType.APARTMENT_MINI_HOUSE,
        area: 480.0,
        numberOfRooms: 35,
        address: "Số 18 Quảng An, Tây Hồ",
        desc: "Tòa căn hộ dịch vụ cao cấp chuẩn khách sạn 4 sao, hồ bơi trên mái.",
        status: 1,
      },
      {
        name: "Sleepbox Bách Khoa GenZ",
        type: WorkspaceType.DORMITORY,
        area: 110.0,
        numberOfRooms: 28,
        address: "Số 15 Lê Thanh Nghị, Hai Bà Trưng",
        desc: "Không gian ngủ nghỉ riêng tư phong cách trẻ trung năng động.",
        status: 1,
      },
      {
        name: "Nhà trọ Xuân Thủy Campus",
        type: WorkspaceType.RENTED_ROOM,
        area: 145.0,
        numberOfRooms: 14,
        address: "Số 130 Xuân Thủy, Cầu Giấy",
        desc: "Đối diện ĐH Sư Phạm Hà Nội, tiện xe buýt, phòng khép kín sạch sẽ.",
        status: 1,
      },
    ];

    const workspacesToSave = workspaceTemplates.map((template, idx) => {
      const ward = sampleWards[idx % sampleWards.length];
      const ws = new Workspace();
      ws.userId = landlord.id;
      ws.name = template.name;
      ws.type = template.type;
      ws.area = template.area;
      ws.numberOfRooms = template.numberOfRooms;
      ws.provinceId = ward.provinceId;
      ws.wardId = ward.id;
      ws.address = template.address;
      ws.description = template.desc;
      ws.contactName = landlord.fullName || "Huy Bách";
      ws.contactPhone = landlord.phoneNumber || "0903333333";
      ws.contactZalo = landlord.phoneNumber || "0903333333";
      ws.status = template.status;
      return ws;
    });

    await workspaceRepository.save(workspacesToSave);

    console.log(
      `[WorkspaceSeeder] 🎉 Đã khởi tạo thành công ${workspacesToSave.length} workspace cho user "${landlord.fullName}"!`,
    );
  }
}
