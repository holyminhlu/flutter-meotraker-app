import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thư mục dữ liệu local:
/// - Windows/macOS/Linux: ~/.meo_traker
/// - Android/iOS: app documents (có quyền ghi)
class AppStorage {
  AppStorage._();

  static Directory? _cached;

  static Future<Directory> dataDir() async {
    if (_cached != null) return _cached!;

    if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'meo_traker'));
      if (!await dir.exists()) await dir.create(recursive: true);
      _cached = dir;
      return dir;
    }

    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final dir = Directory(p.join(home, '.meo_traker'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _cached = dir;
    return dir;
  }

  static Future<File> file(String name) async {
    final dir = await dataDir();
    return File(p.join(dir.path, name));
  }
}
