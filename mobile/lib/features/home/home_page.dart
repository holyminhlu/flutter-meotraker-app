import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/meal_log_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/home/widgets/home_header.dart';
import 'package:meo_traker/features/home/widgets/meal_period_banner.dart';
import 'package:meo_traker/features/home/widgets/meal_timeline.dart';
import 'package:meo_traker/features/home/widgets/motivation_badge_cards.dart';
import 'package:meo_traker/features/home/widgets/nutrition_expert_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onCaptureTap,
    required this.onSelectTab,
  });

  final VoidCallback onCaptureTap;
  /// 0 Home · 1 Challenges · 3 Stats · 4 Profile
  final ValueChanged<int> onSelectTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _currentWeight = 57.2;
  double _startWeight = 55;
  int _weeksTracking = 1;

  late MealPeriodConfig _activePeriod;
  Timer? _ticker;
  late List<MealSlot> _meals;

  MealScheduleService get _schedule => MealScheduleService.instance;
  ProgressService get _progress => ProgressService.instance;
  MealLogService get _logs => MealLogService.instance;

  @override
  void initState() {
    super.initState();
    _schedule.addListener(_onDataChanged);
    _progress.addListener(_onDataChanged);
    _logs.addListener(_onDataChanged);
    _activePeriod = activeMealPeriodFor(_schedule.periods, AppClock.instance.now());
    _rebuildMeals();
    _loadProfile();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _syncFromSchedule();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      final p = status.profile;
      if (p != null && mounted) {
        final w = (p['weightKg'] as num?)?.toDouble() ?? _currentWeight;
        await _progress.seedWeightIfEmpty(w);
        setState(() {
          _currentWeight = _progress.latestWeight ?? w;
          _startWeight = _progress.startWeight ?? w;
          if (_progress.weightHistory.length >= 2) {
            final first = DateTime.tryParse(_progress.weightHistory.first.dateKey);
            final last = DateTime.tryParse(_progress.weightHistory.last.dateKey);
            if (first != null && last != null) {
              _weeksTracking =
                  (last.difference(first).inDays / 7).ceil().clamp(1, 999);
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _schedule.removeListener(_onDataChanged);
    _progress.removeListener(_onDataChanged);
    _logs.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _syncFromSchedule();
  }

  void _syncFromSchedule() {
    final next = activeMealPeriodFor(_schedule.periods, AppClock.instance.now());
    setState(() {
      _activePeriod = next;
      _rebuildMeals();
    });
  }

  void _rebuildMeals() {
    final now = AppClock.instance.now();
    _meals = _schedule.periods.map((cfg) {
      final status = _statusFor(cfg, now);
      final inWindow = isWithinMealWindow(cfg, now);
      final past = now.isAfter(cfg.endOn(now));
      final countdown = status == MealStatus.upcoming && !inWindow
          ? cfg.startOn(now).difference(now).inMinutes.clamp(0, 9999)
          : null;
      final log = _logs.logFor(cfg.period);
      return MealSlot(
        id: cfg.period.name,
        period: cfg.period,
        title: cfg.title,
        timeLabel: '${_fmt(cfg.startOn(now))} – ${_fmt(cfg.endOn(now))}',
        status: status,
        countdownMinutes: countdown,
        inWindow: inWindow && status == MealStatus.upcoming,
        foodItems: log?.foodItems ?? const [],
        past: past,
      );
    }).toList();
  }

  MealStatus _statusFor(MealPeriodConfig cfg, DateTime now) {
    if (_schedule.isCompleted(cfg.period)) return MealStatus.eaten;
    final end = cfg.endOn(now);
    if (now.isAfter(end)) return MealStatus.missed;
    return MealStatus.upcoming;
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _greeting {
    switch (_activePeriod.period) {
      case MealPeriod.breakfast:
        return 'Chào buổi sáng, đừng quên 1 ly nước ấm nhé!';
      case MealPeriod.lunch:
        return 'Buổi trưa rồi — ghi nhận bữa ăn đúng giờ nhé!';
      case MealPeriod.dinner:
        return 'Buổi chiều — hoàn thành bữa bằng ảnh trong khung giờ!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = (user?.displayName.isNotEmpty == true)
        ? user!.displayName.split(' ').last
        : 'bạn';
    final now = AppClock.instance.now();
    final openPeriod = openMealPeriodFor(_schedule.periods, now);
    final canCapture = canCaptureMealNow(
      periods: _schedule.periods,
      now: now,
      isCompleted: _schedule.isCompleted,
    );
    final captureLabel = canCapture
        ? mealCaptureButtonLabel(openPeriod!.period)
        : captureBlockedLabel(
            periods: _schedule.periods,
            now: now,
          );
    final motivation = motivationText(
      currentWeight: _currentWeight,
      startWeight: _startWeight,
      weeksTracking: _weeksTracking,
      streak: _progress.displayStreak,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _schedule.load();
            await _progress.load();
            await _logs.load();
            await _loadProfile();
            _syncFromSchedule();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              HomeHeader(
                displayName: name,
                greeting: _greeting,
                streakDays: _progress.displayStreak,
              ),
              const SizedBox(height: 14),
              MotivationBanner(text: motivation),
              const SizedBox(height: 20),
              MealPeriodBanner(
                config: _activePeriod,
                completed: _schedule.isCompleted(_activePeriod.period),
                inWindow: isWithinMealWindow(_activePeriod, now),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: canCapture ? widget.onCaptureTap : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canCapture
                          ? Icons.photo_camera_rounded
                          : Icons.schedule_rounded,
                      size: 28,
                      color: canCapture
                          ? AppColors.onPrimary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        captureLabel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              MealTimeline(meals: _meals),
              const SizedBox(height: 28),
              NutritionExpertPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
