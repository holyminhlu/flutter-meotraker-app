import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class ChallengeRate {
  const ChallengeRate({
    required this.label,
    required this.rate,
    required this.color,
  });

  final String label;
  /// 0.0 – 1.0
  final double rate;
  final Color color;
}

/// Biểu đồ cột ngang tỉ lệ hoàn thành thử thách.
class ChallengeRateChart extends StatelessWidget {
  const ChallengeRateChart({super.key, required this.rates});

  final List<ChallengeRate> rates;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final r in rates) ...[
            _RateRow(rate: r),
            if (r != rates.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.rate});

  final ChallengeRate rate;

  @override
  Widget build(BuildContext context) {
    final pct = (rate.rate * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                rate.label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: rate.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: rate.rate.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: AppColors.border,
            color: rate.color,
          ),
        ),
      ],
    );
  }
}

class DailyCompletionPoint {
  const DailyCompletionPoint({
    required this.label,
    required this.dateKey,
    required this.completed,
    required this.total,
  });

  final String label;
  final String dateKey;
  final int completed;
  final int total;

  double get rate => total == 0 ? 0 : completed / total;
}

/// Biểu đồ cột hoàn thành chỉ tiêu theo ngày.
class DailyCompletionChart extends StatelessWidget {
  const DailyCompletionChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  final List<DailyCompletionPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _DailyBarPainter(points: points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DailyBarPainter extends CustomPainter {
  _DailyBarPainter({required this.points});

  final List<DailyCompletionPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final left = 28.0;
    final right = size.width - 8;
    final top = 8.0;
    final bottom = size.height - 28;
    final chartW = right - left;
    final chartH = bottom - top;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final labelStyle = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y grid 0%, 50%, 100%
    for (final t in [0.0, 0.5, 1.0]) {
      final y = bottom - chartH * t;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      labelStyle.text = TextSpan(
        text: '${(t * 100).round()}%',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      labelStyle.layout();
      labelStyle.paint(canvas, Offset(2, y - labelStyle.height / 2));
    }

    final n = points.length;
    final slot = chartW / n;
    final barW = math.min(28.0, slot * 0.55);

    for (var i = 0; i < n; i++) {
      final p = points[i];
      final cx = left + slot * (i + 0.5);
      final h = chartH * p.rate.clamp(0.0, 1.0);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, bottom - h / 2),
          width: barW,
          height: math.max(h, 2),
        ),
        const Radius.circular(6),
      );
      final color = p.rate >= 1
          ? AppColors.success
          : p.rate >= 0.66
              ? AppColors.primary
              : AppColors.warning;
      canvas.drawRRect(rect, Paint()..color = color);

      labelStyle.text = TextSpan(
        text: p.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      );
      labelStyle.layout();
      labelStyle.paint(
        canvas,
        Offset(cx - labelStyle.width / 2, bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DailyBarPainter oldDelegate) =>
      oldDelegate.points != points;
}
