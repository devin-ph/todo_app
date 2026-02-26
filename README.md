### Ứng dụng Todo App

**Quick links**
- Source entry: [todo_app/lib/main.dart](todo_app/lib/main.dart)
- Home screen: [todo_app/lib/screens/home_screen.dart](todo_app/lib/screens/home_screen.dart)
- Model: [todo_app/lib/models/todo_item.dart](todo_app/lib/models/todo_item.dart)
- Widget: [todo_app/lib/widgets/todo_item_widget.dart](todo_app/lib/widgets/todo_item_widget.dart)

**1. Cấu trúc dự án (tóm tắt)**
- **android/**, **ios/**, **linux/**, **macos/**, **web/**, **windows/**: nền tảng
	do Flutter sinh ra.
- **lib/**: mã nguồn ứng dụng.
	- [lib/main.dart](todo_app/lib/main.dart): điểm khởi đầu `MyApp`, cấu hình
		theme và gọi `HomeScreen`.
	- [lib/screens/home_screen.dart](todo_app/lib/screens/home_screen.dart): màn
		hình chính, quản lý trạng thái todo list, lưu/đọc bằng
		`SharedPreferences`, logic thêm/sửa/xóa, tìm kiếm, phân lọc (tabs),
		animation và UI tương tác.
	- [lib/models/todo_item.dart](todo_app/lib/models/todo_item.dart): lớp dữ liệu
		`TodoItem` với serialize/deserialize (toMap/fromMap/toJson/fromJson).
	- [lib/widgets/todo_item_widget.dart](todo_app/lib/widgets/todo_item_widget.dart):
		widget hiển thị từng mục công việc, checkbox, nút sửa/xóa và một số
		animation/transition.
- **test/**: chứa test mẫu (nếu có thể mở rộng để thêm unit/widget tests).

**2. Luồng chính**
- `main.dart` khởi tạo `MaterialApp` và `HomeScreen`.
- `HomeScreen` là `StatefulWidget` chứa danh sách `_todos` (List<TodoItem>) và
	`AnimatedList` để hiển thị các item với hiệu ứng chèn/xóa. Các tính năng
	chính:
	- Lưu/đọc dữ liệu: `_loadTodos()` / `_saveTodos()` sử dụng
		`SharedPreferences` với key `_storageKey` (mảng chuỗi JSON).
	- Thêm/Sửa: `_showAddEditSheet()` hiển thị modal bottom sheet có form để
		nhập tiêu đề, mô tả và hẹn ngày/giờ. Khi lưu, tạo `TodoItem` mới hoặc
		cập nhật item hiện có.
	- Xóa: `_confirmDelete()` hiển thị dialog xác nhận, `_deleteTodo()` xử lý
		xóa và animation remove từ `AnimatedList`.
	- Tìm kiếm & lọc: thanh tìm kiếm và `TabBar` (Tất cả / Chưa xong / Đã xong).
	- Giao diện: nhiều chỗ dùng `AnimatedContainer`, `AnimatedSwitcher`,
		`TweenAnimationBuilder` để tăng trải nghiệm người dùng.