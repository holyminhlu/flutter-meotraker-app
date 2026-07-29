import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/progress_sync_service.dart';

/// Tiến độ người dùng (điểm, streak, thử thách, lịch sử, cân nặng).
/// Lưu 1 file local — không tạo bảng DB mới.
class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const int mealPoints = 1;
  static const int waterPoints = 1;
  static const int exercisePoints = 1;
  static const int waterThreshold = 5;
  static const int exerciseRequired = 2;

  int points = 0;
  int streak = 0;
  String? lastStreakDate;

  String _dateKey = '';
  List<bool> waterSlots = List<bool>.filled(6, false);
  List<bool> exerciseSlots = List<bool>.filled(3, false);
  /// Slot nào đã hoàn thành đủ phiên tập và nhận +1 điểm.
  List<bool> exerciseSessionAwards = List<bool>.filled(3, false);
  bool awardedMeal = false;
  bool awardedWater = false;
  bool awardedExercise = false;

  /// dateKey → snapshot ngày
  final Map<String, DayProgress> history = {};

  /// Lịch sử cân nặng (append khi cập nhật).
  final List<WeightLog> weightHistory = [];

  Future<File> _file() => AppStorage.file('progress.json');

  String todayKey([DateTime? now]) => AppClock.instance.todayKey(now);

  String _yesterdayKey() => AppClock.instance.yesterdayKey();

  Future<void> load() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        final raw =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        points = (raw['points'] as num?)?.toInt() ?? 0;
        streak = (raw['streak'] as num?)?.toInt() ?? 0;
        lastStreakDate = raw['lastStreakDate'] as String?;

        history
          ..clear()
          ..addEntries(
            ((raw['history'] as Map?) ?? {}).entries.map((e) {
              final m = Map<String, dynamic>.from(e.value as Map);
              return MapEntry(e.key.toString(), DayProgress.fromJson(m));
            }),
          );

        weightHistory
          ..clear()
          ..addAll(
            ((raw['weightHistory'] as List?) ?? const []).map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return WeightLog(
                dateKey: m['dateKey']?.toString() ?? '',
                kg: (m['kg'] as num?)?.toDouble() ?? 0,
              );
            }),
          );

        _dateKey = raw['dateKey'] as String? ?? '';
        final today = todayKey();
        if (_dateKey == today) {
          _loadTodayFromRaw(raw);
        } else {
          if (_dateKey.isNotEmpty) {
            _archiveDay(_dateKey, raw);
          }
          _resetToday(today);
        }
        await _decayBrokenStreak();
      } else {
        _resetToday(todayKey());
      }
    } catch (_) {
      _resetToday(todayKey());
    }
    await syncMealsFromSchedule();
    notifyListeners();
  }

  void _loadTodayFromRaw(Map<String, dynamic> raw) {
    waterSlots = _boolList(raw['waterSlots'], 6);
    exerciseSlots = _boolList(raw['exerciseSlots'], 3);
    exerciseSessionAwards = _boolList(raw['exerciseSessionAwards'], 3);
    awardedMeal = raw['awardedMeal'] as bool? ?? false;
    awardedWater = raw['awardedWater'] as bool? ?? false;
    awardedExercise = raw['awardedExercise'] as bool? ?? false;
  }

  List<bool> _boolList(dynamic raw, int len) {
    final list = List<bool>.filled(len, false);
    if (raw is List) {
      for (var i = 0; i < len && i < raw.length; i++) {
        list[i] = raw[i] == true;
      }
    }
    return list;
  }

  void _resetToday(String today) {
    _dateKey = today;
    waterSlots = List<bool>.filled(6, false);
    exerciseSlots = List<bool>.filled(3, false);
    exerciseSessionAwards = List<bool>.filled(3, false);
    awardedMeal = false;
    awardedWater = false;
    awardedExercise = false;
  }

  void _archiveDay(String dateKey, Map<String, dynamic> raw) {
    final meals = MealScheduleService.instance;
    // Prefer live meal state if same date was today when rolling; else from raw.
    final c = raw['completed'] as Map<String, dynamic>? ??
        {
          'breakfast': false,
          'lunch': false,
          'dinner': false,
        };
    // When rolling from ProgressService raw we don't have meals — pull from
    // meal file's last known via MealScheduleService if date matches.
    final breakfast = meals.completed[MealPeriod.breakfast] ??
        c['breakfast'] as bool? ??
        false;
    final lunch =
        meals.completed[MealPeriod.lunch] ?? c['lunch'] as bool? ?? false;
    final dinner =
        meals.completed[MealPeriod.dinner] ?? c['dinner'] as bool? ?? false;

    final water = _boolList(raw['waterSlots'], 6).where((e) => e).length;
    final exercise = _boolList(raw['exerciseSlots'], 3)
        .take(exerciseRequired)
        .where((e) => e)
        .length;
    final exerciseSessionPoints =
        _boolList(raw['exerciseSessionAwards'], 3).where((e) => e).length;

    history[dateKey] = DayProgress(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      waterDone: water,
      waterTotal: 6,
      exerciseDone: exercise,
      exerciseTotal: exerciseRequired,
      pointsEarned: (raw['dayPointsEarned'] as num?)?.toInt() ??
          ((raw['awardedMeal'] == true ? mealPoints : 0) +
              (raw['awardedWater'] == true ? waterPoints : 0) +
              (exerciseSessionPoints > 0
                  ? exerciseSessionPoints
                  : (raw['awardedExercise'] == true ? exercisePoints : 0))),
    );
  }

  Future<void> ensureToday() async {
    await _decayBrokenStreak();
    final today = todayKey();
    if (_dateKey == today) return;
    if (_dateKey.isNotEmpty) {
      await _snapshotCurrentDayToHistory(_dateKey);
    }
    _resetToday(today);
    await _persist();
    notifyListeners();
  }

  /// Đứt chuỗi (không hoạt động hôm qua & hôm nay) → streak = 0, icon về streak.png.
  Future<void> _decayBrokenStreak() async {
    final today = todayKey();
    final yesterday = _yesterdayKey();
    if (lastStreakDate == null) return;
    if (lastStreakDate == today || lastStreakDate == yesterday) return;
    if (streak == 0) return;
    streak = 0;
    await _persist();
  }

  /// Streak hiển thị: 0 nếu đã đứt chuỗi.
  int get displayStreak {
    final today = todayKey();
    final yesterday = _yesterdayKey();
    if (lastStreakDate == today || lastStreakDate == yesterday) return streak;
    return 0;
  }

  Future<void> _snapshotCurrentDayToHistory(String dateKey) async {
    final meals = MealScheduleService.instance;
    history[dateKey] = DayProgress(
      breakfast: meals.isCompleted(MealPeriod.breakfast),
      lunch: meals.isCompleted(MealPeriod.lunch),
      dinner: meals.isCompleted(MealPeriod.dinner),
      waterDone: waterDoneCount,
      waterTotal: waterSlots.length,
      exerciseDone: exerciseRequiredDone,
      exerciseTotal: exerciseRequired,
      pointsEarned: (awardedMeal ? mealPoints : 0) +
          (awardedWater ? waterPoints : 0) +
          exerciseSessionPointsEarned,
    );
  }

  int get waterDoneCount => waterSlots.where((e) => e).length;
  bool get waterComplete => waterDoneCount >= waterThreshold;

  int get exerciseRequiredDone {
    var n = 0;
    for (var i = 0; i < exerciseRequired && i < exerciseSlots.length; i++) {
      if (exerciseSlots[i]) n++;
    }
    return n;
  }

  bool get exerciseComplete => exerciseRequiredDone >= exerciseRequired;

  int get exerciseSessionPointsEarned =>
      exerciseSessionAwards.where((e) => e).length;

  bool get mealComplete {
    final m = MealScheduleService.instance;
    return m.isCompleted(MealPeriod.breakfast) &&
        m.isCompleted(MealPeriod.lunch) &&
        m.isCompleted(MealPeriod.dinner);
  }

  int get todayEarned =>
      (awardedMeal ? mealPoints : 0) +
      (awardedWater ? waterPoints : 0) +
      exerciseSessionPointsEarned;

  int get displayPoints => points; // points already include today's awards

  Future<void> syncMealsFromSchedule() async {
    await ensureToday();
    await _reconcileAwards();
    await _persist();
    notifyListeners();
  }

  Future<void> _touchStreak() async {
    final today = todayKey();
    if (lastStreakDate == today) return;
    final yesterday = _yesterdayKey();
    if (lastStreakDate == yesterday) {
      streak += 1;
    } else {
      streak = 1;
    }
    lastStreakDate = today;
  }

  Future<void> _reconcileAwards() async {
    // Meal
    if (mealComplete && !awardedMeal) {
      points += mealPoints;
      awardedMeal = true;
      await _touchStreak();
    } else if (!mealComplete && awardedMeal) {
      points = (points - mealPoints).clamp(0, 999999);
      awardedMeal = false;
    }

    // Water
    if (waterComplete && !awardedWater) {
      points += waterPoints;
      awardedWater = true;
      await _touchStreak();
    } else if (!waterComplete && awardedWater) {
      points = (points - waterPoints).clamp(0, 999999);
      awardedWater = false;
    }

    // Exercise completion remains a status flag. Points are awarded only after
    // completing a timed workout through [completeExerciseSession].
    awardedExercise = exerciseComplete;
  }

  Future<void> setWaterSlot(int index, bool value) async {
    await ensureToday();
    if (index < 0 || index >= waterSlots.length) return;
    waterSlots[index] = value;
    await _reconcileAwards();
    await _persist();
    notifyListeners();
  }

  Future<void> toggleWaterSlot(int index) async {
    await ensureToday();
    if (index < 0 || index >= waterSlots.length) return;
    await setWaterSlot(index, !waterSlots[index]);
  }

  Future<void> setExerciseSlot(int index, bool value) async {
    await ensureToday();
    if (index < 0 || index >= exerciseSlots.length) return;
    exerciseSlots[index] = value;
    await _reconcileAwards();
    await _persist();
    notifyListeners();
  }

  Future<void> toggleExerciseSlot(int index) async {
    await ensureToday();
    if (index < 0 || index >= exerciseSlots.length) return;
    await setExerciseSlot(index, !exerciseSlots[index]);
  }

  /// Ghi nhận một phiên tập đã chạy hết giáo án.
  ///
  /// Mỗi slot chỉ được +1 điểm một lần trong ngày.
  Future<ExerciseSessionResult> completeExerciseSession(int index) async {
    await ensureToday();
    if (index < 0 || index >= exerciseSlots.length) {
      return const ExerciseSessionResult(pointAwarded: false);
    }

    exerciseSlots[index] = true;
    var pointAwarded = false;
    if (!exerciseSessionAwards[index]) {
      exerciseSessionAwards[index] = true;
      points += exercisePoints;
      pointAwarded = true;
      await _touchStreak();
    }
    awardedExercise = exerciseComplete;
    await _persist();
    notifyListeners();
    return ExerciseSessionResult(pointAwarded: pointAwarded);
  }

  /// Home checklist: tăng 1 ly nước → bật slot tiếp theo.
  Future<void> addWaterGlass() async {
    await ensureToday();
    final i = waterSlots.indexWhere((e) => !e);
    if (i < 0) return;
    await setWaterSlot(i, true);
  }

  Future<void> toggleLightExerciseHome() async {
    await ensureToday();
    if (exerciseComplete) {
      for (var i = 0; i < exerciseRequired; i++) {
        exerciseSlots[i] = false;
      }
    } else {
      for (var i = 0; i < exerciseRequired; i++) {
        exerciseSlots[i] = true;
      }
    }
    await _reconcileAwards();
    await _persist();
    notifyListeners();
  }

  Future<bool> spendPoints(int amount, {bool resetDaily = false}) async {
    if (points < amount) return false;
    points -= amount;
    if (resetDaily) {
      waterSlots = List<bool>.filled(6, false);
      exerciseSlots = List<bool>.filled(3, false);
      exerciseSessionAwards = List<bool>.filled(3, false);
      awardedMeal = false;
      awardedWater = false;
      awardedExercise = false;
      final meals = MealScheduleService.instance;
      await meals.setCompleted(MealPeriod.breakfast, false);
      await meals.setCompleted(MealPeriod.lunch, false);
      await meals.setCompleted(MealPeriod.dinner, false);
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> recordWeight(double kg, {String? date}) async {
    final key = date ?? todayKey();
    // Replace same-day entry if exists
    final idx = weightHistory.indexWhere((e) => e.dateKey == key);
    if (idx >= 0) {
      weightHistory[idx] = WeightLog(dateKey: key, kg: kg);
    } else {
      weightHistory.add(WeightLog(dateKey: key, kg: kg));
    }
    weightHistory.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    await _persist();
    notifyListeners();
  }

  Future<void> seedWeightIfEmpty(double kg) async {
    if (weightHistory.isNotEmpty) return;
    await recordWeight(kg);
  }

  double? get latestWeight =>
      weightHistory.isEmpty ? null : weightHistory.last.kg;

  double? get startWeight =>
      weightHistory.isEmpty ? null : weightHistory.first.kg;

  List<DayProgressEntry> historyEntries({int? limit}) {
    final keys = history.keys.toList()..sort();
    // Include today live snapshot at end for stats
    final today = todayKey();
    final entries = <DayProgressEntry>[];
    for (final k in keys) {
      if (k == today) continue;
      entries.add(DayProgressEntry(dateKey: k, progress: history[k]!));
    }
    entries.add(
      DayProgressEntry(
        dateKey: today,
        progress: progressForDate(today),
      ),
    );
    if (limit != null && entries.length > limit) {
      return entries.sublist(entries.length - limit);
    }
    return entries;
  }

  /// Lấy tiến độ 1 ngày (hôm nay = live; không có dữ liệu → 0/3).
  DayProgress progressForDate(String dateKey) {
    final today = todayKey();
    if (dateKey == today) {
      return DayProgress(
        breakfast:
            MealScheduleService.instance.isCompleted(MealPeriod.breakfast),
        lunch: MealScheduleService.instance.isCompleted(MealPeriod.lunch),
        dinner: MealScheduleService.instance.isCompleted(MealPeriod.dinner),
        waterDone: waterDoneCount,
        waterTotal: 6,
        exerciseDone: exerciseRequiredDone,
        exerciseTotal: exerciseRequired,
        pointsEarned: todayEarned,
      );
    }
    return history[dateKey] ??
        const DayProgress(
          breakfast: false,
          lunch: false,
          dinner: false,
          waterDone: 0,
          waterTotal: 6,
          exerciseDone: 0,
          exerciseTotal: 2,
          pointsEarned: 0,
        );
  }

  /// Tỉ lệ hoàn thành từng loại thử thách trên [days] gần nhất.
  ChallengeRates computeChallengeRates({int days = 30}) {
    final entries = historyEntries(limit: days);
    if (entries.isEmpty) {
      return const ChallengeRates(meal: 0, water: 0, exercise: 0);
    }
    var mealOk = 0, waterOk = 0, exerciseOk = 0;
    for (final e in entries) {
      if (e.progress.mealComplete) mealOk++;
      if (e.progress.waterComplete) waterOk++;
      if (e.progress.exerciseComplete) exerciseOk++;
    }
    final n = entries.length.toDouble();
    return ChallengeRates(
      meal: mealOk / n,
      water: waterOk / n,
      exercise: exerciseOk / n,
    );
  }

  Future<void> _persist() async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({
        'points': points,
        'streak': streak,
        'lastStreakDate': lastStreakDate,
        'dateKey': _dateKey,
        'waterSlots': waterSlots,
        'exerciseSlots': exerciseSlots,
        'exerciseSessionAwards': exerciseSessionAwards,
        'awardedMeal': awardedMeal,
        'awardedWater': awardedWater,
        'awardedExercise': awardedExercise,
        'history': {
          for (final e in history.entries) e.key: e.value.toJson(),
        },
        'weightHistory': [
          for (final w in weightHistory)
            {'dateKey': w.dateKey, 'kg': w.kg},
        ],
      }),
    );
    // ignore: unawaited_futures
    ProgressSyncService.instance.syncToday();
  }
}

