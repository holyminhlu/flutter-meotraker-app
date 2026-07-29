import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:path/path.dart' as p;

/// Thông số ảnh đọc cục bộ (EXIF + file) — hiển thị preview.
/// Server vẫn đọc lại EXIF từ bytes để chống giả metadata.
class ImageMetaSnapshot {
  const ImageMetaSnapshot({
    required this.path,
    required this.mimeType,
    required this.byteSize,
    this.takenAt,
    this.deviceMake,
    this.deviceModel,
    this.software,
    this.width,
    this.height,
    this.fileModifiedAt,
    this.labels = const [],
  });

  final String path;
  final String mimeType;
  final int byteSize;
  final DateTime? takenAt;
  final String? deviceMake;
  final String? deviceModel;
  final String? software;
  final int? width;
  final int? height;
  final DateTime? fileModifiedAt;
  final List<String> labels;

  Map<String, dynamic> toJson() => {
        'path': path,
        'mimeType': mimeType,
        'byteSize': byteSize,
        'takenAt': takenAt?.toIso8601String(),
        'deviceMake': deviceMake,
        'deviceModel': deviceModel,
        'software': software,
        'width': width,
        'height': height,
        'fileModifiedAt': fileModifiedAt?.toIso8601String(),
        'labels': labels,
      };
}

class ImageMetaReader {
  ImageMetaReader._();

  static String mimeFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static DateTime? _parseExifDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final norm = raw.replaceFirstMapped(
      RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
      (m) => '${m[1]}-${m[2]}-${m[3]}',
    );
    return DateTime.tryParse(norm.replaceFirst(' ', 'T'));
  }

  static String? _tagStr(Map<String, IfdTag> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.printable.trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static Future<ImageMetaSnapshot> readBytes(
    Uint8List bytes, {
    required String path,
    DateTime? fileModifiedAt,
  }) async {
    Map<String, IfdTag> tags = {};
    try {
      tags = await readExifFromBytes(bytes);
    } catch (_) {
      tags = {};
    }

    final taken = _parseExifDate(
      _tagStr(tags, [
        'Image DateTime',
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
      ]),
    );
    final make = _tagStr(tags, ['Image Make']);
    final model = _tagStr(tags, ['Image Model']);
    final software = _tagStr(tags, ['Image Software']);
    final w = int.tryParse(
      _tagStr(tags, ['EXIF ExifImageWidth', 'Image ImageWidth']) ?? '',
    );
    final h = int.tryParse(
      _tagStr(tags, ['EXIF ExifImageLength', 'Image ImageLength']) ?? '',
    );

    final labels = <String>[];
    if (taken != null) {
      labels.add(
        'Chụp: ${taken.day.toString().padLeft(2, '0')}/'
        '${taken.month.toString().padLeft(2, '0')}/${taken.year} '
        '${taken.hour.toString().padLeft(2, '0')}:'
        '${taken.minute.toString().padLeft(2, '0')}',
      );
    } else {
      labels.add('Không có ngày/giờ EXIF');
    }
    if (make != null || model != null) {
      labels.add('Thiết bị: ${[make, model].whereType<String>().join(' ')}');
    } else {
      labels.add('Không có thông tin thiết bị');
    }
    if (software != null) labels.add('Phần mềm: $software');
    labels.add('Dung lượng: ${(bytes.length / 1024).toStringAsFixed(0)} KB');

    return ImageMetaSnapshot(
      path: path,
      mimeType: mimeFromPath(path),
      byteSize: bytes.length,
      takenAt: taken,
      deviceMake: make,
      deviceModel: model,
      software: software,
      width: w,
      height: h,
      fileModifiedAt: fileModifiedAt,
      labels: labels,
    );
  }
}

class MealAnalyzeResult {
  const MealAnalyzeResult({
    required this.valid,
    required this.foodValid,
    required this.marksCompleted,
    required this.summary,
    required this.reasons,
    required this.metadataScore,
    this.timingStatus,
    this.primaryError,
    this.errorKind,
    this.aiDescription,
    this.aiConfidence,
    this.foodItems = const [],
    this.metadata = const {},
  });

  /// Ảnh hợp lệ (AI + EXIF) — có thể khác marksCompleted nếu ngoài khung giờ.
  final bool foodValid;
  /// Giữ tương thích: true khi đủ điều kiện hoàn thành bữa.
  final bool valid;
  final bool marksCompleted;
  final String summary;
  final List<String> reasons;
  final int metadataScore;
  final String? timingStatus;
  /// Một câu lỗi chính để hiện cho user (null nếu không lỗi).
  final String? primaryError;
  final String? errorKind;
  final String? aiDescription;
  final double? aiConfidence;
  final List<String> foodItems;
  final Map<String, dynamic> metadata;

  bool get hasIssue =>
      primaryError != null && primaryError!.trim().isNotEmpty;

  factory MealAnalyzeResult.fromJson(Map<String, dynamic> json) {
    final ai = Map<String, dynamic>.from((json['ai'] as Map?) ?? {});
    final foodValid = json['foodValid'] == true ||
        (json['foodValid'] == null && json['valid'] == true);
    final marksCompleted = json['marksCompleted'] == true ||
        (json['marksCompleted'] == null &&
            json['valid'] == true &&
            (json['timingStatus'] == null ||
                json['timingStatus'] == 'on_time'));
    final foodItems = ((ai['foodItems'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final reasons = ((json['reasons'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final primary = json['primaryError']?.toString().trim();
    return MealAnalyzeResult(
      foodValid: foodValid,
      valid: marksCompleted,
      marksCompleted: marksCompleted,
      summary: json['summary']?.toString() ?? '',
      reasons: reasons,
      metadataScore: (json['metadataScore'] as num?)?.toInt() ?? 0,
      timingStatus: json['timingStatus']?.toString(),
      primaryError: (primary != null && primary.isNotEmpty)
          ? primary
          : (reasons.isNotEmpty ? reasons.first : null),
      errorKind: json['errorKind']?.toString(),
      aiDescription: ai['description']?.toString(),
      aiConfidence: (ai['confidence'] as num?)?.toDouble(),
      foodItems: foodItems,
      metadata: Map<String, dynamic>.from((json['metadata'] as Map?) ?? {}),
    );
  }
}
