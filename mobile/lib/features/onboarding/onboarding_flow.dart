import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/utils/auth_navigation.dart';
import 'package:meo_traker/data/models/nutrition_metrics.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/features/onboarding/steps/body_stats_step.dart';
import 'package:meo_traker/features/onboarding/steps/calorie_summary_step.dart';
import 'package:meo_traker/features/onboarding/steps/dietary_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.initialStep = 'body_stats'});

  final String initialStep;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late int _index;
  NutritionMetrics? _metrics;
  bool _loading = true;

  static const _titles = [
    'Thông tin cơ thể',
    'BMI · BMR · Calo',
    'Sở thích ăn uống',
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialStep == 'dietary' ? 2 : 0;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      if (!mounted) return;
      if (status.completed) {
        await AuthService.instance.markOnboardingDone();
        if (!mounted) return;
        goAfterAuth(context);
        return;
      }
      if (status.profile != null) {
        _metrics = NutritionMetrics.fromJson({
          ...status.profile!,
          'surplusKcal': status.profile!['goalType'] == 'gain_weight'
              ? 400
              : status.profile!['goalType'] == 'lose_weight'
                  ? -400
                  : 0,
          'heightCm': status.profile!['heightCm'],
          'weightKg': status.profile!['weightKg'],
          'targetWeightKg': status.profile!['targetWeightKg'],
          'age': status.profile!['age'],
          'sex': status.profile!['sex'],
          'activityLevel': status.profile!['activityLevel'],
        });
      }
      setState(() {
        if (status.step == 'dietary') {
          _index = _metrics == null ? 0 : 1;
        } else {
          _index = 0;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onBodySaved(NutritionMetrics metrics) async {
    setState(() {
      _metrics = metrics;
      _index = 1;
    });
  }

  void _onCalorieContinue() {
    setState(() => _index = 2);
  }

  Future<void> _onDietaryDone() async {
    await AuthService.instance.refreshUser();
    if (!mounted) return;
    goAfterAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index.clamp(0, 2)]),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _index;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                BodyStatsStep(onSaved: _onBodySaved),
                CalorieSummaryStep(
                  metrics: _metrics,
                  onContinue: _onCalorieContinue,
                  onBack: () => setState(() => _index = 0),
                ),
                DietaryStep(
                  onDone: _onDietaryDone,
                  onBack: () => setState(() => _index = 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
