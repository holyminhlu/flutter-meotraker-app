import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/data/models/nutrition_metrics.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/auth_service.dart';

class OnboardingStatus {
  const OnboardingStatus({
    required this.step,
    required this.completed,
    this.profile,
    this.dietary,
  });

  final String step;
  final bool completed;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? dietary;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      step: json['step'] as String? ?? 'body_stats',
      completed: json['completed'] as bool? ?? false,
      profile: json['profile'] as Map<String, dynamic>?,
      dietary: json['dietary'] as Map<String, dynamic>?,
    );
  }
}

class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  Map<String, String> get _headers {
    final token = AuthService.instance.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<OnboardingStatus> getStatus() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/onboarding/status'),
          headers: _headers,
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Lỗi onboarding');
    }
    return OnboardingStatus.fromJson(body);
  }

  Future<NutritionMetrics> preview(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/onboarding/preview'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Không tính được chỉ số');
    }
    return NutritionMetrics.fromJson(body);
  }

  Future<NutritionMetrics> saveBodyStats(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/onboarding/body-stats'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Lưu thất bại');
    }
    return NutritionMetrics.fromJson(body['metrics'] as Map<String, dynamic>);
  }

  Future<OnboardingStatus> saveDietary(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/onboarding/dietary'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw AuthException(body['error'] as String? ?? 'Lưu sở thích thất bại');
    }
    return OnboardingStatus.fromJson(body);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
