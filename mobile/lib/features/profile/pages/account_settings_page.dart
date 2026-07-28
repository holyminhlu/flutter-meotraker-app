import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/features/auth/forgot_password_page.dart';
import 'package:meo_traker/features/auth/login_page.dart';
import 'package:meo_traker/features/auth/widgets/auth_text_field.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Toàn bộ dữ liệu hồ sơ sẽ bị xóa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yêu cầu xóa tài khoản đã ghi nhận (demo)')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'ban@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _phoneCtrl,
            label: 'Số điện thoại',
            hint: '09xxxxxxxx',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật liên hệ (demo)')),
              );
            },
            child: const Text('Lưu Email / SĐT'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Liên kết Google/Apple sắp hỗ trợ.'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.onPrimary,
              side: BorderSide(color: AppColors.border),
            ),
            child: const Text('Liên kết OAuth (Google / Apple)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.onPrimary,
              side: BorderSide(color: AppColors.border),
            ),
            child: const Text('Đổi mật khẩu'),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Đăng xuất'),
          ),
          TextButton(
            onPressed: _deleteAccount,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
  }
}
