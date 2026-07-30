import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/features/profile/widgets/budget_level_selector.dart';
import 'package:meo_traker/features/profile/widgets/local_food_picker.dart';

/// Sở thích ăn uống đang soạn — dùng chung cho onboarding và trang cài đặt.
class DietaryPreferencesDraft {
  const DietaryPreferencesDraft({
    this.likedFoods = const [],
    this.dislikedFoods = const [],
    this.allergies = const [],
    this.eligibleFoods = const [],
    this.localFoods = const [],
    this.budgetLevel = 'medium',
  });

  final List<String> likedFoods;
  final List<String> dislikedFoods;
  final List<String> allergies;
  final List<String> eligibleFoods;
  final List<String> localFoods;
  final String budgetLevel;

  DietaryPreferencesDraft copyWith({
    List<String>? likedFoods,
    List<String>? dislikedFoods,
    List<String>? allergies,
    List<String>? eligibleFoods,
    List<String>? localFoods,
    String? budgetLevel,
  }) {
    return DietaryPreferencesDraft(
      likedFoods: likedFoods ?? this.likedFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      allergies: allergies ?? this.allergies,
      eligibleFoods: eligibleFoods ?? this.eligibleFoods,
      localFoods: localFoods ?? this.localFoods,
      budgetLevel: budgetLevel ?? this.budgetLevel,
    );
  }

  /// Payload cho POST /api/onboarding/dietary.
  Map<String, dynamic> toPayload() => {
        'likedFoods': likedFoods,
        'dislikedFoods': dislikedFoods,
        'allergies': allergies,
        'eligibleFoods': eligibleFoods,
        'budgetLevel': budgetLevel,
        'localFoodNotes': joinFoodSelection(localFoods),
      };

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory DietaryPreferencesDraft.fromStatus(Map<String, dynamic> dietary) {
    return DietaryPreferencesDraft(
      likedFoods: _stringList(dietary['likedFoods']),
      dislikedFoods: _stringList(dietary['dislikedFoods']),
      allergies: _stringList(dietary['allergies']),
      eligibleFoods: _stringList(dietary['eligibleFoods']),
      localFoods:
          parseFoodSelection((dietary['localFoodNotes'] as String?) ?? '')
              .toList(),
      budgetLevel: (dietary['budgetLevel'] as String?) ?? 'medium',
    );
  }
}

/// Các trường sở thích ăn uống (không gồm mức vận động).
class DietaryPreferencesForm extends StatelessWidget {
  const DietaryPreferencesForm({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DietaryPreferencesDraft value;
  final ValueChanged<DietaryPreferencesDraft> onChanged;

  Future<void> _pick(
    BuildContext context, {
    required Future<List<String>?> Function(
      BuildContext, {
      Iterable<String> initialSelected,
    }) picker,
    required List<String> current,
    required DietaryPreferencesDraft Function(List<String>) apply,
  }) async {
    final result = await picker(context, initialSelected: current);
    if (result == null) return;
    onChanged(apply(result));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FoodSelectField(
          label: 'Món thích',
          items: value.likedFoods,
          onTap: () => _pick(
            context,
            picker: showLikedDislikedFoodPicker,
            current: value.likedFoods,
            apply: (v) => value.copyWith(likedFoods: v),
          ),
        ),
        const SizedBox(height: 16),
        FoodSelectField(
          label: 'Món ghét',
          items: value.dislikedFoods,
          onTap: () => _pick(
            context,
            picker: showLikedDislikedFoodPicker,
            current: value.dislikedFoods,
            apply: (v) => value.copyWith(dislikedFoods: v),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Image.asset(AppIcons.diUng, width: 28, height: 28),
            const SizedBox(width: 8),
            const Text(
              'Dị ứng / hạn chế',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FoodSelectField(
          label: 'Dị ứng',
          items: value.allergies,
          onTap: () => _pick(
            context,
            picker: showAllergyFoodPicker,
            current: value.allergies,
            apply: (v) => value.copyWith(allergies: v),
          ),
        ),
        const SizedBox(height: 16),
        FoodSelectField(
          label: 'Món đủ điều kiện (địa phương)',
          items: value.eligibleFoods,
          onTap: () => _pick(
            context,
            picker: showEligibleFoodPicker,
            current: value.eligibleFoods,
            apply: (v) => value.copyWith(eligibleFoods: v),
          ),
        ),
        const SizedBox(height: 16),
        BudgetLevelSelector(
          value: value.budgetLevel,
          onChanged: (v) => onChanged(value.copyWith(budgetLevel: v)),
        ),
        const SizedBox(height: 16),
        FoodSelectField(
          label: 'Nguồn thực phẩm địa phương',
          items: value.localFoods,
          onTap: () => _pick(
            context,
            picker: showLocalFoodPicker,
            current: value.localFoods,
            apply: (v) => value.copyWith(localFoods: v),
          ),
        ),
      ],
    );
  }
}

/// Ô hiển thị số món đã chọn, chạm để mở picker.
class FoodSelectField extends StatelessWidget {
  const FoodSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.onTap,
  });

  final String label;
  final List<String> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      count == 0
                          ? 'Chạm để chọn theo từng nhóm món'
                          : 'Đã chọn $count món · Chạm để sửa',
                      style: TextStyle(
                        color: count == 0
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(height: 8),
          Text(
            items.join(', '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
