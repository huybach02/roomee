import { z } from "zod";

type StringRuleOptions = {
  min?: number;
  max?: number;
  trim?: boolean;
};

type NumberRuleOptions = {
  min?: number;
  max?: number;
  int?: boolean;
};

const requiredString = (
  label: string,
  { min, max, trim = true }: StringRuleOptions = {},
): z.ZodString => {
  let schema: z.ZodString = z.string(`${label} is required`);

  if (trim) {
    schema = schema.trim();
  }

  const minLength = min ?? 1;
  schema = schema.min(
    minLength,
    minLength <= 1
      ? `${label} is required`
      : `${label} must be at least ${minLength} characters`,
  );

  if (max !== undefined) {
    schema = schema.max(max, `${label} must be at most ${max} characters`);
  }

  return schema;
};

const optionalString = (label: string, options: StringRuleOptions = {}) =>
  requiredString(label, options).nullish();

const emailRule = requiredString("Email", { max: 255 })
  .toLowerCase()
  .pipe(z.email("Invalid email address"));

const passwordRule = ({
  label = "Password",
  min = 8,
  max = 255,
}: { label?: string; min?: number; max?: number } = {}) =>
  requiredString(label, { min, max, trim: false });

const phoneRule = (label = "Phone number") =>
  requiredString(label, { max: 20 }).regex(
    /^(?:\+84|0)(?:3|5|7|8|9)\d{8}$/,
    `${label} must be a valid Vietnamese phone number`,
  );

const uuidRule = (label = "Id") =>
  requiredString(label, { max: 36 }).pipe(
    z.uuid(`${label} must be a valid UUID`),
  );

const enumRule = <const T extends readonly string[]>(
  label: string,
  values: T,
) =>
  z.enum(values, {
    error: (issue) =>
      issue.input === undefined
        ? `${label} is required`
        : `${label} is invalid`,
  });

const numberRule = (
  label: string,
  { min, max, int = false }: NumberRuleOptions = {},
): z.ZodNumber => {
  let schema: z.ZodNumber = z.number(`${label} must be a number`);

  if (int) {
    schema = schema.int(`${label} must be an integer`);
  }

  if (min !== undefined) {
    schema = schema.min(min, `${label} must be at least ${min}`);
  }

  if (max !== undefined) {
    schema = schema.max(max, `${label} must be at most ${max}`);
  }

  return schema;
};

const dateRule = (label = "Date") =>
  requiredString(label, { max: 10 }).pipe(
    z.iso.date(`${label} must be in YYYY-MM-DD format`),
  );

export const ruleValidates = {
  requiredString,
  optionalString,
  emailRule,
  passwordRule,
  phoneRule,
  uuidRule,
  enumRule,
  numberRule,
  dateRule,
};
