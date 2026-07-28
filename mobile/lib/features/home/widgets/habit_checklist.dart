import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class HabitChecklist extends StatelessWidget {
  const HabitChecklist({
    super.key,
    required this.waterGlasses,
    required this.exerciseDone,
    required this.snackSuggestion,
    required this.onAddWater,
    required this.onToggleExercise,
  });

  final int waterGlasses;
  final bool exerciseDone;
  final String snackSuggestion;
  final VoidCallback onAddWater;
  final VoidCallback onToggleExercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thói quen & thử thách',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HabitTile(
                iconPath: AppIcons.uongNuocAm,
                title: 'Nước ấm',
                subtitle: '$waterGlasses ly',
                onTap: onAddWater,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HabitTile(
                iconPath: AppIcons.vanDongNhe,
                title: 'Vận động 10p',
                subtitle: exerciseDone ? 'Đã xong' : 'Chạm để check',
                highlighted: exerciseDone,
                onTap: onToggleExercise,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Image.asset(AppIcons.goiYMonAn, width: 48, height: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý ăn nhẹ (địa phương)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snackSuggestion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppColors.primary.withValues(alpha: 0.28)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Image.asset(iconPath, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
