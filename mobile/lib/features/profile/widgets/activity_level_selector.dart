import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class ActivityOption {
  const ActivityOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.level,
  });

  final String id;
  final String title;
  final String subtitle;
  final String hint;
  final int level; // 1–5, dùng cho thanh cường độ
}

const kActivityOptions = [
  ActivityOption(
    id: 'sedentary',
    title: 'Ít vận động',
    subtitle: 'Ngồi nhiều trong ngày',
    hint: 'Làm việc văn phòng, ít đi bộ — calo tiêu hao thấp',
    level: 1,
  ),
  ActivityOption(
    id: 'light',
    title: 'Nhẹ',
    subtitle: '1–3 ngày/tuần',
    hint: 'Đi bộ, việc nhà nhẹ hoặc tập rất ít trong tuần',
    level: 2,
  ),
  ActivityOption(
    id: 'moderate',
    title: 'Vừa phải',
    subtitle: '3–5 ngày/tuần',
    hint: 'Tập đều hoặc đi lại nhiều — mức phổ biến nhất',
    level: 3,
  ),
  ActivityOption(
    id: 'active',
    title: 'Nhiều',
    subtitle: '6–7 ngày/tuần',
    hint: 'Tập gần như mỗi ngày hoặc lao động chân tay vừa',
    level: 4,
  ),
  ActivityOption(
    id: 'very_active',
    title: 'Rất nhiều',
    subtitle: 'Tập nặng / lao động nặng',
    hint: 'Vận động cường độ cao hằng ngày — nhu cầu calo cao',
    level: 5,
  ),
];

/// Bộ chọn mức độ vận động (5 mức).
class ActivityLevelSelector extends StatelessWidget {
  const ActivityLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.showHeader = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final selected = kActivityOptions.firstWhere(
      (e) => e.id == value,
      orElse: () => kActivityOptions[2],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Image.asset(AppIcons.vanDongNhe, width: 28, height: 28),
              const SizedBox(width: 8),
              Text(
                'Mức độ vận động',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ảnh hưởng đến nhu cầu calo và gợi ý chế độ ăn',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < kActivityOptions.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ActivityCard(
            option: kActivityOptions[i],
            selected: value == kActivityOptions[i].id,
            onTap: () => onChanged(kActivityOptions[i].id),
          ),
        ],
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(selected.id),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              selected.hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ActivityOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.22)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _IntensityBars(level: option.level, active: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntensityBars extends StatelessWidget {
  const _IntensityBars({required this.level, required this.active});

  final int level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 1; i <= 5; i++) ...[
            if (i > 1) const SizedBox(width: 2),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 8.0 + i * 3.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= level
                      ? (active
                          ? AppColors.onPrimary.withValues(alpha: 0.85)
                          : AppColors.primary)
                      : AppColors.border,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
