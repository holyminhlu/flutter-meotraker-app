import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Thời tiết hiện tại tại Vĩnh Long, Việt Nam (Open-Meteo, không cần API key).
class WeatherService extends ChangeNotifier {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const latitude = 10.2537;
  static const longitude = 105.9722;
  static const locationLabel = 'Vĩnh Long';

  double? temperatureC;
  int? weatherCode;
  bool isDay = true;
  bool loading = false;
  String? error;

  IconData get weatherIcon {
    final code = weatherCode ?? 0;
    if (!isDay) {
      if (code == 0) return Icons.nightlight_round;
      if (code <= 3) return Icons.nights_stay_rounded;
    }
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_rounded;
    if (code <= 48) return Icons.blur_on_rounded;
    if (code <= 57) return Icons.grain_rounded;
    if (code <= 67) return Icons.umbrella_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.beach_access_rounded;
    if (code <= 86) return Icons.cloudy_snowing;
    if (code <= 99) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
  }

  String get weatherLabel {
    final code = weatherCode ?? 0;
    if (code == 0) return isDay ? 'Trời trong' : 'Đêm trong';
    if (code <= 3) return 'Ít mây';
    if (code <= 48) return 'Sương mù';
    if (code <= 57) return 'Mưa phùn';
    if (code <= 67) return 'Mưa';
    if (code <= 77) return 'Tuyết';
    if (code <= 82) return 'Mưa rào';
    if (code <= 86) return 'Mưa đá';
    if (code <= 99) return 'Dông';
    return 'Thời tiết';
  }

  String get tempLabel {
    if (temperatureC == null) return '—°C';
    return '${temperatureC!.round()}°C';
  }

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,weather_code,is_day'
        '&timezone=${Uri.encodeComponent('Asia/Ho_Chi_Minh')}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        error = 'Không lấy được thời tiết';
        return;
      }
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      final current = raw['current'] as Map<String, dynamic>? ?? {};
      temperatureC = (current['temperature_2m'] as num?)?.toDouble();
      weatherCode = (current['weather_code'] as num?)?.toInt();
      isDay = current['is_day'] == 1 || current['is_day'] == true;
      error = null;
    } catch (_) {
      error = 'Lỗi mạng thời tiết';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
