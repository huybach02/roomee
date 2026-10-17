import { z } from "zod";
import { ruleValidates } from "../../utils/ruleValidate.js";

export const registerSchema = z.object({
  username: ruleValidates.requiredString("Username", { min: 3, max: 50 }),
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule(),
});

export const loginSchema = z.object({
  email: ruleValidates.emailRule,
  password: ruleValidates.passwordRule({ min: 1 }),
});

export type RegisterDto = z.infer<typeof registerSchema>;
export type LoginDto = z.infer<typeof loginSchema>;
