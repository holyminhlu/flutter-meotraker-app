import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';

export 'package:meo_traker/core/meal/meal_schedule.dart'
    show MealPeriod, MealPeriodConfig;

class MealPeriodBanner extends StatelessWidget {
  const MealPeriodBanner({
    super.key,
    required this.config,
    required this.completed,
    this.inWindow = false,
  });

  final MealPeriodConfig config;
  final bool completed;
  final bool inWindow;

  @override
  Widget build(BuildContext context) {
    final now = AppClock.instance.now();
    final start = config.startOn(now);
    final end = config.endOn(now);
    final timeLabel = '${_fmt(start)} – ${_fmt(end)}';

    final statusLabel = completed
        ? 'Đã xong'
        : inWindow
            ? 'Đang trong khung giờ'
            : 'Chờ khung giờ';
    final statusColor = completed
        ? AppColors.success
        : inWindow
            ? AppColors.primary
            : AppColors.textSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(config.bannerAsset, fit: BoxFit.cover),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            completed
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 16,
                            color: completed || inWindow
                                ? (completed
                                    ? Colors.white
                                    : AppColors.onPrimary)
                                : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: completed || !inWindow
                                  ? Colors.white
                                  : AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
