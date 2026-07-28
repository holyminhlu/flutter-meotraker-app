import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/auth/widgets/auth_text_field.dart';

class UpdateWeightPage extends StatefulWidget {
  const UpdateWeightPage({super.key, required this.currentWeight});

  final double currentWeight;

  @override
  State<UpdateWeightPage> createState() => _UpdateWeightPageState();
}

class _UpdateWeightPageState extends State<UpdateWeightPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightCtrl;
  bool _saving = false;
  bool _loading = true;

  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.currentWeight.toStringAsFixed(1),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      _profile = status.profile;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có hồ sơ cơ thể. Hoàn thành onboarding trước.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final weight = double.parse(_weightCtrl.text.trim());
      await OnboardingService.instance.saveBodyStats({
        'heightCm': _profile!['heightCm'],
        'weightKg': weight,
        'targetWeightKg': _profile!['targetWeightKg'],
        'age': _profile!['age'],
        'sex': _profile!['sex'],
        'activityLevel': _profile!['activityLevel'],
      });
      await ProgressService.instance.recordWeight(weight);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật cân nặng & tính lại BMR/Calo')),
      );
      Navigator.of(context).pop(true);
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
      appBar: AppBar(title: const Text('Cập nhật cân nặng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(AppIcons.canNang, width: 72, height: 72),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nhập cân nặng mới. Hệ thống sẽ tính lại BMI, BMR và nhu cầu calo/ngày.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: _weightCtrl,
                      label: 'Cân nặng (kg)',
                      hint: '56.5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n < 30 || n > 300) return '30–300 kg';
                        return null;
                      },
                    ),
                    const Spacer(),
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
                          : const Text('Lưu & tính lại'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
