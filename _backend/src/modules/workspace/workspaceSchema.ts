import { z } from "zod";
import { WorkspaceType } from "../../utils/constanst.js";
import { ruleValidates } from "../../utils/ruleValidate.js";
import { baseQuerySchema } from "../../utils/queryHelper.js";

export const workspaceParamSchema = z.object({
  id: ruleValidates.uuidRule(),
});

export type WorkspaceParam = z.infer<typeof workspaceParamSchema>;

/**
 * Các trường nghiệp vụ dùng chung cho tạo mới và cập nhật.
 * Không đặt default tại đây để `updateWorkspaceSchema.partial()` không tự sinh
 * giá trị mặc định khi client chỉ gửi một phần dữ liệu (ví dụ chỉ đổi status).
 */
const workspaceCoreSchema = z.object({
  name: ruleValidates.requiredString({ max: 255 }),
  type: z.nativeEnum(WorkspaceType),
  area: ruleValidates.positiveNumber(),
  provinceId: ruleValidates.idRule(),
  wardId: ruleValidates.idRule(),
  address: ruleValidates.requiredString({ max: 255 }),
  description: ruleValidates.optionalString(),
  contactName: ruleValidates.requiredString({ max: 100 }),
  contactPhone: ruleValidates.phoneRule(),
  contactZalo: ruleValidates.phoneRule().nullish(),
});

/**
 * Schema validate body khi tạo mới Workspace
 */
export const createWorkspaceSchema = workspaceCoreSchema.extend({
  id: ruleValidates.uuidRule().optional(),
  numberOfRooms: ruleValidates.nonNegativeNumber({ int: true }).default(0),
  status: ruleValidates.statusRule(),
});

export type CreateWorkspaceDto = z.infer<typeof createWorkspaceSchema>;

/**
 * Schema validate body khi cập nhật Workspace.
 * Không cho phép đổi `id`; bỏ default của `status` để tránh reset trạng thái.
 */
export const updateWorkspaceSchema = workspaceCoreSchema.partial().extend({
  numberOfRooms: ruleValidates.nonNegativeNumber({ int: true }).optional(),
  status: ruleValidates.statusRule().removeDefault().optional(),
});

export type UpdateWorkspaceDto = z.infer<typeof updateWorkspaceSchema>;

/**
 * Schema validate query params khi lấy danh sách Workspace
 * Kế thừa các field cố định (page, limit, search, sortBy, sortOrder, all) từ baseQuerySchema
 */
export const workspaceQuerySchema = baseQuerySchema.extend({
  type: z.nativeEnum(WorkspaceType).optional(),
  status: z.coerce.number().int().min(0).max(1).optional(),
  provinceId: z.coerce.number().int().optional(),
  wardId: z.coerce.number().int().optional(),
  areaMin: z.coerce.number().min(0).optional(),
  areaMax: z.coerce.number().min(0).optional(),
});

export type WorkspaceQueryDto = z.infer<typeof workspaceQuerySchema>;
