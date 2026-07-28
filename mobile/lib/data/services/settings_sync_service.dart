import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';

/// Đồng bộ cài đặt app (theme, nhắc nhở, khung giờ) lên server để admin xem.
class SettingsSyncService {
  SettingsSyncService._();
  static final SettingsSyncService instance = SettingsSyncService._();

  Future<void> sync() async {
    final token = AuthService.instance.token;
    if (token == null || token.isEmpty) return;
    final user = AuthService.instance.currentUser;
    if (user == null || user.isAdmin) return;

    final theme = ThemeSettingsService.instance;
    final schedule = MealScheduleService.instance;
    final row = schedule.row;

    final settings = <String, dynamic>{
      'theme': {
        'isDark': theme.isDark,
        'mealReminders': theme.mealReminders,
        'encouragementReminders': theme.encouragementReminders,
        'compactLists': theme.compactLists,
      },
      'reminders': {
        'mealRemindersEnabled': schedule.mealRemindersEnabled,
        'warmWater': schedule.warmWater,
        'lightExercise': schedule.lightExercise,
        'flexibleSkip': schedule.flexibleSkip,
        'breakfastHour': schedule.breakfast.hour,
        'breakfastMinute': schedule.breakfast.minute,
      },
      'mealWindows': {
        'breakfast': _window(MealPeriod.breakfast, row),
        'lunch': _window(MealPeriod.lunch, row),
        'dinner': _window(MealPeriod.dinner, row),
      },
    };

    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/settings/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'settings': settings}),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // Đồng bộ nền — không chặn UX
    }
  }

  Map<String, String> _window(MealPeriod period, MealScheduleRow row) {
    final periods = mealPeriodsFor(row);
    final cfg = periods.firstWhere((p) => p.period == period);
    String pad(int n) => n.toString().padLeft(2, '0');
    return {
      'start': '${pad(cfg.startHour)}:${pad(cfg.startMinute)}',
      'end': '${pad(cfg.endHour)}:${pad(cfg.endMinute)}',
    };
  }
}
