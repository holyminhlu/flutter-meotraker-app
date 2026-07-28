import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/habit_slogans.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/progress_sync_service.dart';
import 'package:meo_traker/data/services/settings_sync_service.dart';

class MealScheduleService extends ChangeNotifier {
  MealScheduleService._();
  static final MealScheduleService instance = MealScheduleService._();

  /// Hook sau khi đổi trạng thái bữa ăn (ProgressService lắng nghe).
  Future<void> Function()? onMealCompletionChanged;

  static const _defaultBreakfast = TimeOfDay(hour: 7, minute: 0);

  TimeOfDay breakfast = _defaultBreakfast;
  bool mealRemindersEnabled = true;
  bool warmWater = true;
  bool lightExercise = true;
  bool flexibleSkip = true;

  String _dateKey = '';
  final Map<MealPeriod, bool> completed = {
    MealPeriod.breakfast: false,
    MealPeriod.lunch: false,
    MealPeriod.dinner: false,
  };
  final Set<String> firedReminderIds = {};

  MealScheduleRow get row => scheduleForBreakfast(breakfast);
  List<MealPeriodConfig> get periods => mealPeriodsFor(row);
  List<MealReminderSlot> get reminderSlots => buildMealReminderSlots(row);
  List<EncouragementWindow> get encouragementWindows =>
      buildEncouragementWindows(breakfast);

  Future<File> _file() => AppStorage.file('meal_schedule.json');

  String _todayKey([DateTime? now]) {
    final d = now ?? AppClock.instance.now();
    return AppClock.instance.todayKey(d);
  }

  Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        _ensureToday();
        return;
      }
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final bh = (raw['breakfastHour'] as num?)?.toInt() ?? 7;
      final bm = (raw['breakfastMinute'] as num?)?.toInt() ?? 0;
      breakfast = TimeOfDay(hour: bh, minute: bm);
      mealRemindersEnabled = raw['mealRemindersEnabled'] as bool? ?? true;
      warmWater = raw['warmWater'] as bool? ?? true;
      lightExercise = raw['lightExercise'] as bool? ?? true;
      flexibleSkip = raw['flexibleSkip'] as bool? ?? true;

      _dateKey = raw['dateKey'] as String? ?? '';
      final today = _todayKey();
      if (_dateKey != today) {
        _resetDay(today);
      } else {
        final c = raw['completed'] as Map<String, dynamic>? ?? {};
        completed[MealPeriod.breakfast] = c['breakfast'] as bool? ?? false;
        completed[MealPeriod.lunch] = c['lunch'] as bool? ?? false;
        completed[MealPeriod.dinner] = c['dinner'] as bool? ?? false;
        firedReminderIds
          ..clear()
          ..addAll(
            ((raw['firedReminderIds'] as List?) ?? const [])
                .map((e) => e.toString()),
          );
      }
    } catch (_) {
      _ensureToday();
    }
    notifyListeners();
  }

  void _ensureToday() {
    final today = _todayKey();
    if (_dateKey != today) _resetDay(today);
  }

  void _resetDay(String today) {
    _dateKey = today;
    completed[MealPeriod.breakfast] = false;
    completed[MealPeriod.lunch] = false;
    completed[MealPeriod.dinner] = false;
    firedReminderIds.clear();
  }

  Future<void> savePrefs({
    required TimeOfDay breakfastTime,
    required bool mealReminders,
    required bool warmWaterHabit,
    required bool lightExerciseHabit,
    required bool allowFlexibleSkip,
  }) async {
    breakfast = breakfastTime;
    mealRemindersEnabled = mealReminders;
    warmWater = warmWaterHabit;
    lightExercise = lightExerciseHabit;
    flexibleSkip = allowFlexibleSkip;
    await _persist();
    notifyListeners();
    // ignore: unawaited_futures
    SettingsSyncService.instance.sync();
  }

  Future<void> setCompleted(MealPeriod period, bool value) async {
    _ensureToday();
    completed[period] = value;
    await _persist();
    notifyListeners();
    final hook = onMealCompletionChanged;
    if (hook != null) await hook();
    // ignore: unawaited_futures
    ProgressSyncService.instance.syncToday();
  }

  Future<void> markReminderFired(String id) async {
    _ensureToday();
    firedReminderIds.add(id);
    await _persist();
  }

  bool isCompleted(MealPeriod period) {
    _ensureToday();
    return completed[period] ?? false;
  }

  Future<void> _persist() async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({
        'breakfastHour': breakfast.hour,
        'breakfastMinute': breakfast.minute,
        'mealRemindersEnabled': mealRemindersEnabled,
        'warmWater': warmWater,
        'lightExercise': lightExercise,
        'flexibleSkip': flexibleSkip,
        'dateKey': _dateKey,
        'completed': {
          'breakfast': completed[MealPeriod.breakfast] ?? false,
          'lunch': completed[MealPeriod.lunch] ?? false,
          'dinner': completed[MealPeriod.dinner] ?? false,
        },
        'firedReminderIds': firedReminderIds.toList(),
      }),
    );
  }
}
