import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'meo_kv_';

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<bool> exists(String name) async {
  final prefs = await _prefs();
  return prefs.containsKey('$_prefix$name');
}

Future<String?> readString(String name) async {
  final prefs = await _prefs();
  return prefs.getString('$_prefix$name');
}

Future<void> writeString(String name, String content) async {
  final prefs = await _prefs();
  await prefs.setString('$_prefix$name', content);
}

Future<Uint8List?> readBytes(String name) async {
  final raw = await readString(name);
  if (raw == null || raw.isEmpty) return null;
  return Uint8List.fromList(base64Decode(raw));
}

Future<void> writeBytes(String name, List<int> bytes) async {
  await writeString(name, base64Encode(bytes));
}

Future<void> delete(String name) async {
  final prefs = await _prefs();
  await prefs.remove('$_prefix$name');
}
