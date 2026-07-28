import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/meal_analysis_service.dart';

export 'package:meo_traker/data/services/meal_analysis_service.dart'
    show ImageMetaReader, ImageMetaSnapshot, MealAnalyzeResult;

/// Gọi backend phân tích ảnh bữa ăn (EXIF server + Gemini AI).
class MealAnalysisApi {
  MealAnalysisApi._();

  static String timingStatusApi(MealTimingKind kind) {
    switch (kind) {
      case MealTimingKind.onTime:
        return 'on_time';
      case MealTimingKind.tooEarly:
        return 'too_early';
      case MealTimingKind.tooLate:
        return 'too_late';
    }
  }

  static Future<MealAnalyzeResult> analyze({
    required Uint8List bytes,
    required String mimeType,
    required MealPeriod mealPeriod,
    required DateTime windowStart,
    required DateTime windowEnd,
    required String timingStatus,
    required String? authToken,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Cần đăng nhập để phân tích ảnh');
    }

    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/meals/analyze'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'imageBase64': base64Encode(bytes),
            'mimeType': mimeType,
            'mealPeriod': mealPeriod.name,
            'clientNowIso':
                AppClock.instance.now().toUtc().toIso8601String(),
            'windowStartIso': windowStart.toUtc().toIso8601String(),
            'windowEndIso': windowEnd.toUtc().toIso8601String(),
            'timingStatus': timingStatus,
          }),
        )
        .timeout(const Duration(seconds: 90));

    Map<String, dynamic> map;
    try {
      map = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Phản hồi máy chủ không hợp lệ (${res.statusCode})');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        map['message']?.toString() ??
            'Phân tích thất bại (${res.statusCode})',
      );
    }
    return MealAnalyzeResult.fromJson(map);
  }
}
