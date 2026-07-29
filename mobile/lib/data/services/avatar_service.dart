import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/data/services/auth_service.dart';

/// Ảnh đại diện lưu local theo user id.
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final ImagePicker _picker = ImagePicker();

  String? get _userId => AuthService.instance.currentUser?.id;

  String? _keyFor(String uid) => 'avatar_$uid.jpg';

  Future<Uint8List?> avatarBytes() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    return AppStorage.readBytes(_keyFor(uid)!);
  }

  /// Key ổn định để UI biết avatar đã có (không dùng path file trên web).
  Future<String?> avatarKey() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    final key = _keyFor(uid)!;
    if (await AppStorage.exists(key)) return key;
    return null;
  }

  Future<Uint8List?> pickAndSave({
    ImageSource source = ImageSource.gallery,
  }) async {
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
    final key = _keyFor(uid)!;
    await AppStorage.writeBytes(key, bytes);

    // Xóa bản cũ khác đuôi nếu có.
    for (final name in ['avatar_$uid.png', 'avatar_$uid.webp']) {
      await AppStorage.delete(name);
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> clear() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await AppStorage.delete(_keyFor(uid)!);
    await AppStorage.delete('avatar_$uid.png');
    await AppStorage.delete('avatar_$uid.webp');
  }
}
