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

/**
 * Rule kiểm tra chuỗi bắt buộc
 * Hỗ trợ: requiredString(), requiredString({ max: 255 }), requiredString("Tên", { max: 255 })
 */
const requiredString = (
  labelOrOptions?: string | StringRuleOptions,
  options?: StringRuleOptions,
): z.ZodString => {
  let label = "Field";
  let opts: StringRuleOptions = {};

  if (typeof labelOrOptions === "string") {
    label = labelOrOptions;
    opts = options ?? {};
  } else if (labelOrOptions && typeof labelOrOptions === "object") {
    opts = labelOrOptions;
  }

  const { min, max, trim = true } = opts;
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

/**
 * Rule kiểm tra chuỗi tùy chọn (nullable / undefined)
 * Hỗ trợ: optionalString(), optionalString({ max: 500 }), optionalString("Mô tả")
 */
const optionalString = (
  labelOrOptions?: string | StringRuleOptions,
  options?: StringRuleOptions,
) => requiredString(labelOrOptions, options).nullish();

/**
 * Rule kiểm tra Email
 */
const emailRule = (label = "Email") =>
  requiredString(label, { max: 255 })
    .toLowerCase()
    .pipe(z.email("Invalid email address"));

/**
 * Rule kiểm tra Mật khẩu
 */
const passwordRule = ({
  label = "Password",
  min = 8,
  max = 255,
}: { label?: string; min?: number; max?: number } = {}) =>
  requiredString(label, { min, max, trim: false });

/**
 * Rule kiểm tra số điện thoại Việt Nam
 */
const phoneRule = (label = "Phone number") =>
  requiredString(label, { max: 20 }).regex(
    /^(?:\+84|0)(?:3|5|7|8|9)\d{8}$/,
    `${label} must be a valid Vietnamese phone number`,
  );

/**
 * Rule kiểm tra UUID v4
 */
const uuidRule = (label = "ID") =>
  requiredString(label, { max: 36 }).pipe(
    z.uuid(`${label} must be a valid UUID`),
  );

/**
 * Rule kiểm tra Enum
 * Hỗ trợ: enumRule(values), enumRule("Role", values)
 */
function enumRule<const T extends readonly string[]>(
  valuesOrLabel: T | string,
  valuesOrOptions?: T,
) {
  let label = "Value";
  let values: T;

  if (typeof valuesOrLabel === "string") {
    label = valuesOrLabel;
    values = valuesOrOptions!;
  } else {
    values = valuesOrLabel;
  }

  return z.enum(values, {
    error: (issue) =>
      issue.input === undefined
        ? `${label} is required`
        : `${label} is invalid`,
  });
}

/**
 * Rule kiểm tra số tổng quát
 * Hỗ trợ: numberRule(), numberRule({ int: true, min: 1 }), numberRule("Age", { min: 18 })
 */
const numberRule = (
  labelOrOptions?: string | NumberRuleOptions,
  options?: NumberRuleOptions,
): z.ZodNumber => {
  let label = "Value";
  let opts: NumberRuleOptions = {};

  if (typeof labelOrOptions === "string") {
    label = labelOrOptions;
    opts = options ?? {};
  } else if (labelOrOptions && typeof labelOrOptions === "object") {
    opts = labelOrOptions;
  }

  const { min, max, int = false } = opts;
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

/**
 * Rule kiểm tra ngày tháng chuẩn YYYY-MM-DD
 */
const dateRule = (label = "Date") =>
  requiredString(label, { max: 10 }).pipe(
    z.iso.date(`${label} must be in YYYY-MM-DD format`),
  );

/**
 * Rule kiểm tra ID hoặc Khóa ngoại (Foreign Key) >= 1
 * Tự động coerce kiểu số (từ query param hoặc JSON body)
 * Hỗ trợ: idRule(), idRule("Province ID")
 */
const idRule = (label = "ID") =>
  z.coerce
    .number(`${label} must be a number`)
    .int(`${label} must be an integer`)
    .min(1, `${label} must be at least 1`);

/**
 * Rule kiểm tra số dương (> 0) cho diện tích, tiền tệ, cọc phòng
 * Tự động coerce kiểu số
 * Hỗ trợ: positiveNumber(), positiveNumber({ max: 1000 }), positiveNumber("Diện tích")
 */
const positiveNumber = (
  labelOrOptions?: string | { max?: number },
  options?: { max?: number },
) => {
  let label = "Value";
  let max = options?.max;

  if (typeof labelOrOptions === "string") {
    label = labelOrOptions;
  } else if (labelOrOptions && typeof labelOrOptions === "object") {
    max = labelOrOptions.max;
  }

  let schema = z.coerce
    .number(`${label} must be a number`)
    .positive(`${label} must be greater than 0`);

  if (max !== undefined) {
    schema = schema.max(max, `${label} must be at most ${max}`);
  }

  return schema;
};

/**
 * Rule kiểm tra số không âm (>= 0) cho số phòng, số người, phụ phí
 * Tự động coerce kiểu số, hỗ trợ ép kiểu số nguyên
 * Hỗ trợ: nonNegativeNumber(), nonNegativeNumber({ int: true })
 */
const nonNegativeNumber = (
  labelOrOptions?: string | { max?: number; int?: boolean },
  options?: { max?: number; int?: boolean },
) => {
  let label = "Value";
  let opts: { max?: number; int?: boolean } = {};

  if (typeof labelOrOptions === "string") {
    label = labelOrOptions;
    opts = options ?? {};
  } else if (labelOrOptions && typeof labelOrOptions === "object") {
    opts = labelOrOptions;
  }

  const { max, int = false } = opts;
  let schema = z.coerce
    .number(`${label} must be a number`)
    .min(0, `${label} must be greater than or equal to 0`);

  if (int) {
    schema = schema.int(`${label} must be an integer`);
  }

  if (max !== undefined) {
    schema = schema.max(max, `${label} must be at most ${max}`);
  }

  return schema;
};

/**
 * Rule kiểm tra boolean linh hoạt, tự động parse từ boolean, "true"/"false", 1/0
 */
const booleanRule = (label = "Value") =>
  z.preprocess(
    (val) => {
      if (typeof val === "boolean") return val;
      if (val === "true" || val === 1 || val === "1") return true;
      if (val === "false" || val === 0 || val === "0") return false;
      return val;
    },
    z.boolean(`${label} must be a boolean`),
  );

/**
 * Rule kiểm tra cờ trạng thái nhị phân (0 hoặc 1), tự động parse boolean/string
 */
const statusRule = (label = "Status") =>
  z
    .preprocess(
      (val) => {
        if (typeof val === "boolean") return val ? 1 : 0;
        if (val === "true" || val === "1") return 1;
        if (val === "false" || val === "0") return 0;
        return val;
      },
      z.coerce
        .number(`${label} must be 0 or 1`)
        .int(`${label} must be an integer`)
        .min(0, `${label} must be 0 or 1`)
        .max(1, `${label} must be 0 or 1`),
    )
    .default(1);

/**
 * Rule kiểm tra Căn cước công dân (CCCD 12 số) hoặc CMND (9 số) Việt Nam
 */
const identityCardRule = (label = "Identity card") =>
  requiredString(label, { min: 9, max: 12 }).regex(
    /^(?:\d{9}|\d{12})$/,
    `${label} must be a valid Vietnamese identity card number (9 or 12 digits)`,
  );

/**
 * Rule kiểm tra đường dẫn URL hợp lệ (link ảnh, website)
 */
const urlRule = (label = "URL") =>
  requiredString(label, { max: 2048 }).pipe(
    z.url(`${label} must be a valid URL`),
  );

/**
 * Rule kiểm tra chuỗi thời gian chuẩn ISO DateTime (YYYY-MM-DDTHH:mm:ssZ)
 */
const dateTimeRule = (label = "DateTime") =>
  requiredString(label, { max: 35 }).pipe(
    z.iso.datetime(`${label} must be in ISO 8601 format`),
  );

/**
 * Rule kiểm tra mã OTP (mặc định 6 chữ số)
 */
const otpRule = (label = "OTP", length = 6) =>
  requiredString(label, { min: length, max: length }).regex(
    new RegExp(`^\\d{${length}}$`),
    `${label} must be ${length} digits`,
  );

/**
 * Rule kiểm tra mảng các phần tử với tùy chọn số lượng tối thiểu và tối đa
 */
const arrayRule = <T extends z.ZodType>(
  itemSchemaOrLabel: T | string,
  optionsOrItemSchema?: { min?: number; max?: number } | T,
  options?: { min?: number; max?: number },
) => {
  let label = "Array";
  let itemSchema: T;
  let opts: { min?: number; max?: number } = {};

  if (typeof itemSchemaOrLabel === "string") {
    label = itemSchemaOrLabel;
    itemSchema = optionsOrItemSchema as T;
    opts = options ?? {};
  } else {
    itemSchema = itemSchemaOrLabel;
    opts = (optionsOrItemSchema as { min?: number; max?: number }) ?? {};
  }

  const { min = 0, max } = opts;
  let schema = z.array(itemSchema, {
    error: (issue) =>
      issue.input === undefined
        ? `${label} is required`
        : `${label} must be an array`,
  });

  if (min > 0) {
    schema = schema.min(min, `${label} must contain at least ${min} item(s)`);
  }

  if (max !== undefined) {
    schema = schema.max(max, `${label} must contain at most ${max} item(s)`);
  }

  return schema;
};

// Tạo phiên bản gọi trực tiếp hoặc hàm cho emailRule
const emailRuleSchema = emailRule();

export const ruleValidates = {
  requiredString,
  optionalString,
  emailRule: emailRuleSchema,
  emailRuleFn: emailRule,
  passwordRule,
  phoneRule,
  uuidRule,
  enumRule,
  numberRule,
  dateRule,
  idRule,
  positiveNumber,
  nonNegativeNumber,
  booleanRule,
  statusRule,
  identityCardRule,
  urlRule,
  dateTimeRule,
  otpRule,
  arrayRule,
};
