import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';

enum MealPeriod { breakfast, lunch, dinner }

class MealPeriodConfig {
  const MealPeriodConfig({
    required this.period,
    required this.title,
    required this.bannerAsset,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final MealPeriod period;
  final String title;
  final String bannerAsset;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  DateTime startOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMinute);

  DateTime endOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, endHour, endMinute);

  /// Banner for this meal becomes active 30 minutes before start.
  DateTime bannerStartOn(DateTime day) =>
      startOn(day).subtract(const Duration(minutes: 30));
}

class MealTimeRange {
  const MealTimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  TimeOfDay get start => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get end => TimeOfDay(hour: endHour, minute: endMinute);

  String get label {
    final a = _fmt(startHour, startMinute);
    final b = _fmt(endHour, endMinute);
    return a == b ? a : '$a – $b';
  }

  static String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Sleep guidance only — never used for notifications.
class SleepGuidance {
  const SleepGuidance({required this.label});

  final String label;
}

class MealScheduleRow {
  const MealScheduleRow({
    required this.breakfastHour,
    required this.breakfastMinute,
    required this.lunch,
    required this.dinner,
    required this.sleep,
  });

  final int breakfastHour;
  final int breakfastMinute;
  final MealTimeRange lunch;
  final MealTimeRange dinner;
  final SleepGuidance sleep;

  TimeOfDay get breakfast =>
      TimeOfDay(hour: breakfastHour, minute: breakfastMinute);

  int get breakfastMinutes => breakfastHour * 60 + breakfastMinute;
}

/// Khung giờ ăn cố định trong ngày.
const kBreakfastWindow = MealTimeRange(
  startHour: 7,
  startMinute: 0,
  endHour: 9,
  endMinute: 0,
);

const kLunchWindow = MealTimeRange(
  startHour: 12,
  startMinute: 30,
  endHour: 13,
  endMinute: 30,
);

const kDinnerWindow = MealTimeRange(
  startHour: 18,
  startMinute: 0,
  endHour: 19,
  endMinute: 30,
);

/// Bảng khung giờ: chọn giờ thức dậy / ăn sáng → suy ra giờ ngủ (tham khảo).
/// Trưa–tối luôn theo [kLunchWindow] / [kDinnerWindow].
const mealScheduleTable = <MealScheduleRow>[
  MealScheduleRow(
    breakfastHour: 6,
    breakfastMinute: 0,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '21:00 – 21:30'),
  ),
  MealScheduleRow(
    breakfastHour: 6,
    breakfastMinute: 30,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '21:30 – 22:00'),
  ),
  MealScheduleRow(
    breakfastHour: 7,
    breakfastMinute: 0,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '22:00 – 22:30'),
  ),
  MealScheduleRow(
    breakfastHour: 7,
    breakfastMinute: 30,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '22:30 – 23:00'),
  ),
  MealScheduleRow(
    breakfastHour: 8,
    breakfastMinute: 0,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '23:00 – 23:30'),
  ),
  MealScheduleRow(
    breakfastHour: 8,
    breakfastMinute: 30,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: '23:30 – 24:00'),
  ),
  MealScheduleRow(
    breakfastHour: 9,
    breakfastMinute: 0,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: 'Sau 23:30'),
  ),
  MealScheduleRow(
    breakfastHour: 10,
    breakfastMinute: 0,
    lunch: kLunchWindow,
    dinner: kDinnerWindow,
    sleep: SleepGuidance(label: 'Sau 24:00'),
  ),
];

MealScheduleRow scheduleForBreakfast(TimeOfDay breakfast) {
  final minutes = breakfast.hour * 60 + breakfast.minute;
  MealScheduleRow? best;
  for (final row in mealScheduleTable) {
    if (row.breakfastMinutes == minutes) return row;
    if (row.breakfastMinutes <= minutes) best = row;
  }
  return best ?? mealScheduleTable[2]; // default 07:00
}

class MealReminderSlot {
  const MealReminderSlot({
    required this.period,
    required this.mealAt,
    required this.notifyAt,
    required this.id,
  });

  final MealPeriod period;
  final TimeOfDay mealAt;
  final TimeOfDay notifyAt;
  final String id;

  String get mealLabel {
    switch (period) {
      case MealPeriod.breakfast:
        return 'ăn sáng';
      case MealPeriod.lunch:
        return 'ăn trưa';
      case MealPeriod.dinner:
        return 'ăn tối';
    }
  }

  String get message {
    final t =
        '${mealAt.hour.toString().padLeft(2, '0')}:${mealAt.minute.toString().padLeft(2, '0')}';
    return 'Sắp đến giờ $mealLabel ($t) — còn 15 phút. Đừng bỏ lỡ nhé!';
  }
}

TimeOfDay _minus15(TimeOfDay t) {
  var m = t.hour * 60 + t.minute - 15;
  if (m < 0) m += 24 * 60;
  return TimeOfDay(hour: m ~/ 60, minute: m % 60);
}

