import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meo_traker/core/config/api_config.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/data/models/user.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/progress_sync_service.dart';
import 'package:meo_traker/data/services/settings_sync_service.dart';

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final User user;
  final String token;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  User? currentUser;
  String? token;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<File> _sessionFile() => AppStorage.file('session.json');

  Future<void> loadSession() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return;

      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      token = raw['token'] as String?;
      final userJson = raw['user'];
      if (userJson is Map<String, dynamic>) {
        currentUser = User.fromJson(userJson);
      }
    } catch (_) {
      await logout();
      return;
    }

    if (token == null) return;

    try {
      currentUser = await fetchMe();
      await _persistSession(token!, currentUser!);
      // ignore: unawaited_futures
      SettingsSyncService.instance.sync();
      // ignore: unawaited_futures
      ProgressSyncService.instance.syncToday();
    } on AuthException {
      await logout();
    }
  }

  Future<AuthResult> register({
    String? email,
    String? phone,
    required String password,
    required String displayName,
  }) async {
    final result = await _postAuth('/api/auth/register', {
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'password': password,
      'displayName': displayName.trim(),
    });
    await _persistSession(result.token, result.user);
    // ignore: unawaited_futures
    SettingsSyncService.instance.sync();
    return result;
  }

  Future<AuthResult> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final result = await _postAuth('/api/auth/login', {
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'password': password,
    });
    await _persistSession(result.token, result.user);
    // ignore: unawaited_futures
    SettingsSyncService.instance.sync();
    // ignore: unawaited_futures
    ProgressSyncService.instance.syncToday();
    return result;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return _postJson('/api/auth/forgot-password', {'email': email.trim()});
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    return _postJson('/api/auth/reset-password', {
      'token': token.trim(),
      'password': password,
    });
  }

  Future<User> fetchMe() async {
    if (token == null) {
      throw AuthException('Chưa đăng nhập', statusCode: 401);
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);

    final body = _decodeBody(response);
    if (response.statusCode >= 400) {
      throw AuthException(
        body['error'] as String? ?? 'Không lấy được thông tin người dùng',
        statusCode: response.statusCode,
      );
    }

    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> refreshUser() async {
    if (token == null) return;
    currentUser = await fetchMe();
    await _persistSession(token!, currentUser!);
  }

  Future<void> markOnboardingDone() async {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(
      onboardingCompleted: true,
      onboardingStep: 'done',
    );
    if (token != null) {
      await _persistSession(token!, currentUser!);
    }
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    try {
      final file = await _sessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<AuthResult> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);

      final body = _decodeBody(response);
      if (response.statusCode >= 400) {
        throw AuthException(
          body['error'] as String? ?? 'Yêu cầu thất bại',
          statusCode: response.statusCode,
        );
      }

      final user = User.fromJson(body['user'] as Map<String, dynamic>);
      final authToken = body['token'] as String;
      return AuthResult(user: user, token: authToken);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Không kết nối được máy chủ. Kiểm tra backend đang chạy tại ${ApiConfig.baseUrl}',
      );
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);
      final body = _decodeBody(response);
      if (response.statusCode >= 400) {
        throw AuthException(
          body['error'] as String? ?? 'Yêu cầu thất bại',
          statusCode: response.statusCode,
        );
      }
      return body;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Không kết nối được máy chủ. Kiểm tra backend đang chạy tại ${ApiConfig.baseUrl}',
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Future<void> _persistSession(String authToken, User user) async {
    token = authToken;
    currentUser = user;
    final file = await _sessionFile();
    await file.writeAsString(
      jsonEncode({
        'token': authToken,
        'user': user.toJson(),
      }),
    );
  }
}
