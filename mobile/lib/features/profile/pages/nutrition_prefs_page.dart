import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/profile/widgets/activity_level_selector.dart';
import 'package:meo_traker/features/profile/widgets/dietary_preferences_form.dart';

class NutritionPrefsPage extends StatefulWidget {
  const NutritionPrefsPage({super.key});

  @override
  State<NutritionPrefsPage> createState() => _NutritionPrefsPageState();
}

class _NutritionPrefsPageState extends State<NutritionPrefsPage> {
  DietaryPreferencesDraft _draft = const DietaryPreferencesDraft();
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
        _draft = DietaryPreferencesDraft.fromStatus(d);
      }
      if (_profile != null) {
        _activity = (_profile!['activityLevel'] as String?) ?? 'moderate';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
      await OnboardingService.instance.saveDietary(_draft.toPayload());
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
                DietaryPreferencesForm(
                  value: _draft,
                  onChanged: (v) => setState(() => _draft = v),
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