/// Mốc nhắc ăn sáng trong khung 07:00–09:00 (từ giờ thức dậy nếu nằm trong khung).
List<TimeOfDay> breakfastMilestones(MealScheduleRow row) {
  final windowStart = kBreakfastWindow.startHour * 60 + kBreakfastWindow.startMinute;
  final windowEnd = kBreakfastWindow.endHour * 60 + kBreakfastWindow.endMinute;
  final start = row.breakfastMinutes < windowStart
      ? windowStart
      : row.breakfastMinutes;
  if (start > windowEnd) {
    return [
      TimeOfDay(
        hour: kBreakfastWindow.endHour,
        minute: kBreakfastWindow.endMinute,
      ),
    ];
  }
  return mealScheduleTable
      .where((r) =>
          r.breakfastMinutes >= start && r.breakfastMinutes <= windowEnd)
      .map((r) => r.breakfast)
      .toList();
}

List<TimeOfDay> rangeMilestones(MealTimeRange range) {
  final start = range.start;
  final end = range.end;
  if (start.hour == end.hour && start.minute == end.minute) {
    return [start];
  }
  return [start, end];
}

/// Tất cả slot nhắc ăn (không gồm ngủ). Nhắc trước mỗi mốc 15 phút.
List<MealReminderSlot> buildMealReminderSlots(MealScheduleRow row) {
  final slots = <MealReminderSlot>[];

  for (final mealAt in breakfastMilestones(row)) {
    final notify = _minus15(mealAt);
    slots.add(
      MealReminderSlot(
        period: MealPeriod.breakfast,
        mealAt: mealAt,
        notifyAt: notify,
        id: 'breakfast_${mealAt.hour}_${mealAt.minute}',
      ),
    );
  }

  for (final mealAt in rangeMilestones(row.lunch)) {
    slots.add(
      MealReminderSlot(
        period: MealPeriod.lunch,
        mealAt: mealAt,
        notifyAt: _minus15(mealAt),
        id: 'lunch_${mealAt.hour}_${mealAt.minute}',
      ),
    );
  }

  for (final mealAt in rangeMilestones(row.dinner)) {
    slots.add(
      MealReminderSlot(
        period: MealPeriod.dinner,
        mealAt: mealAt,
        notifyAt: _minus15(mealAt),
        id: 'dinner_${mealAt.hour}_${mealAt.minute}',
      ),
    );
  }

  return slots;
}

List<MealPeriodConfig> mealPeriodsFor(MealScheduleRow row) {
  return [
    MealPeriodConfig(
      period: MealPeriod.breakfast,
      title: 'Bữa sáng',
      bannerAsset: AppIcons.buaSang,
      startHour: kBreakfastWindow.startHour,
      startMinute: kBreakfastWindow.startMinute,
      endHour: kBreakfastWindow.endHour,
      endMinute: kBreakfastWindow.endMinute,
    ),
    MealPeriodConfig(
      period: MealPeriod.lunch,
      title: 'Bữa trưa',
      bannerAsset: AppIcons.buaTrua,
      startHour: row.lunch.startHour,
      startMinute: row.lunch.startMinute,
      endHour: row.lunch.endHour,
      endMinute: row.lunch.endMinute,
    ),
    MealPeriodConfig(
      period: MealPeriod.dinner,
      title: 'Bữa tối',
      bannerAsset: AppIcons.buaToi,
      startHour: row.dinner.startHour,
      startMinute: row.dinner.startMinute,
      endHour: row.dinner.endHour,
      endMinute: row.dinner.endMinute,
    ),
  ];
}

MealPeriodConfig activeMealPeriodFor(
  List<MealPeriodConfig> periods,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final breakfast = periods[0];
  final lunch = periods[1];
  final dinner = periods[2];

  final lunchBannerAt = lunch.bannerStartOn(today);
  final dinnerBannerAt = dinner.bannerStartOn(today);
  final tomorrowBreakfastBannerAt =
      breakfast.bannerStartOn(today.add(const Duration(days: 1)));
  final todayBreakfastBannerAt = breakfast.bannerStartOn(today);

  if (now.isBefore(todayBreakfastBannerAt)) return dinner;
  if (now.isBefore(lunchBannerAt)) return breakfast;
  if (now.isBefore(dinnerBannerAt)) return lunch;
  if (now.isBefore(tomorrowBreakfastBannerAt)) return dinner;
  return breakfast;
}

/// Đang nằm trong khung giờ ăn của bữa (start–end).
bool isWithinMealWindow(MealPeriodConfig cfg, DateTime now) {
  final start = cfg.startOn(now);
  final end = cfg.endOn(now);
  return !now.isBefore(start) && !now.isAfter(end);
}

