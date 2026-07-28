import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/auth_exception.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/auth/widgets/auth_text_field.dart';
import 'package:meo_traker/features/profile/widgets/budget_level_selector.dart';

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
  final _likedCtrl = TextEditingController();
  final _dislikedCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _eligibleCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  String _budget = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _likedCtrl.dispose();
    _dislikedCtrl.dispose();
    _allergyCtrl.dispose();
    _eligibleCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await OnboardingService.instance.saveDietary({
        'likedFoods': _likedCtrl.text,
        'dislikedFoods': _dislikedCtrl.text,
        'allergies': _allergyCtrl.text,
        'eligibleFoods': _eligibleCtrl.text,
        'budgetLevel': _budget,
        'localFoodNotes': _localCtrl.text,
      });
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
          AuthTextField(
            controller: _likedCtrl,
            label: 'Món thích',
            hint: 'Cơm gà, trứng, sữa, chuối… (cách nhau bởi dấu phẩy)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _dislikedCtrl,
            label: 'Món ghét / không muốn ăn',
            hint: 'Gan, mắm…',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _allergyCtrl,
            label: 'Dị ứng / hạn chế',
            hint: 'Hải sản, lactose, đậu phộng…',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _eligibleCtrl,
            label: 'Món đủ điều kiện (ngân sách / sẵn có)',
            hint: 'Trứng, đậu phụ, khoai lang, thịt heo…',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          BudgetLevelSelector(
            value: _budget,
            onChanged: (v) => setState(() => _budget = v),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _localCtrl,
            label: 'Ghi chú nguồn thực phẩm địa phương',
            hint: 'Chợ gần nhà, quán cơm tấm, siêu thị…',
            textInputAction: TextInputAction.done,
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
