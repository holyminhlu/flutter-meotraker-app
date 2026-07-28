import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';

/// Đồng bộ thử thách / tiến độ ngày lên server cho admin xem.
class ProgressSyncService {
  ProgressSyncService._();
  static final ProgressSyncService instance = ProgressSyncService._();

  Future<void> syncToday() async {
    final token = AuthService.instance.token;
    if (token == null || token.isEmpty) return;
    final user = AuthService.instance.currentUser;
    if (user == null || user.isAdmin) return;

    final p = ProgressService.instance;
    final meals = MealScheduleService.instance;
    final dateKey = AppClock.instance.todayKey();

    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/progress/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'dateKey': dateKey,
              'mealBreakfast': meals.isCompleted(MealPeriod.breakfast),
              'mealLunch': meals.isCompleted(MealPeriod.lunch),
              'mealDinner': meals.isCompleted(MealPeriod.dinner),
              'waterSlots': p.waterSlots,
              'exerciseSlots': p.exerciseSlots,
              'points': p.points,
              'streakDays': p.displayStreak,
              'awardedMeal': p.awardedMeal,
              'awardedWater': p.awardedWater,
              'awardedExercise': p.awardedExercise,
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // Đồng bộ nền — không chặn UX
    }
  }
}
