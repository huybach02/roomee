import { z } from "zod";

export const provinceIdParamSchema = z.object({
  provinceId: z.coerce
    .number("Province ID must be a number")
    .int("Province ID must be an integer")
    .min(1, "Province ID must be at least 1"),
});

export type ProvinceIdParam = z.infer<typeof provinceIdParamSchema>;

export const syncMutationSchema = z.object({
  id: z.string().min(1, "Mutation ID cannot be empty"),
  module: z.string().min(1, "Module name cannot be empty"),
  action: z.enum(["create", "update", "delete"]),
  entityId: z.string().min(1, "Entity ID cannot be empty"),
  data: z.record(z.string(), z.any()).optional().nullable(),
});

export const syncItemSchema = z.object({
  id: z.string().min(1, "ID cannot be empty"),
  updatedAt: z.string().optional().nullable(),
});

export const syncRequestSchema = z.object({
  mutations: z.array(syncMutationSchema).optional().default([]),
  entities: z.record(z.string(), z.array(syncItemSchema)),
});

export type SyncMutationDto = z.infer<typeof syncMutationSchema>;
export type SyncItemDto = z.infer<typeof syncItemSchema>;
export type SyncRequestDto = z.infer<typeof syncRequestSchema>;

export interface SyncModuleResult {
  needUpdate: any[];
  needDelete: string[];
}

export interface SyncResponseData {
  appliedMutationIds: string[];
  entities: Record<string, SyncModuleResult>;
}

