import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:meo_traker/core/meal/habit_slogans.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thông báo hệ thống (ngoài app) cho nhắc động lực / bữa ăn.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const _channelId = 'meo_traker_reminders';
  static const _channelName = 'Nhắc nhở Meo Traker';
  static const _channelDesc = 'Nhắc động lực và khung giờ ăn uống';

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);
    await _ensureAndroidChannel();
    _ready = true;
  }

  Future<void> _ensureAndroidChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (!_ready) await init();

    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
      final granted = await android?.requestNotificationsPermission();
      // API < 33 không có runtime permission → null coi như đã cấp.
      if (granted == false) return false;
      return true;
    }

    if (!kIsWeb && Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  NotificationDetails _detailsWithBody(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// Hiện ngay trên thanh thông báo điện thoại.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _detailsWithBody(body),
    );
  }

  /// Huỷ lịch + đặt lại lịch hàng ngày theo cài đặt hiện tại.
  Future<void> rescheduleAll() async {
    if (!_ready) await init();
    await _plugin.cancelAll();

    final settings = ThemeSettingsService.instance;
    final mealSvc = MealScheduleService.instance;

    final wantEncouragement = settings.encouragementReminders;
    final wantMealSlots =
        settings.mealReminders && mealSvc.mealRemindersEnabled;

    if (!wantEncouragement && !wantMealSlots) return;

    final now = tz.TZDateTime.now(tz.local);
    var notifId = 2000;

    // Lời động viên: lịch hệ thống — vẫn chạy khi app tắt.
    if (wantEncouragement) {
      for (final window in mealSvc.encouragementWindows) {
        final slogan = pickRandomSlogan(prefer: window.theme);
        await _scheduleDaily(
          id: notifId++,
          hour: window.startHour,
          minute: window.startMinute,
          title: window.title,
          body: slogan.text,
          now: now,
        );
      }
    }

    // Nhắc sắp đến giờ ăn (15 phút trước).
    if (wantMealSlots) {
      for (final slot in mealSvc.reminderSlots) {
        await _scheduleDaily(
          id: notifId++,
          hour: slot.notifyAt.hour,
          minute: slot.notifyAt.minute,
          title: 'Nhắc ${slot.mealLabel}',
          body: slot.message,
          now: now,
        );
      }
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required tz.TZDateTime now,
  }) async {
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _detailsWithBody(body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Một số máy không cho exact alarm → fallback inexact.
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _detailsWithBody(body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
