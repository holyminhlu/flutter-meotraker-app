import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class MotivationBanner extends StatelessWidget {
  const MotivationBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(AppIcons.mucTieu, width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  const BadgeCard({super.key, required this.badge, required this.streak});

  final String badge;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.asset(AppIcons.anMungDatMoc, width: 48, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔥 Chuỗi $streak ngày duy trì đều đặn',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String badgeLabelForStreak(int streak) {
  if (streak >= 30) return 'Huy hiệu 30 ngày';
  if (streak >= 14) return 'Hạng Bạc';
  if (streak >= 7) return 'Hạng Đồng';
  return 'Tân binh';
}

String motivationText({
  required double currentWeight,
  required double startWeight,
  required int weeksTracking,
  required int streak,
}) {
  final gained = currentWeight - startWeight;
  if (gained >= 0.3) {
    return 'Bạn đã tăng được ${gained.toStringAsFixed(1)}kg trong $weeksTracking tuần!\nGiữ nhịp này nhé.';
  }
  if (streak >= 7) {
    return 'Streak $streak ngày — đều đặn là chìa khóa tăng cân bền vững!';
  }
  return 'Mỗi bữa đúng giờ + nước + vận động = điểm thưởng. Bắt đầu từ hôm nay!';
}
