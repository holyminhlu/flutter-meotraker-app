import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/core/time/exercise_fab_schedule.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/chat/widgets/exercise_session_page.dart';

class _SlotDef {
  const _SlotDef({
    required this.title,
    required this.duration,
    required this.endHour,
    required this.endMinute,
    this.optional = false,
  });

  final String title;
  final String duration;
  final int endHour;
  final int endMinute;
  final bool optional;

  bool isPast(DateTime now) {
    if (ExerciseFabSchedule.forceEnabledForTest) return false;
    final end = DateTime(now.year, now.month, now.day, endHour, endMinute);
    return now.isAfter(end);
  }
}

const _slots = [
  _SlotDef(
    title: 'Buổi sáng',
    duration: '10 phút',
    endHour: 9,
    endMinute: 0,
  ),
  _SlotDef(
    title: 'Buổi xế chiều',
    duration: '10 phút',
    endHour: 17,
    endMinute: 30,
  ),
  _SlotDef(
    title: 'Buổi tối',
    duration: '10 phút',
    endHour: 22,
    endMinute: 0,
    optional: true,
  ),
];

/// Sheet nhanh khi chạm nút vận động — chọn buổi và bắt đầu tập.
class ExerciseQuickSheet extends StatelessWidget {
  const ExerciseQuickSheet({
    super.key,
    this.onOpenChallenges,
  });

  final VoidCallback? onOpenChallenges;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onOpenChallenges,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseQuickSheet(onOpenChallenges: onOpenChallenges),
    );
  }

  Future<void> _startSlot(BuildContext context, int index) async {
    final def = _slots[index];
    final now = AppClock.instance.now();
    final progress = ProgressService.instance;

    if (def.isPast(now) && !progress.exerciseSlots[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã bỏ lỡ "${def.title}" — không thể tập sau giờ.')),
      );
      return;
    }

    if (progress.exerciseSlots[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${def.title}" đã ghi nhận hôm nay.')),
      );
      return;
    }

    Navigator.of(context).pop();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ExerciseSessionPage(
          slotIndex: index,
          slotTitle: def.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final progress = ProgressService.instance;
        final inWindow = ExerciseFabSchedule.isActive();
        final done = progress.exerciseRequiredDone;
        final total = ProgressService.exerciseRequired;
        final now = AppClock.instance.now();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(AppIcons.vanDongNhe, width: 44, height: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vận động nhẹ',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              inWindow
                                  ? 'Sẵn sàng · ${ExerciseFabSchedule.windowLabel()}'
                                  : 'Ngoài khung giờ · ${ExerciseFabSchedule.windowLabel()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: inWindow
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tiến độ hôm nay: $done/$total khung bắt buộc'
                    '${progress.exerciseComplete ? ' · Đã đủ điểm' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _slots.length; i++)
                    _SlotActionRow(
                      title: _slots[i].title,
                      subtitle:
                          '${_slots[i].duration}${_slots[i].optional ? ' · tùy chọn' : ''}',
                      done: i < progress.exerciseSlots.length &&
                          progress.exerciseSlots[i],
                      missed: _slots[i].isPast(now) &&
                          !(i < progress.exerciseSlots.length &&
                              progress.exerciseSlots[i]),
                      enabled: inWindow ||
                          ExerciseFabSchedule.forceEnabledForTest,
                      onStart: () => _startSlot(context, i),
                    ),
                  const SizedBox(height: 8),
                  if (onOpenChallenges != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenChallenges!();
                        },
                        child: const Text('Xem chi tiết ở Thử thách'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlotActionRow extends StatelessWidget {
  const _SlotActionRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.missed,
    required this.enabled,
    required this.onStart,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool missed;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final statusColor = done
        ? AppColors.success
        : missed
            ? AppColors.error
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: done
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: (done || missed || !enabled) ? null : onStart,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  done
                      ? Icons.check_circle_rounded
                      : missed
                          ? Icons.cancel_rounded
                          : Icons.play_circle_outline_rounded,
                  size: 26,
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        done
                            ? 'Đã ghi nhận'
                            : missed
                                ? 'Đã bỏ lỡ'
                                : 'Chạm để bắt đầu · $subtitle',
                        style: TextStyle(fontSize: 12, color: statusColor),
                      ),
                    ],
                  ),
                ),
                if (!done && !missed && enabled)
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
