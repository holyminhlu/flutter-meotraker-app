import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/data/services/auth_service.dart';

class AdminApi {
  AdminApi._();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  static Future<List<Map<String, dynamic>>> listUsers() async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/api/admin/users'), headers: _headers)
        .timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Không tải được danh sách user');
    }
    return ((body['users'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getUserDetail(
    String userId, {
    String? date,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId')
        .replace(queryParameters: {
      if (date != null) 'date': date,
    });
    final res = await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Không tải được user');
    }
    return body;
  }

  static Future<Map<String, dynamic>> getAnalysis(
    String userId, {
    required String range,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/users/$userId/analysis',
    ).replace(queryParameters: {'range': range});
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 90),
        );
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Phân tích thất bại');
    }
    return body;
  }

  static Uri mealImageUri(String userId, String mealId) {
    return Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/users/$userId/meals/$mealId/image',
    );
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
