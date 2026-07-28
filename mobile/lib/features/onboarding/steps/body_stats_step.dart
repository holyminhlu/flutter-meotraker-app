import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/models/nutrition_metrics.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/auth/widgets/auth_text_field.dart';
import 'package:meo_traker/features/profile/widgets/activity_level_selector.dart';

class BodyStatsStep extends StatefulWidget {
  const BodyStatsStep({super.key, required this.onSaved});

  final Future<void> Function(NutritionMetrics metrics) onSaved;

  @override
  State<BodyStatsStep> createState() => _BodyStatsStepState();
}

class _BodyStatsStepState extends State<BodyStatsStep> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _sex = 'male';
  String _activity = 'moderate';
  bool _submitting = false;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'heightCm': double.parse(_heightCtrl.text.trim()),
        'weightKg': double.parse(_weightCtrl.text.trim()),
        'targetWeightKg': double.parse(_targetCtrl.text.trim()),
        'age': int.parse(_ageCtrl.text.trim()),
        'sex': _sex,
        'activityLevel': _activity,
      };
      final metrics = await OnboardingService.instance.saveBodyStats(payload);
      await widget.onSaved(metrics);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được thông tin')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhập chỉ số ban đầu để Meo Traker tính nhu cầu calo tăng cân.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _heightCtrl,
              label: 'Chiều cao (cm)',
              hint: '170',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 100 || n > 250) return '100–250 cm';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _weightCtrl,
              label: 'Cân nặng hiện tại (kg)',
              hint: '55',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 30 || n > 300) return '30–300 kg';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _targetCtrl,
              label: 'Cân nặng mục tiêu (kg)',
              hint: '65',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 30 || n > 300) return '30–300 kg';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _ageCtrl,
              label: 'Tuổi',
              hint: '22',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 10 || n > 100) return '10–100 tuổi';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Giới tính (dùng tính BMR)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Nam'),
                  selected: _sex == 'male',
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _sex = 'male'),
                ),
                ChoiceChip(
                  label: const Text('Nữ'),
                  selected: _sex == 'female',
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _sex = 'female'),
                ),
                ChoiceChip(
                  label: const Text('Khác'),
                  selected: _sex == 'other',
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _sex = 'other'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ActivityLevelSelector(
              value: _activity,
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Tính BMI / BMR / Calo'),
            ),
          ],
        ),
      ),
    );
  }
}
