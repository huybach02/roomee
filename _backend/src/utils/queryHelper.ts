import { SelectQueryBuilder, Brackets, ObjectLiteral } from "typeorm";
import { z } from "zod";

export const baseQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().optional(),
  sort: z.union([z.string(), z.array(z.string())]).optional(),
  sortBy: z.string().trim().optional(),
  sortOrder: z.enum(["asc", "desc", "ASC", "DESC"]).optional(),
  all: z
    .preprocess(
      (val) => val === "true" || val === true || val === "1" || val === 1,
      z.boolean(),
    )
    .optional(),
});

export type BaseQueryDto = z.infer<typeof baseQuerySchema>;

export type FilterOperator =
  | "eq"
  | "in"
  | "iLike"
  | "gte"
  | "lte"
  | "between"
  | "isNull"
  | "isNotNull";

export interface FilterRule {
  /**
   * Tên cột kèm alias trong SQL (hỗ trợ cả bảng chính lẫn bảng join).
   * Ví dụ: "workspace.type", "province.id", "ward.fullName", "user.role"
   */
  field: string;
  /**
   * Toán tử so sánh. Mặc định là "eq"
   */
  operator?: FilterOperator;
  /**
   * Tùy chọn chuyển đổi giá trị trước khi đưa vào SQL
   */
  transform?: (value: any) => any;
}

export type FilterSchema<TQuery = Record<string, any>> = {
  [K in keyof TQuery]?: FilterRule | FilterRule[];
};

export interface PaginationResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface SortItem {
  field?: string;
  order?: string;
}

export class QueryHelper {
  /**
   * 1. Multi-Field Search (Hỗ trợ cả bảng chính lẫn bảng JOIN)
   * Sử dụng CAST(... AS TEXT) để tìm kiếm an toàn trên cả cột text, số, enum.
   */
  public static applySearch<T extends ObjectLiteral>(
    qb: SelectQueryBuilder<T>,
    keyword: string | undefined | null,
    searchableFields: string[],
  ): SelectQueryBuilder<T> {
    if (
      !keyword ||
      keyword.trim().length === 0 ||
      searchableFields.length === 0
    ) {
      return qb;
    }

    const trimmed = keyword.trim();
    const paramName = `search_${Math.random().toString(36).substring(2, 8)}`;

    // Bọc trong Brackets để điều kiện OR không làm ảnh hưởng điều kiện AND của userId/tenant scoping và các filter khác
    qb.andWhere(
      new Brackets((subQb) => {
        searchableFields.forEach((field, index) => {
          const condition = `CAST(${field} AS TEXT) ILIKE :${paramName}`;
          if (index === 0) {
            subQb.where(condition, { [paramName]: `%${trimmed}%` });
          } else {
            subQb.orWhere(condition, { [paramName]: `%${trimmed}%` });
          }
        });
      }),
    );

    return qb;
  }

  /**
   * 2. Declarative Filters (Lọc linh động theo cấu hình Schema)
   */
  public static applyFilters<
    T extends ObjectLiteral,
    TQuery extends Record<string, any>,
  >(
    qb: SelectQueryBuilder<T>,
    query: TQuery,
    schema: FilterSchema<TQuery>,
  ): SelectQueryBuilder<T> {
    Object.entries(schema).forEach(([queryKey, rules]) => {
      const rawValue = (query as any)[queryKey];
      if (rawValue === undefined || rawValue === null || rawValue === "")
        return;

      const ruleList = Array.isArray(rules) ? rules : [rules as FilterRule];

      ruleList.forEach((rule, idx) => {
        const val = rule.transform ? rule.transform(rawValue) : rawValue;
        const operator = rule.operator || "eq";
        const paramName = `filter_${queryKey}_${idx}_${Math.random().toString(36).substring(2, 6)}`;

        switch (operator) {
          case "eq":
            qb.andWhere(`${rule.field} = :${paramName}`, { [paramName]: val });
            break;
          case "in": {
            const inValues = Array.isArray(val)
              ? val
              : typeof val === "string"
                ? val.split(",").map((s) => s.trim())
                : [val];
            if (inValues.length > 0) {
              qb.andWhere(`${rule.field} IN (:...${paramName})`, {
                [paramName]: inValues,
              });
            }
            break;
          }
          case "iLike":
            qb.andWhere(`CAST(${rule.field} AS TEXT) ILIKE :${paramName}`, {
              [paramName]: `%${val}%`,
            });
            break;
          case "gte":
            qb.andWhere(`${rule.field} >= :${paramName}`, { [paramName]: val });
            break;
          case "lte":
            qb.andWhere(`${rule.field} <= :${paramName}`, { [paramName]: val });
            break;
          case "isNull":
            if (val === true || val === "true" || val === 1 || val === "1") {
              qb.andWhere(`${rule.field} IS NULL`);
            }
            break;
          case "isNotNull":
            if (val === true || val === "true" || val === 1 || val === "1") {
              qb.andWhere(`${rule.field} IS NOT NULL`);
            }
            break;
        }
      });
    });

    return qb;
  }

