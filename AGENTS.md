Please read these files first: @./.agents/rule/roomee.md
Always response with Vietnamese

## Response presentation

Always begin each response with the heading: ## 🤖 AI TRẢ LỜI:
End each response with a horizontal divider: ---
Do not place the entire response inside a code block
Use headings and clear spacing between sections

## IMPORTANT RULE

1. Think Before Coding Don't assume. Don't hide confusion. Surface tradeoffs.
   Before implementing:

State your assumptions explicitly. If uncertain, ask. If multiple interpretations exist, present them - don't pick silently. If a simpler approach exists, say so. Push back when warranted. If something is unclear, stop. Name what's confusing. Ask.

2. Simplicity First Minimum code that solves the problem. Nothing speculative.
   No features beyond what was asked. No abstractions for single-use code. No "flexibility" or "configurability" that wasn't requested. No error handling for impossible scenarios. If you write 200 lines and it could be 50, rewrite it. Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

3. Surgical Changes Touch only what you must. Clean up only your own mess.
   When editing existing code:

Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken. Match existing style, even if you'd do it differently. If you notice unrelated dead code, mention it - don't delete it. When your changes create orphans:

Remove imports/variables/functions that YOUR changes made unused. Don't remove pre-existing dead code unless asked. The test: Every changed line should trace directly to the user's request.

4. Goal-Driven Execution Define success criteria. Loop until verified.
   Transform tasks into verifiable goals:

"Add validation" → "Write tests for invalid inputs, then make them pass" "Fix the bug" → "Write a test that reproduces it, then make it pass" "Refactor X" → "Ensure tests pass before and after" For multi-step tasks, state a brief plan:

[Step] → verify: [check]
[Step] → verify: [check]
[Step] → verify: [check] Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Database & MCP Guidelines

When you need to check table schemas, data types, or indexes, or verify actual data for debugging purposes, please prioritize using the MCP server (via `dbhub / execute_sql` or `search_objects`).

SAFETY GUIDELINES:

Execute only READ-only queries (SELECT, SHOW, EXPLAIN).
DO NOT, under any circumstances, execute queries that modify the database structure or data (INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE) unless explicitly requested by the user.
Always include a `LIMIT` clause in `SELECT` statements to prevent loading excessive amounts of data, which could overwhelm the context window.

QUERY STANDARD (TypeORM):
- Ưu tiên sử dụng `createQueryBuilder` cho các truy vấn lấy dữ liệu từ database. Chỉ sử dụng các hàm truy vấn có sẵn như `findOneBy`, `findBy` cho các trường hợp cực kỳ đơn giản (tra cứu theo ID/khóa chính, 1 điều kiện cơ bản) theo quy tắc tại `@./.agents/rule/roomee.md`.

If the MCP server is not yet installed, please let me know so I can set it up for you.

Whenever you read this, please respond with ✅ READED AGENTS.md
