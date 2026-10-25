import { z } from "zod";
import { WorkspaceType } from "../../utils/constanst.js";
import { ruleValidates } from "../../utils/ruleValidate.js";

export const workspaceParamSchema = z.object({
  id: z.coerce
    .number("Workspace ID must be a number")
    .int("Workspace ID must be an integer")
    .min(1, "Workspace ID must be at least 1"),
});

export type WorkspaceParam = z.infer<typeof workspaceParamSchema>;

/**
 * Schema validate body khi tạo mới Workspace
 */
export const createWorkspaceSchema = z.object({
  name: ruleValidates.requiredString("Tên nhà trọ / khu trọ", { max: 255 }),
  type: z.nativeEnum(WorkspaceType, {
    message: "Loại hình bất động sản không hợp lệ",
  }),
  area: z.coerce
    .number("Diện tích phải là số")
    .positive("Diện tích phải lớn hơn 0"),
  numberOfRooms: z.coerce
    .number("Số phòng phải là số")
    .int("Số phòng phải là số nguyên")
    .min(0, "Số phòng không được nhỏ hơn 0")
    .default(0),
  provinceId: z.coerce
    .number("Tỉnh/Thành phố là bắt buộc")
    .int()
    .min(1, "Tỉnh/Thành phố không hợp lệ"),
  wardId: z.coerce
    .number("Phường/Xã là bắt buộc")
    .int()
    .min(1, "Phường/Xã không hợp lệ"),
  address: ruleValidates.requiredString("Địa chỉ chi tiết", { max: 255 }),
  description: ruleValidates.optionalString("Mô tả"),
  contactName: ruleValidates.requiredString("Tên người liên hệ", { max: 100 }),
  contactPhone: ruleValidates.phoneRule("Số điện thoại liên hệ"),
  contactZalo: ruleValidates.phoneRule("Số Zalo liên hệ").nullish(),
  status: z
    .preprocess((val) => {
      if (typeof val === "boolean") return val ? 1 : 0;
      if (val === "true") return 1;
      if (val === "false") return 0;
      return val;
    }, z.coerce.number().int().min(0).max(1))
    .default(1),
});

export type CreateWorkspaceDto = z.infer<typeof createWorkspaceSchema>;

/**
 * Schema validate body khi cập nhật Workspace
 */
export const updateWorkspaceSchema = createWorkspaceSchema.partial();

export type UpdateWorkspaceDto = z.infer<typeof updateWorkspaceSchema>;

/**
 * Schema validate query params khi lấy danh sách Workspace
 */
export const workspaceQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().optional(),
  type: z.nativeEnum(WorkspaceType).optional(),
  provinceId: z.coerce.number().int().optional(),
  wardId: z.coerce.number().int().optional(),
  all: z
    .preprocess(
      (val) => val === "true" || val === true || val === "1" || val === 1,
      z.boolean(),
    )
    .optional(),
});

export type WorkspaceQueryDto = z.infer<typeof workspaceQuerySchema>;
