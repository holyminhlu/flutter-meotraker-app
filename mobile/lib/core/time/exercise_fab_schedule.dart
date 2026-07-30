import 'package:meo_traker/core/time/app_clock.dart';

/// Khung giờ hiển thị nút vận động nổi trên nút AI.
class ExerciseFabSchedule {
  ExerciseFabSchedule._();

  /// Bật = luôn active (không phụ thuộc khung giờ) — dùng khi test.
  /// Tắt lại (`false`) trước khi release.
  static const bool forceEnabledForTest = false;

  static const _windows = <({int start, int end, String label})>[
    (start: 6 * 60, end: 8 * 60, label: '06:00–08:00'),
    (start: 16 * 60, end: 17 * 60 + 30, label: '16:00–17:30'),
    (start: 21 * 60, end: 22 * 60, label: '21:00–22:00'),
  ];

  static int _minutes(DateTime at) => at.hour * 60 + at.minute;

  /// Chỉ mở đúng buổi tương ứng; mốc kết thúc không còn được tính.
  static bool isSlotActive(int slotIndex, [DateTime? at]) {
    if (forceEnabledForTest) return true;
    if (slotIndex < 0 || slotIndex >= _windows.length) return false;
    final minutes = _minutes(at ?? AppClock.instance.now());
    final window = _windows[slotIndex];
    return minutes >= window.start && minutes < window.end;
  }

  static bool isSlotPast(int slotIndex, [DateTime? at]) {
    if (forceEnabledForTest) return false;
    if (slotIndex < 0 || slotIndex >= _windows.length) return true;
    return _minutes(at ?? AppClock.instance.now()) >= _windows[slotIndex].end;
  }

  static String slotWindowLabel(int slotIndex) =>
      slotIndex >= 0 && slotIndex < _windows.length
      ? _windows[slotIndex].label
      : '';

  /// Nút vận động chỉ hiện trong một trong ba khung.
  static bool isActive([DateTime? at]) {
    if (forceEnabledForTest) return true;
    final t = at ?? AppClock.instance.now();
    return List.generate(
      _windows.length,
      (i) => i,
    ).any((i) => isSlotActive(i, t));
  }

  static String windowLabel() => forceEnabledForTest
      ? 'TEST · luôn bật'
      : _windows.map((w) => w.label).join(' · ');
}
