# Thiết kế LocalQueryEngine — Giai đoạn 5

## Mục tiêu

Tạo bộ query engine dùng chung trong bộ nhớ để các feature có thể search, filter, sort và paginate danh sách đã đọc từ cache, thay vì tự viết thuật toán riêng. Giai đoạn này chỉ xây core query infrastructure, chưa tích hợp vào Workspace hay datasource nào.

## Cấu trúc

Tách theo trách nhiệm trong `lib/core/offline/query/`:

- `local_query_schema.dart`: schema whitelist search/filter/sort field; filter field dùng descriptor chứa getter và tập operator được phép.
- `local_filter_rule.dart`: enum operator và descriptor `LocalFilterField<T>`.
- `offline_page.dart`: `DataSourceKind` và `OfflinePage<T>`.
- `search_normalizer.dart`: hàm chuẩn hóa trim/lowercase/bỏ dấu dùng package `diacritic`.
- `local_query_engine.dart`: áp dụng search → filter → sort → pagination trên danh sách được truyền vào.

## Hợp đồng API

Engine nhận danh sách `List<T>`, `Map<String, dynamic>` query parameters, `LocalQuerySchema<T>`, và `CacheMetadata?`. Engine không mở Hive box hay gọi repository.

Query parameters tương thích caller hiện tại:

- `search`: chuỗi tìm kiếm.
- Filter đơn: giá trị trực tiếp, ví dụ `status: 1`, tương đương `equals`.
- Filter tường minh hỗ trợ đúng các tên operator: `equals`, `notEquals`, `contains`, `inList`, `greaterThan`, `lessThan`, `between`, `isNull`. Ví dụ `{operator: 'between', value: [20, 100]}`; `isNull` không cần value.
- `sort`: danh sách ưu tiên dạng `area:desc,name:asc`; field phải có trong `sortFields`, chiều chỉ nhận `asc`/`desc`.
- `page` và `limit`: số nguyên dương. `page` thiếu/sai/nhỏ hơn 1 dùng 1; `limit` thiếu/sai/nhỏ hơn 1 dùng mặc định 20. Không đặt giới hạn tối đa mới trong phase này.

Schema search có danh sách getter chuỗi; sort là map field → getter `Comparable?`; filter là map field → `LocalFilterField<T>` gồm getter và set operator được whitelist. `uniqueId` là getter chuỗi tùy chọn.

## Quy tắc xử lý

1. Chuẩn hóa từ khóa và mỗi giá trị search bằng cùng một hàm: bỏ dấu bằng `diacritic`, trim, lowercase; so khớp substring.
2. Thực hiện search trên tất cả search field đã khai báo.
3. Áp dụng mọi filter có field/operator hợp lệ. Filter trực tiếp tương đương `equals`. Field không whitelisted, operator không whitelisted, hoặc value sai hình dạng/type bị bỏ qua.
4. `contains` trên chuỗi dùng cùng chuẩn hóa không dấu; `between` là inclusive; `isNull` kiểm tra getter trả null; `inList` nhận list. `equals`, `notEquals` và `inList` dùng equality Dart, kể cả giá trị null. Các toán tử thứ tự chấp nhận int/double so sánh chéo qua `num`; value không phải số hoặc field null làm filter bị bỏ qua.
5. Sắp xếp theo tiêu chí `sort` theo đúng thứ tự chuỗi. Field/chiều sai hoặc không hợp lệ bị bỏ qua. Giá trị null đứng sau giá trị khác bất kể asc/desc. Khi tất cả tiêu chí bằng nhau, `uniqueId` tăng dần là tie-break; nếu không có hoặc ID bằng nhau, giữ thứ tự đầu vào ổn định.
6. Tính `total` sau search/filter, rồi mới cắt trang. `totalPages` tối thiểu là 1 kể cả danh sách rỗng; không ép page vượt phạm vi về trang cuối.
7. `OfflinePage.source` là `local`. `isComplete` và `lastFetchedAt` lấy từ metadata; nếu metadata null, dùng `false` và `null`. `total` chỉ mô tả số bản ghi khớp trong cache; caller không được coi là tổng server khi `isComplete == false`.

## Approaches

1. Engine nhận danh sách đã đọc từ cache và query map/schema/metadata; thuần Dart trong bộ nhớ, không phụ thuộc Hive và có thể tái sử dụng với bất kỳ entity nào. Đây là lựa chọn đã thống nhất.
2. Engine tự đọc từ Hive/store; ít bước ở caller nhưng buộc query layer phụ thuộc persistence và khó tái sử dụng/kiểm thử độc lập. Không chọn.

Search normalization có thể tự duy trì bảng chuyển đổi hoặc dùng package. Chọn `diacritic` để tránh tự duy trì bảng dấu; dependency version sẽ được solver xác nhận khi triển khai.

## Ngoài phạm vi

- Không tích hợp Workspace UI/BLoC/repository/datasource.
- Không thay đổi cache completeness hay metadata lifecycle.
- Không ghi dữ liệu vào Hive, không thêm cache sync, không thêm model codec.
- Không thay đổi API remote hoặc query backend.

## Kiểm chứng

Unit tests cho search tiếng Việt không dấu/hoa/thừa khoảng trắng; từng operator và whitelist; parsing query lỗi bị bỏ qua; multi-sort và null/tie-break ổn định; search/filter/sort xảy ra trước pagination; metadata/source/total/empty-result semantics.
