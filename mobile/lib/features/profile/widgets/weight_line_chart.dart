import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class WeightPoint {
  const WeightPoint({required this.label, required this.kg});

  final String label;
  final double kg;
}

/// Simple line chart without third-party packages.
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.points,
    required this.targetKg,
    this.height = 180,
  });

  final List<WeightPoint> points;
  final double targetKg;
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
        painter: _WeightChartPainter(points: points, targetKg: targetKg),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.points, required this.targetKg});

  final List<WeightPoint> points;
  final double targetKg;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minY = math.min(
      points.map((e) => e.kg).reduce(math.min),
      targetKg,
    );
    final maxY = math.max(
      points.map((e) => e.kg).reduce(math.max),
      targetKg,
    );
    final pad = 4.0;
    final chartMin = minY - pad;
    final chartMax = maxY + pad;
    final range = (chartMax - chartMin).clamp(1.0, 9999.0);

    final left = 36.0;
    final right = size.width - 8;
    final top = 8.0;
    final bottom = size.height - 28;
    final chartW = right - left;
    final chartH = bottom - top;

    double xAt(int i) {
      if (points.length == 1) return left + chartW / 2;
      return left + chartW * (i / (points.length - 1));
    }

    double yAt(double kg) {
      return top + chartH * (1 - (kg - chartMin) / range);
    }

    // Target line
    final targetPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final ty = yAt(targetKg);
    final dash = Path()
      ..moveTo(left, ty)
      ..lineTo(right, ty);
    _drawDashed(canvas, dash, targetPaint);

    // Weight line
    final linePaint = Paint()
      ..color = AppColors.onPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xAt(i), yAt(points[i].kg));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final borderPaint = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final labelStyle = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < points.length; i++) {
      final p = Offset(xAt(i), yAt(points[i].kg));
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, borderPaint);

      labelStyle.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
      labelStyle.layout();
      labelStyle.paint(
        canvas,
        Offset(p.dx - labelStyle.width / 2, bottom + 6),
      );
    }

    // Target label
    labelStyle.text = TextSpan(
      text: 'Mục tiêu ${targetKg.toStringAsFixed(0)}kg',
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
    labelStyle.layout();
    labelStyle.paint(canvas, Offset(right - labelStyle.width, ty - 16));
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.targetKg != targetKg;
}
