import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/profile/widgets/dietary_preferences_form.dart';

class DietaryStep extends StatefulWidget {
  const DietaryStep({
    super.key,
    required this.onDone,
    required this.onBack,
  });

  final Future<void> Function() onDone;
  final VoidCallback onBack;

  @override
  State<DietaryStep> createState() => _DietaryStepState();
}

class _DietaryStepState extends State<DietaryStep> {
  DietaryPreferencesDraft _draft = const DietaryPreferencesDraft();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await OnboardingService.instance.saveDietary(_draft.toPayload());
      await widget.onDone();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kê khai sở thích ăn uống để gợi ý món phù hợp ngân sách và nguồn thực phẩm địa phương.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          DietaryPreferencesForm(
            value: _draft,
            onChanged: (v) => setState(() => _draft = v),
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
                : const Text('Hoàn tất onboarding'),
          ),
          TextButton(onPressed: widget.onBack, child: const Text('Quay lại')),
        ],
      ),
    );
  }
}
