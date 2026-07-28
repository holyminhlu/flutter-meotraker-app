import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/profile/widgets/activity_level_selector.dart';
import 'package:meo_traker/features/profile/widgets/budget_level_selector.dart';
import 'package:meo_traker/features/profile/widgets/local_food_picker.dart';

class NutritionPrefsPage extends StatefulWidget {
  const NutritionPrefsPage({super.key});

  @override
  State<NutritionPrefsPage> createState() => _NutritionPrefsPageState();
}

class _NutritionPrefsPageState extends State<NutritionPrefsPage> {
  List<String> _likedFoods = [];
  List<String> _dislikedFoods = [];
  List<String> _allergies = [];
  List<String> _eligibleFoods = [];
  List<String> _localFoods = [];
  String _budget = 'medium';
  String _activity = 'moderate';
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      _profile = status.profile;
      final d = status.dietary;
      if (d != null) {
        _likedFoods = ((d['likedFoods'] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _dislikedFoods = ((d['dislikedFoods'] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _allergies = ((d['allergies'] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _eligibleFoods = ((d['eligibleFoods'] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final notes = (d['localFoodNotes'] as String?) ?? '';
        _localFoods = parseFoodSelection(notes).toList();
        _budget = (d['budgetLevel'] as String?) ?? 'medium';
      }
      if (_profile != null) {
        _activity = (_profile!['activityLevel'] as String?) ?? 'moderate';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openLikedFoodPicker() async {
    final result = await showLikedDislikedFoodPicker(
      context,
      initialSelected: _likedFoods,
    );
    if (result == null || !mounted) return;
    setState(() => _likedFoods = result);
  }

  Future<void> _openDislikedFoodPicker() async {
    final result = await showLikedDislikedFoodPicker(
      context,
      initialSelected: _dislikedFoods,
    );
    if (result == null || !mounted) return;
    setState(() => _dislikedFoods = result);
  }

  Future<void> _openAllergyFoodPicker() async {
    final result = await showAllergyFoodPicker(
      context,
      initialSelected: _allergies,
    );
    if (result == null || !mounted) return;
    setState(() => _allergies = result);
  }

  Future<void> _openEligibleFoodPicker() async {
    final result = await showEligibleFoodPicker(
      context,
      initialSelected: _eligibleFoods,
    );
    if (result == null || !mounted) return;
    setState(() => _eligibleFoods = result);
  }

  Future<void> _openLocalFoodPicker() async {
    final result = await showLocalFoodPicker(
      context,
      initialSelected: _localFoods,
    );
    if (result == null || !mounted) return;
    setState(() => _localFoods = result);
  }

  Widget _foodSelectField({
    required String label,
    required List<String> items,
    required VoidCallback onTap,
  }) {
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_profile != null) {
        await OnboardingService.instance.saveBodyStats({
          'heightCm': _profile!['heightCm'],
          'weightKg': _profile!['weightKg'],
          'targetWeightKg': _profile!['targetWeightKg'],
          'age': _profile!['age'],
          'sex': _profile!['sex'],
          'activityLevel': _activity,
        });
      }
      await OnboardingService.instance.saveDietary({
        'likedFoods': _likedFoods,
        'dislikedFoods': _dislikedFoods,
        'allergies': _allergies,
        'eligibleFoods': _eligibleFoods,
        'budgetLevel': _budget,
        'localFoodNotes': joinFoodSelection(_localFoods),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu sở thích & mức vận động')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dinh dưỡng & sở thích')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _foodSelectField(
                  label: 'Món thích',
                  items: _likedFoods,
                  onTap: _openLikedFoodPicker,
                ),
                const SizedBox(height: 16),
                _foodSelectField(
                  label: 'Món ghét',
                  items: _dislikedFoods,
                  onTap: _openDislikedFoodPicker,
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
                _foodSelectField(
                  label: 'Dị ứng',
                  items: _allergies,
                  onTap: _openAllergyFoodPicker,
                ),
                const SizedBox(height: 16),
                _foodSelectField(
                  label: 'Món đủ điều kiện (địa phương)',
                  items: _eligibleFoods,
                  onTap: _openEligibleFoodPicker,
                ),
                const SizedBox(height: 16),
                BudgetLevelSelector(
                  value: _budget,
                  onChanged: (v) => setState(() => _budget = v),
                ),
                const SizedBox(height: 16),
                _foodSelectField(
                  label: 'Nguồn thực phẩm địa phương',
                  items: _localFoods,
                  onTap: _openLocalFoodPicker,
                ),
                const SizedBox(height: 16),
                ActivityLevelSelector(
                  value: _activity,
                  onChanged: (v) => setState(() => _activity = v),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Lưu thay đổi'),
                ),
              ],
            ),
    );
  }
}