class ExerciseSessionResult {
  const ExerciseSessionResult({required this.pointAwarded});

  final bool pointAwarded;
}

class WeightLog {
  const WeightLog({required this.dateKey, required this.kg});
  final String dateKey;
  final double kg;
}

class DayProgress {
  const DayProgress({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.waterDone,
    required this.waterTotal,
    required this.exerciseDone,
    required this.exerciseTotal,
    required this.pointsEarned,
  });

  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final int waterDone;
  final int waterTotal;
  final int exerciseDone;
  final int exerciseTotal;
  final int pointsEarned;

  bool get mealComplete => breakfast && lunch && dinner;
  bool get waterComplete => waterDone >= ProgressService.waterThreshold;
  bool get exerciseComplete =>
      exerciseDone >= ProgressService.exerciseRequired;

  int get tasksDone =>
      (mealComplete ? 1 : 0) +
      (waterComplete ? 1 : 0) +
      (exerciseComplete ? 1 : 0);

  int get tasksTotal => 3;

  double get rate => tasksTotal == 0 ? 0 : tasksDone / tasksTotal;

  factory DayProgress.fromJson(Map<String, dynamic> m) => DayProgress(
        breakfast: m['breakfast'] as bool? ?? false,
        lunch: m['lunch'] as bool? ?? false,
        dinner: m['dinner'] as bool? ?? false,
        waterDone: (m['waterDone'] as num?)?.toInt() ?? 0,
        waterTotal: (m['waterTotal'] as num?)?.toInt() ?? 6,
        exerciseDone: (m['exerciseDone'] as num?)?.toInt() ?? 0,
        exerciseTotal: (m['exerciseTotal'] as num?)?.toInt() ?? 2,
        pointsEarned: (m['pointsEarned'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'waterDone': waterDone,
        'waterTotal': waterTotal,
        'exerciseDone': exerciseDone,
        'exerciseTotal': exerciseTotal,
        'pointsEarned': pointsEarned,
      };
}

class DayProgressEntry {
  const DayProgressEntry({required this.dateKey, required this.progress});
  final String dateKey;
  final DayProgress progress;
}

class ChallengeRates {
  const ChallengeRates({
    required this.meal,
    required this.water,
    required this.exercise,
  });
  final double meal;
  final double water;
  final double exercise;
}