/// Bữa đang mở để ghi nhận ảnh; null nếu ngoài mọi khung giờ.
MealPeriodConfig? openMealPeriodFor(
  List<MealPeriodConfig> periods,
  DateTime now,
) {
  for (final cfg in periods) {
    if (isWithinMealWindow(cfg, now)) return cfg;
  }
  return null;
}

/// Cho phép chụp khi đang trong khung giờ bữa và bữa đó chưa ghi nhận xong.
bool canCaptureMealNow({
  required List<MealPeriodConfig> periods,
  required DateTime now,
  required bool Function(MealPeriod period) isCompleted,
}) {
  final open = openMealPeriodFor(periods, now);
  if (open == null) return false;
  return !isCompleted(open.period);
}

/// Bữa kế tiếp chưa mở (sau [now]); dùng cho nhãn chờ.
MealPeriodConfig nextMealPeriodAfter(
  List<MealPeriodConfig> periods,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  MealPeriodConfig? best;
  DateTime? bestAt;

  void consider(MealPeriodConfig cfg, DateTime day) {
    final start = cfg.startOn(day);
    if (!start.isAfter(now)) return;
    if (bestAt == null || start.isBefore(bestAt!)) {
      bestAt = start;
      best = cfg;
    }
  }

  for (final cfg in periods) {
    consider(cfg, today);
  }
  for (final cfg in periods) {
    consider(cfg, today.add(const Duration(days: 1)));
  }
  return best ?? periods.first;
}

String captureBlockedLabel({
  required List<MealPeriodConfig> periods,
  required DateTime now,
}) {
  String fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime startOf(MealPeriodConfig cfg) {
    final todayStart = cfg.startOn(now);
    if (todayStart.isAfter(now)) return todayStart;
    return cfg.startOn(now.add(const Duration(days: 1)));
  }

  final next = nextMealPeriodAfter(periods, now);
  return 'Chờ tới giờ buổi ${mealPeriodShortName(next.period)}'
      ' · ${fmt(startOf(next))}';
}


enum MealTimingKind { onTime, tooEarly, tooLate }

/// Gán bữa theo thời điểm chụp: trong khung = đúng giờ; ngoài = sớm/trễ gần nhất.
class MealTimingContext {
  const MealTimingContext({
    required this.config,
    required this.kind,
  });

  final MealPeriodConfig config;
  final MealTimingKind kind;

  MealPeriod get period => config.period;
  bool get inWindow => kind == MealTimingKind.onTime;

  String get timingLabelVi {
    switch (kind) {
      case MealTimingKind.onTime:
        return 'Đúng khung giờ';
      case MealTimingKind.tooEarly:
        return 'Ăn quá sớm';
      case MealTimingKind.tooLate:
        return 'Ăn quá trễ';
    }
  }
}

MealTimingContext resolveMealTiming(
  List<MealPeriodConfig> periods,
  DateTime now,
) {
  final open = openMealPeriodFor(periods, now);
  if (open != null) {
    return MealTimingContext(config: open, kind: MealTimingKind.onTime);
  }

  MealPeriodConfig? bestCfg;
  MealTimingKind? bestKind;
  Duration? bestDist;

  void consider(MealPeriodConfig cfg, DateTime day) {
    final start = cfg.startOn(day);
    final end = cfg.endOn(day);
    if (now.isBefore(start)) {
      final d = start.difference(now);
      if (bestDist == null || d < bestDist!) {
        bestDist = d;
        bestCfg = cfg;
        bestKind = MealTimingKind.tooEarly;
      }
    } else if (now.isAfter(end)) {
      final d = now.difference(end);
      if (bestDist == null || d < bestDist!) {
        bestDist = d;
        bestCfg = cfg;
        bestKind = MealTimingKind.tooLate;
      }
    }
  }

  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  for (final cfg in periods) {
    consider(cfg, today);
  }
  // Sáng sớm trước bữa sáng: có thể là tối hôm trước quá trễ
  consider(periods[2], yesterday);
  // Khuya sau bữa tối: có thể là sáng mai quá sớm
  consider(periods[0], tomorrow);

  return MealTimingContext(
    config: bestCfg ?? periods.first,
    kind: bestKind ?? MealTimingKind.tooLate,
  );
}

/// Nhãn nút ghi nhận theo buổi (chiều = bữa tối).
String mealCaptureButtonLabel(MealPeriod period) {
  switch (period) {
    case MealPeriod.breakfast:
      return 'Ghi nhận bữa sáng';
    case MealPeriod.lunch:
      return 'Ghi nhận bữa trưa';
    case MealPeriod.dinner:
      return 'Ghi nhận bữa chiều';
  }
}

String mealPeriodShortName(MealPeriod period) {
  switch (period) {
    case MealPeriod.breakfast:
      return 'sáng';
    case MealPeriod.lunch:
      return 'trưa';
    case MealPeriod.dinner:
      return 'chiều';
  }
}
