# Todo App

Ứng dụng quản lý công việc xây dựng bằng Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-success)

## ✨ Highlights

- Light/Dark mode
- Tạo, sửa, xóa, hoàn tác xóa (Undo)
- Tìm kiếm theo tiêu đề/mô tả theo thời gian thực
- Lọc theo trạng thái: Tất cả / Đang làm / Hoàn thành
- Ưu tiên công việc: Thấp / Trung bình / Cao
- Ghim công việc quan trọng
- Deadline theo ngày + giờ
- Sắp xếp linh hoạt: Smart / Deadline / Mới tạo / Ưu tiên
- Dọn dẹp nhanh các công việc đã hoàn thành

## 🗂️ Project Structure

```text
lib/
├─ main.dart                 # App entry, theme, routes
├─ models/
│  └─ todo_item.dart         # Data model + JSON serialization
├─ screens/
│  ├─ home_screen.dart       # Main todo experience
│  └─ settings_screen.dart   # Theme settings
├─ services/
│  └─ settings_service.dart  # Persist theme mode
└─ widgets/
   └─ todo_item_widget.dart  # Reusable task card
```

## 🚀 Getting Started

### 1) Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code + Flutter extension

Kiểm tra môi trường:

```bash
flutter doctor
```

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Run app

```bash
flutter run
```

Chạy trên web:

```bash
flutter run -d chrome
```

## 🧪 Testing

Chạy test widget hiện tại:

```bash
flutter test
```