import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Directory? _cached;

Future<Directory> _dataDir() async {
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

Future<File> _file(String name) async {
  final dir = await _dataDir();
  return File(p.join(dir.path, name));
}

Future<bool> exists(String name) async {
  final file = await _file(name);
  return file.exists();
}

Future<String?> readString(String name) async {
  final file = await _file(name);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeString(String name, String content) async {
  final file = await _file(name);
  await file.writeAsString(content);
}

Future<Uint8List?> readBytes(String name) async {
  final file = await _file(name);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> writeBytes(String name, List<int> bytes) async {
  final file = await _file(name);
  await file.writeAsBytes(bytes, flush: true);
}

Future<void> delete(String name) async {
  final file = await _file(name);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {}
  }
}
