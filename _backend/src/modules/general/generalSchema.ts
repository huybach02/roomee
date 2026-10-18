import { z } from "zod";

export const provinceIdParamSchema = z.object({
  provinceId: z.coerce
    .number("Province ID must be a number")
    .int("Province ID must be an integer")
    .min(1, "Province ID must be at least 1"),
});

export type ProvinceIdParam = z.infer<typeof provinceIdParamSchema>;