  /**
   * 3. Parse chuỗi sắp xếp theo chuẩn RESTful
   * Hỗ trợ: "field:desc,field:asc", "-field,field", mảng string hoặc SortItem[]
   */
  public static parseSort(
    sortInput?: string | string[] | SortItem | SortItem[],
    fallbackSorts?: SortItem | SortItem[],
  ): SortItem[] {
    const fallbacks = fallbackSorts
      ? Array.isArray(fallbackSorts)
        ? fallbackSorts
        : [fallbackSorts]
      : [];

    if (!sortInput) return fallbacks;

    // Nếu đã là object SortItem hoặc SortItem[]
    if (typeof sortInput === "object") {
      if (!Array.isArray(sortInput)) return [sortInput];
      if (sortInput.length === 0) return fallbacks;
      if (typeof sortInput[0] === "object") return sortInput as SortItem[];
    }

    // Chuẩn hóa mọi dạng chuỗi về danh sách tokens
    const rawTokens = (Array.isArray(sortInput) ? sortInput : [sortInput])
      .flatMap((item) => (typeof item === "string" ? item.split(",") : []))
      .map((s) => s.trim())
      .filter(Boolean);

    const parsed: SortItem[] = rawTokens
      .map((token) => {
        if (token.includes(":")) {
          const [field, order] = token.split(":");
          return {
            field: field.trim(),
            order: order.trim().toUpperCase() === "ASC" ? "ASC" : "DESC",
          };
        }
        const isDesc = token.startsWith("-");
        const isAsc = token.startsWith("+");
        return {
          field: isDesc || isAsc ? token.slice(1).trim() : token,
          order: isDesc ? "DESC" : "ASC",
        };
      })
      .filter((item) => item.field.length > 0);

    return parsed.length > 0 ? parsed : fallbacks;
  }

  /**
   * 4. Sắp xếp an toàn (Tránh SQL Injection bằng Whitelist, hỗ trợ sắp xếp đa tiêu chí)
   */
  public static applySorting<T extends ObjectLiteral>(
    qb: SelectQueryBuilder<T>,
    sorts?: string | string[] | SortItem | SortItem[],
    sortOrderOrAllowed?: string | Record<string, string>,
    allowedSortFieldsInput: Record<string, string> = {},
    defaultSort: { field: string; order: "ASC" | "DESC" } = {
      field: "workspace.createdAt",
      order: "DESC",
    },
  ): SelectQueryBuilder<T> {
    let allowed: Record<string, string> = {};

    if (typeof sortOrderOrAllowed === "object" && sortOrderOrAllowed !== null) {
      allowed = sortOrderOrAllowed;
    } else {
      allowed = allowedSortFieldsInput;
    }

    const sortItems: SortItem[] = QueryHelper.parseSort(sorts);
    const validSorts = sortItems.filter((s) => s.field && allowed[s.field]);

    if (validSorts.length === 0) {
      qb.orderBy(defaultSort.field, defaultSort.order);
      return qb;
    }

    validSorts.forEach((sort, idx) => {
      const order = sort.order?.toUpperCase() === "ASC" ? "ASC" : "DESC";
      const column = allowed[sort.field!];
      if (idx === 0) {
        qb.orderBy(column, order);
      } else {
        qb.addOrderBy(column, order);
      }
    });

    return qb;
  }

  /**
   * 4. Phân trang chuẩn
   */
  public static async paginate<T extends ObjectLiteral>(
    qb: SelectQueryBuilder<T>,
    page: number = 1,
    limit: number = 20,
    all?: boolean,
  ): Promise<PaginationResult<T>> {
    if (all) {
      const data = await qb.getMany();
      return {
        data,
        total: data.length,
        page: 1,
        limit: data.length,
        totalPages: 1,
      };
    }

    const safePage = Math.max(1, page);
    const safeLimit = Math.max(1, Math.min(limit, 100));
    const skip = (safePage - 1) * safeLimit;

    qb.skip(skip).take(safeLimit);

    const [data, total] = await qb.getManyAndCount();

    return {
      data,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.ceil(total / safeLimit) || 1,
    };
  }
}
