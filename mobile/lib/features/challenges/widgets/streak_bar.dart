import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

/// Thanh streak ngang: tiến độ chuỗi ngày tới mốc kế tiếp.
class StreakBar extends StatelessWidget {
  const StreakBar({
    super.key,
    required this.streak,
    this.cycleDays = 7,
  });

  final int streak;
  final int cycleDays;

  String get _icon => AppIcons.streakForDays(streak);

  int get _nextMilestone {
    if (streak < 7) return 7;
    if (streak < 30) return 30;
    if (streak < 90) return 90;
    if (streak < 120) return 120;
    return ((streak ~/ 30) + 1) * 30;
  }

  @override
  Widget build(BuildContext context) {
    final inCycle = streak % cycleDays;
    final filled = streak == 0 ? 0 : (inCycle == 0 ? cycleDays : inCycle);
    final next = _nextMilestone;
    final remain = (next - streak).clamp(0, 999);
    final toNext = streak == 0 ? 0.0 : (streak / next).clamp(0.0, 1.0);
    final icon = _icon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, width: 32, height: 32),
              const SizedBox(width: 8),
              const Text(
                'Streak',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              Text(
                streak == 0 ? 'Đứt chuỗi' : '$streak ngày',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 4.0;
              final cellW =
                  (constraints.maxWidth - gap * (cycleDays - 1)) / cycleDays;
              return Row(
                children: [
                  for (var i = 0; i < cycleDays; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    SizedBox(
                      width: cellW,
                      child: _DayPip(
                        dayIndex: i + 1,
                        active: i < filled,
                        iconAsset: icon,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: toNext,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            streak == 0
                ? 'Hoàn thành thử thách hôm nay để bắt đầu chuỗi mới'
                : remain == 0
                    ? 'Đã chạm mốc $next ngày!'
                    : 'Còn $remain ngày nữa tới mốc $next ngày',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPip extends StatelessWidget {
  const _DayPip({
    required this.dayIndex,
    required this.active,
    required this.iconAsset,
  });

  final int dayIndex;
  final bool active;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.35)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: active ? 1 : 0.35,
            child: Image.asset(
              iconAsset,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: active ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'N$dayIndex',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
