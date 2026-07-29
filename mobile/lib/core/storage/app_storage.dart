import 'dart:typed_data';

import 'app_storage_io.dart'
    if (dart.library.html) 'app_storage_web.dart' as impl;

/// Lưu key-value local (file trên IO, SharedPreferences trên web).
class AppStorage {
  AppStorage._();

  static Future<bool> exists(String name) => impl.exists(name);

  static Future<String?> readString(String name) => impl.readString(name);

  static Future<void> writeString(String name, String content) =>
      impl.writeString(name, content);

  static Future<Uint8List?> readBytes(String name) => impl.readBytes(name);

  static Future<void> writeBytes(String name, List<int> bytes) =>
      impl.writeBytes(name, bytes);

  static Future<void> delete(String name) => impl.delete(name);
}
