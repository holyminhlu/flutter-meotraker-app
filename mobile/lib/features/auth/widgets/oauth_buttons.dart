import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class OAuthButtons extends StatelessWidget {
  const OAuthButtons({super.key});

  void _soon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đăng nhập $provider sắp được hỗ trợ. Hiện dùng email/SĐT.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Hoặc',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _soon(context, 'Google'),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: const Text('Tiếp tục với Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _soon(context, 'Apple'),
          icon: const Icon(Icons.apple, size: 22),
          label: const Text('Tiếp tục với Apple'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
