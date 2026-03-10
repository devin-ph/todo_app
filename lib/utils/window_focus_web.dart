import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Phát sự kiện mỗi khi cửa sổ trình duyệt lấy lại focus.
/// Dùng để phát hiện ngay lập tức khi người dùng đóng popup đăng nhập.
/// Listener được dọn dẹp tự động khi subscription bị hủy.
Stream<void> get windowFocusStream {
  return Stream.multi((controller) {
    // Flag đảm bảo không add event sau khi subscription bị hủy.
    var active = true;

    // Lưu cùng một tham chiếu JS để remove đúng listener sau này.
    late final JSFunction jsCallback;
    jsCallback = ((web.Event _) {
      if (active) controller.add(null);
    }).toJS;

    web.window.addEventListener('focus', jsCallback);

    controller.onCancel = () {
      active = false;
      web.window.removeEventListener('focus', jsCallback);
    };
  });
}
