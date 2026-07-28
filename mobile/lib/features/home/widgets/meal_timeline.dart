import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

enum MealStatus { eaten, upcoming, missed }

class MealSlot {
  const MealSlot({
    required this.id,
    required this.period,
    required this.title,
    required this.timeLabel,
    required this.status,
    this.countdownMinutes,
    this.inWindow = false,
    this.foodItems = const [],
    this.past = false,
  });

  final String id;
  final MealPeriod period;
  final String title;
  final String timeLabel;
  final MealStatus status;
  final int? countdownMinutes;
  final bool inWindow;
  final List<String> foodItems;
  final bool past;
}

String _missedNudge(MealPeriod period) {
  switch (period) {
    case MealPeriod.breakfast:
      return 'Bạn đã bỏ lỡ bữa sáng — đừng để bữa tiếp theo trôi qua nữa.';
    case MealPeriod.lunch:
      return 'Bữa trưa đã lỡ. Cơ thể cần bạn quyết tâm hơn ở bữa tối.';
    case MealPeriod.dinner:
      return 'Bữa tối bỏ lỡ rồi. Mai bắt đầu lại — bạn làm được.';
  }
}

/// Bữa ăn hôm nay — danh sách dọc; bữa bỏ lỡ nổi bật đỏ.
class MealTimeline extends StatelessWidget {
  const MealTimeline({
    super.key,
    required this.meals,
  });

  final List<MealSlot> meals;

  @override
  Widget build(BuildContext context) {
    final missedCount =
        meals.where((m) => m.status == MealStatus.missed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bữa ăn hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (missedCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '$missedCount đã bỏ lỡ',
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
        for (var i = 0; i < meals.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MealRow(meal: meals[i], index: i + 1),
        ],
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal, required this.index});

  final MealSlot meal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final missed = meal.status == MealStatus.missed;
    final Color accent;
    final String statusText;
    final IconData statusIcon;

    switch (meal.status) {
      case MealStatus.eaten:
        accent = AppColors.success;
        statusText = 'Đã ghi nhận';
        statusIcon = Icons.check_circle_rounded;
      case MealStatus.upcoming:
        accent = meal.inWindow ? AppColors.primary : AppColors.textSecondary;
        statusText = meal.inWindow
            ? 'Đang mở'
            : meal.countdownMinutes != null
                ? 'Còn ${meal.countdownMinutes} phút'
                : 'Sắp tới';
        statusIcon =
            meal.inWindow ? Icons.restaurant_rounded : Icons.schedule_rounded;
      case MealStatus.missed:
        accent = AppColors.error;
        statusText = 'Đã bỏ lỡ';
        statusIcon = Icons.cancel_rounded;
    }

    final bg = missed
        ? AppColors.error.withValues(alpha: 0.1)
        : (meal.inWindow
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface);
    final titleColor = missed ? AppColors.error : AppColors.textPrimary;
    final borderColor = missed
        ? AppColors.error
        : (meal.inWindow
            ? AppColors.primary.withValues(alpha: 0.7)
            : AppColors.border);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: missed || meal.inWindow ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: missed ? 0.18 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: missed
                    ? Icon(Icons.close_rounded, color: accent, size: 22)
                    : Text(
                        '$index',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: accent,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: titleColor,
                            ),
                          ),
                        ),
                        Icon(statusIcon, size: 18, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: missed
                            ? AppColors.error.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (missed) ...[
            const SizedBox(height: 10),
            Text(
              _missedNudge(meal.period),
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ] else if (meal.foodItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: meal.foodItems
                  .take(4)
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
