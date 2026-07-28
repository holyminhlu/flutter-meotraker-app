import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

/// Banner tên menu trên cùng — chữ nhật vuông góc, full bề ngang.
class PageMenuBanner extends StatelessWidget {
  const PageMenuBanner({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
            const Color(0xFFFFE566),
          ],
        ),
        borderRadius: BorderRadius.zero,
        border: Border(
          bottom: BorderSide(
            color: AppColors.onPrimary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: trailing == null
          ? Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppColors.onPrimary,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                trailing!,
              ],
            ),
    );
  }
}
