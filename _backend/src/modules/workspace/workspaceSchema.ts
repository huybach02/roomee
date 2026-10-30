import { z } from "zod";
import { WorkspaceType } from "../../utils/constanst.js";
import { ruleValidates } from "../../utils/ruleValidate.js";
import { baseQuerySchema } from "../../utils/queryHelper.js";

export const workspaceParamSchema = z.object({
  id: ruleValidates.uuidRule(),
});

export type WorkspaceParam = z.infer<typeof workspaceParamSchema>;

/**
 * Schema validate body khi tạo mới Workspace
 */
export const createWorkspaceSchema = z.object({
  name: ruleValidates.requiredString({ max: 255 }),
  type: z.nativeEnum(WorkspaceType),
  area: ruleValidates.positiveNumber(),
  numberOfRooms: ruleValidates.nonNegativeNumber({ int: true }).default(0),
  provinceId: ruleValidates.idRule(),
  wardId: ruleValidates.idRule(),
  address: ruleValidates.requiredString({ max: 255 }),
  description: ruleValidates.optionalString(),
  contactName: ruleValidates.requiredString({ max: 100 }),
  contactPhone: ruleValidates.phoneRule(),
  contactZalo: ruleValidates.phoneRule().nullish(),
  status: ruleValidates.statusRule(),
});

export type CreateWorkspaceDto = z.infer<typeof createWorkspaceSchema>;

/**
 * Schema validate body khi cập nhật Workspace
 */
export const updateWorkspaceSchema = createWorkspaceSchema.partial();

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
  sortByScale: z.string().trim().optional(),
  sortOrderScale: z.enum(["asc", "desc", "ASC", "DESC"]).optional(),
});

export type WorkspaceQueryDto = z.infer<typeof workspaceQuerySchema>;
