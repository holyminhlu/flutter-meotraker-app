import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/models/nutrition_metrics.dart';

class CalorieSummaryStep extends StatelessWidget {
  const CalorieSummaryStep({
    super.key,
    required this.metrics,
    required this.onContinue,
    required this.onBack,
  });

  final NutritionMetrics? metrics;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  String get _goalLabel {
    switch (metrics?.goalType) {
      case 'gain_weight':
        return 'Tăng cân (+${metrics!.surplusKcal.toInt()} kcal/ngày)';
      case 'lose_weight':
        return 'Giảm cân (${metrics!.surplusKcal.toInt()} kcal/ngày)';
      default:
        return 'Duy trì cân nặng';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (metrics == null) {
      return Center(
        child: TextButton(onPressed: onBack, child: const Text('Quay lại nhập chỉ số')),
      );
    }

    final m = metrics!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chỉ số được tính tự động từ thông tin của bạn (Mifflin-St Jeor).',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          _MetricCard(
            title: 'BMI',
            value: m.bmi.toStringAsFixed(1),
            subtitle: m.bmiLabel,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'BMR',
            value: '${m.bmr.toInt()} kcal',
            subtitle: 'Calo nghỉ ngơi / ngày',
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'TDEE',
            value: '${m.tdee.toInt()} kcal',
            subtitle: 'Duy trì cân nặng hiện tại',
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'Nhu cầu calo mục tiêu',
            value: '${m.calorieTarget.toInt()} kcal/ngày',
            subtitle: _goalLabel,
            highlight: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Hiện tại ${m.weightKg} kg → mục tiêu ${m.targetWeightKg} kg',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onContinue,
            child: const Text('Tiếp tục sở thích ăn uống'),
          ),
          TextButton(onPressed: onBack, child: const Text('Chỉnh lại chỉ số')),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.28)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
