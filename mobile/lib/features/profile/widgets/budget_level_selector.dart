import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class BudgetOption {
  const BudgetOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.coinCount,
  });

  final String id;
  final String title;
  final String subtitle;
  final String hint;
  final int coinCount;
}

const kBudgetOptions = [
  BudgetOption(
    id: 'low',
    title: 'Thấp',
    subtitle: '~30–50k/ngày',
    hint: 'Món bình dân, chợ quê, tận dụng nguyên liệu sẵn có',
    coinCount: 1,
  ),
  BudgetOption(
    id: 'medium',
    title: 'Trung bình',
    subtitle: '~50–80k/ngày',
    hint: 'Cân bằng dinh dưỡng, đa dạng món mà vẫn tiết kiệm',
    coinCount: 2,
  ),
  BudgetOption(
    id: 'high',
    title: 'Cao',
    subtitle: '80k+/ngày',
    hint: 'Linh hoạt chọn món, ưu tiên chất lượng và đa dạng',
    coinCount: 3,
  ),
];

/// Bộ chọn mức ngân sách ăn uống (3 mức).
class BudgetLevelSelector extends StatelessWidget {
  const BudgetLevelSelector({
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
    final selected = kBudgetOptions.firstWhere(
      (e) => e.id == value,
      orElse: () => kBudgetOptions[1],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Image.asset(AppIcons.nganSach, width: 28, height: 28),
              const SizedBox(width: 8),
              Text(
                'Ngân sách ăn uống',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn mức chi tiêu để gợi ý món phù hợp hơn',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            for (var i = 0; i < kBudgetOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _BudgetCard(
                  option: kBudgetOptions[i],
                  selected: value == kBudgetOptions[i].id,
                  onTap: () => onChanged(kBudgetOptions[i].id),
                ),
              ),
            ],
          ],
        ),
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

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final BudgetOption option;
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
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < option.coinCount; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Image.asset(AppIcons.xu, width: 16, height: 16),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.onPrimary.withValues(alpha: 0.15) : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 12,
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
