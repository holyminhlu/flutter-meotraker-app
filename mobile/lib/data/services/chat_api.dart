import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/data/services/auth_service.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role; // user | assistant
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatApi {
  ChatApi._();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  static Future<String> fetchGreeting({String range = '7d'}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/greeting')
        .replace(queryParameters: {'range': range});
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 60),
        );
    return _extractReply(res);
  }

  static Future<String> send({
    required List<ChatMessage> messages,
    String contextRange = '7d',
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/chat'),
          headers: _headers,
          body: jsonEncode({
            'messages': messages.map((m) => m.toJson()).toList(),
            'contextRange': contextRange,
          }),
        )
        .timeout(const Duration(seconds: 90));
    return _extractReply(res);
  }

  static String _extractReply(http.Response res) {
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(body['error']?.toString() ?? 'Chat thất bại');
    }
    final reply = body['reply']?.toString();
    if (reply == null || reply.isEmpty) {
      throw Exception('AI không trả lời');
    }
    return reply;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
