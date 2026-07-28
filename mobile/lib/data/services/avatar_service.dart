import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:path/path.dart' as p;

/// Ảnh đại diện lưu local theo user id.
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final ImagePicker _picker = ImagePicker();

  String? get _userId => AuthService.instance.currentUser?.id;

  Future<File?> avatarFile() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    final file = await AppStorage.file('avatar_$uid.jpg');
    if (await file.exists()) return file;
    return null;
  }

  Future<String?> avatarPath() async {
    final f = await avatarFile();
    return f?.path;
  }

  Future<File?> pickAndSave({ImageSource source = ImageSource.gallery}) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;

    final x = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (x == null) return null;

    final bytes = await x.readAsBytes();
    final dest = await AppStorage.file('avatar_$uid.jpg');
    await dest.writeAsBytes(bytes, flush: true);

    // Xóa bản cũ khác đuôi nếu có.
    final dir = await AppStorage.dataDir();
    for (final name in ['avatar_$uid.png', 'avatar_$uid.webp']) {
      final old = File(p.join(dir.path, name));
      if (await old.exists()) {
        try {
          await old.delete();
        } catch (_) {}
      }
    }
    return dest;
  }

  Future<void> clear() async {
    final f = await avatarFile();
    if (f != null && await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
