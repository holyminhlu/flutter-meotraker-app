/// Đồng hồ ứng dụng theo giờ của thiết bị (Android/iOS local time).
class AppClock {
  AppClock._();
  static final AppClock instance = AppClock._();

  /// Luôn lấy từ đồng hồ thiết bị.
  String source = 'device';
  bool syncedFromApi = false;

  /// Thời điểm hiện tại theo giờ máy (timezone người dùng đã cài).
  DateTime now() => DateTime.now();

  String todayKey([DateTime? at]) {
    final d = at ?? now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String yesterdayKey() {
    final d = now().subtract(const Duration(days: 1));
    return todayKey(d);
  }

  /// Giữ API cũ — không còn gọi timeapi; luôn dùng giờ thiết bị.
  Future<void> sync() async {
    source = 'device';
    syncedFromApi = false;
  }
}
