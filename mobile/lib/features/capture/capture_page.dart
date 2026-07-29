import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/meal_analysis_api.dart';
import 'package:meo_traker/data/services/meal_log_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final _picker = ImagePicker();

  Uint8List? _bytes;
  ImageMetaSnapshot? _meta;
  MealAnalyzeResult? _result;
  MealTimingContext? _timing;
  bool _busy = false;
  String? _error;
  bool _completedMeal = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _error = null;
      _result = null;
      _completedMeal = false;
      _bytes = null;
      _meta = null;
      _timing = null;
    });

    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      final meta = await ImageMetaReader.readBytes(
        bytes,
        path: x.name.isNotEmpty ? x.name : 'picked.jpg',
        fileModifiedAt: null,
      );
      if (!mounted) return;

      final now = AppClock.instance.now();
      final timing = resolveMealTiming(
        MealScheduleService.instance.periods,
        now,
      );

      setState(() {
        _bytes = bytes;
        _meta = meta;
        _timing = timing;
        _busy = true;
      });

      await _analyze(bytes: bytes, meta: meta, timing: timing, now: now);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Không lấy được ảnh: $e';
      });
    }
  }

  Future<void> _analyze({
    required Uint8List bytes,
    required ImageMetaSnapshot meta,
    required MealTimingContext timing,
    required DateTime now,
  }) async {
    try {
      final cfg = timing.config;
      final result = await MealAnalysisApi.analyze(
        bytes: bytes,
        mimeType: meta.mimeType,
        mealPeriod: cfg.period,
        windowStart: cfg.startOn(now),
        windowEnd: cfg.endOn(now),
        timingStatus: MealAnalysisApi.timingStatusApi(timing.kind),
        authToken: AuthService.instance.token,
      );

      var completed = false;
      // Chỉ hoàn thành bữa khi đúng khung giờ + ảnh hợp lệ (AI/EXIF).
      if (result.marksCompleted) {
        await MealScheduleService.instance.setCompleted(cfg.period, true);
        await ProgressService.instance.syncMealsFromSchedule();
        completed = true;
      }

      // Lưu món AI nhận diện để Chuyên gia dinh dưỡng tư vấn (kể cả sớm/trễ).
      if (result.foodValid &&
          (result.foodItems.isNotEmpty ||
              (result.aiDescription?.trim().isNotEmpty ?? false))) {
        await MealLogService.instance.saveRecognition(
          period: cfg.period,
          foodItems: result.foodItems,
          description: result.aiDescription,
        );
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _completedMeal = completed;
        _busy = false;
      });

      // Hiện đúng 1 lỗi chính (không phải đồ ăn / sai giờ / …).
      if (result.hasIssue && !completed) {
        await _showIssueDialog(result.primaryError!);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _busy = false;
        _error = msg;
      });
      await _showIssueDialog(msg);
    }
  }

  Future<void> _showIssueDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 36,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Cảnh báo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Đã hiểu'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timing = _timing;
    final title = timing == null
        ? 'Ghi nhận bữa ăn'
        : mealCaptureButtonLabel(timing.period);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'Chụp hoặc chọn ảnh — hệ thống tự gán buổi theo giờ hiện tại',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceCard(
                      icon: Icons.photo_camera_rounded,
                      label: 'Chụp ảnh',
                      onTap: _busy ? null : () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Thư viện',
                      onTap: _busy ? null : () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (timing != null) ...[
                const SizedBox(height: 16),
                _TimingChip(timing: timing),
              ],
              if (_bytes != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(_bytes!, fit: BoxFit.cover),
                  ),
                ),
              ],
              if (_meta != null && timing != null) ...[
                const SizedBox(height: 12),
                _MetaCard(
                  meta: _meta!,
                  periodTitle: mealCaptureButtonLabel(timing.period)
                      .replaceFirst('Ghi nhận ', ''),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _Banner(
                  color: AppColors.error.withValues(alpha: 0.12),
                  border: AppColors.error.withValues(alpha: 0.4),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 12),
                _ResultCard(
                  result: _result!,
                  completedMeal: _completedMeal,
                  timing: timing,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(_completedMeal),
                child: const Text('Đóng'),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Đang phân tích ảnh…',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI + thông số ảnh',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: AppColors.onPrimary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  const _TimingChip({required this.timing});

  final MealTimingContext timing;

  @override
  Widget build(BuildContext context) {
    final now = AppClock.instance.now();
    final start = timing.config.startOn(now);
    final end = timing.config.endOn(now);
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final color = switch (timing.kind) {
      MealTimingKind.onTime => AppColors.success,
      MealTimingKind.tooEarly => AppColors.warning,
      MealTimingKind.tooLate => AppColors.warning,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            '${timing.config.title} · ${timing.timingLabelVi}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Khung giờ: ${fmt(start)} – ${fmt(end)}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.meta, required this.periodTitle});

  final ImageMetaSnapshot meta;
  final String periodTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông số ảnh · $periodTitle',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('MIME: ${meta.mimeType}', style: _metaStyle),
          Text('Thiết bị: ${_deviceLabel(meta)}', style: _metaStyle),
          Text(
            'Thời gian: ${meta.takenAt?.toIso8601String() ?? 'Không có EXIF'}',
            style: _metaStyle,
          ),
        ],
      ),
    );
  }

  TextStyle get _metaStyle => TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  String _deviceLabel(ImageMetaSnapshot meta) {
    final label = [meta.deviceMake, meta.deviceModel]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    return label.isEmpty ? '—' : label;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.completedMeal,
    required this.timing,
  });

  final MealAnalyzeResult result;
  final bool completedMeal;
  final MealTimingContext? timing;

  @override
  Widget build(BuildContext context) {
    final foodOk = result.foodValid;
    final Color accent;
    final String headline;

    if (completedMeal) {
      accent = AppColors.success;
      headline = 'Hoàn thành — đã ghi nhận bữa';
    } else if (!foodOk) {
      accent = AppColors.error;
      headline = result.primaryError ?? 'Ảnh chưa hợp lệ';
    } else if (timing?.kind == MealTimingKind.tooEarly ||
        result.errorKind == 'too_early') {
      accent = AppColors.warning;
      headline = result.primaryError ??
          'Thời gian chụp sớm hơn khung giờ bữa ăn';
    } else if (timing?.kind == MealTimingKind.tooLate ||
        result.errorKind == 'too_late') {
      accent = AppColors.warning;
      headline = result.primaryError ??
          'Thời gian chụp trễ hơn khung giờ bữa ăn';
    } else {
      accent = AppColors.warning;
      headline = result.primaryError ?? 'Chưa hoàn thành bữa';
    }

    return _Banner(
      color: accent.withValues(alpha: 0.12),
      border: accent.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          if (completedMeal && result.foodItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Món: ${result.foodItems.join(', ')}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (completedMeal &&
              result.aiDescription != null &&
              result.aiDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              result.aiDescription!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.border,
    required this.child,
  });

  final Color color;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
