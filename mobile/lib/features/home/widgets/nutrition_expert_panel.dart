import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/meal_log_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';

String _missedExpertNudge(MealPeriod period) {
  switch (period) {
    case MealPeriod.breakfast:
      return 'Bữa sáng đã bỏ lỡ — đây là nền tảng năng lượng cả ngày. Bữa sau đừng để trượt nữa.';
    case MealPeriod.lunch:
      return 'Bữa trưa bỏ lỡ rồi. Cơ thể đang chờ bạn chứng minh sự quyết tâm ở bữa tối.';
    case MealPeriod.dinner:
      return 'Bữa tối đã bỏ lỡ. Một ngày chưa hoàn thành — mai bạn sẽ làm tốt hơn.';
  }
}

/// Lịch sử món AI + lời khuyên; bữa bỏ lỡ nổi bật để thúc đẩy quyết tâm.
class NutritionExpertPanel extends StatelessWidget {
  const NutritionExpertPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        MealLogService.instance,
        MealScheduleService.instance,
      ]),
      builder: (context, _) {
        final schedule = MealScheduleService.instance;
        final logs = MealLogService.instance;
        final now = AppClock.instance.now();
        final missedCount = schedule.periods
            .where(
              (cfg) =>
                  now.isAfter(cfg.endOn(now)) &&
                  !schedule.isCompleted(cfg.period),
            )
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: missedCount > 0
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    missedCount > 0
                        ? Icons.warning_amber_rounded
                        : Icons.health_and_safety_rounded,
                    color: missedCount > 0
                        ? AppColors.error
                        : AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chuyên gia dinh dưỡng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (missedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '$missedCount bỏ lỡ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final cfg in schedule.periods) ...[
              _ExpertMealCard(
                config: cfg,
                log: logs.logFor(cfg.period),
                past: now.isAfter(cfg.endOn(now)),
                inWindow: isWithinMealWindow(cfg, now),
                completed: schedule.isCompleted(cfg.period),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ExpertMealCard extends StatelessWidget {
  const _ExpertMealCard({
    required this.config,
    required this.log,
    required this.past,
    required this.inWindow,
    required this.completed,
  });

  final MealPeriodConfig config;
  final MealFoodLog? log;
  final bool past;
  final bool inWindow;
  final bool completed;

  bool get _hasLog {
    if (log == null) return false;
    return log!.foodItems.isNotEmpty ||
        (log!.description?.trim().isNotEmpty ?? false) ||
        log!.advice.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final now = AppClock.instance.now();
    final start = config.startOn(now);
    final end = config.endOn(now);
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final hasLog = _hasLog;
    final missed = past && !completed;

    final Color borderColor;
    final Color bg;
    if (missed) {
      borderColor = AppColors.error;
      bg = AppColors.error.withValues(alpha: 0.1);
    } else if (inWindow && !completed) {
      borderColor = AppColors.primary;
      bg = AppColors.primary.withValues(alpha: 0.08);
    } else {
      borderColor = AppColors.border;
      bg = AppColors.surface;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: missed || (inWindow && !completed) ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                missed
                    ? Icons.cancel_rounded
                    : (completed || hasLog
                        ? Icons.check_circle_rounded
                        : (inWindow
                            ? Icons.restaurant_rounded
                            : Icons.schedule_rounded)),
                size: 22,
                color: missed
                    ? AppColors.error
                    : (completed || hasLog
                        ? AppColors.success
                        : (inWindow
                            ? AppColors.onPrimary
                            : AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: missed ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
              if (missed)
                Text(
                  'Đã bỏ lỡ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                )
              else
                Text(
                  '${fmt(start)}–${fmt(end)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (missed)
            Text(
              _missedExpertNudge(config.period),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            )
          else if (!hasLog)
            Text(
              inWindow ? 'Đang mở — sẵn sàng ghi nhận.' : 'Chưa tới giờ.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            if (log!.foodItems.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: log!.foodItems
                    .map(
                      (f) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (log!.description != null &&
                log!.description!.trim().isNotEmpty) ...[
              if (log!.foodItems.isNotEmpty) const SizedBox(height: 8),
              Text(
                log!.description!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (log!.advice.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log!.advice,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
