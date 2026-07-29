import 'package:meo_traker/core/time/app_clock.dart';

/// Khung giờ hiển thị nút vận động nổi trên nút AI.
class ExerciseFabSchedule {
  ExerciseFabSchedule._();

  /// Bật = luôn active (không phụ thuộc khung giờ) — dùng khi test.
  /// Tắt lại (`false`) trước khi release.
  static const bool forceEnabledForTest = true;

  /// 06:00–09:00 và 18:00–20:00 (giờ thiết bị).
  static bool isActive([DateTime? at]) {
    if (forceEnabledForTest) return true;
    final t = at ?? AppClock.instance.now();
    final minutes = t.hour * 60 + t.minute;
    const morningStart = 6 * 60;
    const morningEnd = 9 * 60;
    const eveningStart = 18 * 60;
    const eveningEnd = 20 * 60;
    return (minutes >= morningStart && minutes < morningEnd) ||
        (minutes >= eveningStart && minutes < eveningEnd);
  }

  static String windowLabel() => forceEnabledForTest
      ? 'TEST · luôn bật'
      : '06:00–09:00 · 18:00–20:00';
}
