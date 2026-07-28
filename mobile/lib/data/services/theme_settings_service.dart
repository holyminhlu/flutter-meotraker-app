import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/data/services/local_notification_service.dart';
import 'package:meo_traker/data/services/settings_sync_service.dart';

/// Cài đặt ứng dụng (giao diện, nhắc nhở, …) — lưu local JSON.
class ThemeSettingsService extends ChangeNotifier {
  ThemeSettingsService._();
  static final ThemeSettingsService instance = ThemeSettingsService._();

  bool isDark = false;
  bool mealReminders = true;
  bool encouragementReminders = true;
  bool compactLists = false;

  Future<File> _file() => AppStorage.file('settings.json');

  Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      isDark = raw['isDark'] as bool? ?? false;
      mealReminders = raw['mealReminders'] as bool? ?? true;
      encouragementReminders = raw['encouragementReminders'] as bool? ?? true;
      compactLists = raw['compactLists'] as bool? ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({
        'isDark': isDark,
        'mealReminders': mealReminders,
        'encouragementReminders': encouragementReminders,
        'compactLists': compactLists,
      }),
    );
    // ignore: unawaited_futures
    SettingsSyncService.instance.sync();
  }

  Future<void> setDark(bool value) async {
    if (isDark == value) return;
    isDark = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setMealReminders(bool value) async {
    mealReminders = value;
    notifyListeners();
    await _persist();
    await LocalNotificationService.instance.rescheduleAll();
  }

  Future<void> setEncouragementReminders(bool value) async {
    encouragementReminders = value;
    notifyListeners();
    await _persist();
    await LocalNotificationService.instance.rescheduleAll();
  }

  Future<void> setCompactLists(bool value) async {
    compactLists = value;
    notifyListeners();
    await _persist();
  }
}
