import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/window_focus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _isStatusError = false;

  StreamSubscription<void>? _focusSub;

  @override
  void initState() {
    super.initState();
    // Lắng nghe focus trình duyệt để phát hiện ngay khi popup đóng.
    // Khi user đóng popup, cửa sổ chính lấy lại focus → hiển thị phản hồi
    // tức thì thay vì chờ Firebase poll (~1 giây).
    _focusSub = windowFocusStream.listen((_) {
      if (!mounted || !_isLoading) return;
      setState(() {
        _statusMessage = 'Đang kiểm tra kết quả đăng nhập...';
        _isStatusError = false;
      });
    });
  }

  @override
  void dispose() {
    _focusSub?.cancel();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isStatusError = false;
    });

    try {
      await AuthService.signInWithGoogle();
      // Đăng nhập thành công → AuthGate tự chuyển màn hình
    } on AuthCancelledException {
      if (mounted) {
        setState(() {
          _statusMessage = 'Bạn đã đóng cửa sổ đăng nhập. Nhấn nút để thử lại.';
          _isStatusError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
          _isStatusError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      // Đặt lại trạng thái loading sau khi Firebase xử lý xong.
      // Nếu đã hiện 'Đang kiểm tra...' (do focus event), text này sẽ bị
      // thay thế bởi kết quả thực ở trên nên không cần reset riêng.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todo App',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để đồng bộ và sử dụng ứng dụng',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isStatusError
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Đang đăng nhập...' : 'Đăng nhập với Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
