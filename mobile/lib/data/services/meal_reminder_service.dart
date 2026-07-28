import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/habit_slogans.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/local_notification_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';

/// 4 khung / ngày · mỗi khung 1 thông báo · slogan random từ kho.
/// Hiện dialog trong app + thông báo hệ thống trên điện thoại.
class MealReminderService {
  MealReminderService._();
  static final MealReminderService instance = MealReminderService._();

  GlobalKey<NavigatorState>? navigatorKey;
  Timer? _timer;
  Timer? _syncTimer;
  bool _showing = false;
  final _rng = Random();

  void start({required GlobalKey<NavigatorState> key}) {
    navigatorKey = key;
    _timer?.cancel();
    _syncTimer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      AppClock.instance.sync();
    });
    Future<void>.delayed(const Duration(seconds: 1), () async {
      await LocalNotificationService.instance.requestPermission();
      await LocalNotificationService.instance.rescheduleAll();
      await _tick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> refreshSchedule() async {
    await LocalNotificationService.instance.rescheduleAll();
  }

  Future<void> _tick() async {
    final settings = ThemeSettingsService.instance;
    if (!settings.encouragementReminders) return;

    final svc = MealScheduleService.instance;

    // Ensure day rollover.
    svc.isCompleted(svc.periods.first.period);

    final now = AppClock.instance.now();
    for (final window in svc.encouragementWindows) {
      if (svc.firedReminderIds.contains(window.id)) continue;
      if (!window.contains(now)) continue;

      await svc.markReminderFired(window.id);
      // ~70% theo theme khung, 30% random toàn kho cho bất ngờ.
      final prefer = _rng.nextDouble() < 0.7 ? window.theme : null;
      final slogan = pickRandomSlogan(prefer: prefer);
      await _showEncouragement(window, slogan);
      break; // one dialog at a time
    }
  }

  Future<void> _showEncouragement(
    EncouragementWindow window,
    HabitSlogan slogan,
  ) async {
    // Luôn đẩy thông báo điện thoại (kể cả khi app đang mở).
    await LocalNotificationService.instance.showNow(
      id: window.id.hashCode & 0x7fffffff,
      title: window.title,
      body: slogan.text,
    );

    if (_showing) return;
    final ctx = navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _showing = true;
    final flexible = MealScheduleService.instance.flexibleSkip;
    final isWater = slogan.theme == SloganTheme.water;

    try {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: true,
        builder: (dialogCtx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isWater
                      ? Icons.water_drop_rounded
                      : Icons.restaurant_rounded,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    window.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Text(
              slogan.text,
              style: const TextStyle(height: 1.4, fontSize: 15),
            ),
            actions: [
              if (flexible)
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Để sau'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(isWater ? 'Uống liền!' : 'Ăn liền!'),
              ),
            ],
          );
        },
      );
    } finally {
      _showing = false;
    }
  }
}
