/// API base URL for the Express backend.
///
/// Windows / Chrome / iOS simulator: localhost
/// Android emulator: use 10.0.2.2 (pass --dart-define=API_BASE_URL=...)
/// Physical device: use your machine LAN IP
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Render free tier ngủ sau ~15 phút; cold start có thể mất gần một phút.
  static const Duration timeout = Duration(seconds: 60);
}
