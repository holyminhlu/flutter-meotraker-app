import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/core/widgets/page_menu_banner.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/challenges/widgets/coin_icon.dart';
import 'package:meo_traker/features/challenges/widgets/reward_chest_panel.dart';
import 'package:meo_traker/features/challenges/widgets/streak_bar.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _WaterSlotDef {
  const _WaterSlotDef({
    required this.title,
    required this.amount,
    required this.note,
    required this.endHour,
    required this.endMinute,
  });

  final String title;
  final String amount;
  final String note;
  /// Hết hạn tick sau mốc này (đã qua → bỏ lỡ nếu chưa xong).
  final int endHour;
  final int endMinute;

  bool isPast(DateTime now) {
    final end = DateTime(now.year, now.month, now.day, endHour, endMinute);
    return now.isAfter(end);
  }
}

const _waterSlotDefs = [
  _WaterSlotDef(
    title: 'Uống nước ấm',
    amount: '200–300 ml',
    note: 'Khởi động buổi sáng',
    endHour: 9,
    endMinute: 0,
  ),
  _WaterSlotDef(
    title: '9:00 – 10:00',
    amount: '200–300 ml',
    note: 'Giữ tỉnh táo khi bắt đầu làm việc',
    endHour: 10,
    endMinute: 0,
  ),
  _WaterSlotDef(
    title: 'Trước ăn trưa 30 phút',
    amount: '200 ml',
    note: 'Hỗ trợ hệ tiêu hóa hoạt động tốt hơn',
    endHour: 12,
    endMinute: 30,
  ),
  _WaterSlotDef(
    title: '14:00 – 15:00',
    amount: '200–300 ml',
    note: 'Bù nước buổi chiều, giảm căng thẳng',
    endHour: 15,
    endMinute: 0,
  ),
  _WaterSlotDef(
    title: 'Trước khi tắm',
    amount: '100–200 ml',
    note: 'Giúp ổn định huyết áp',
    endHour: 18,
    endMinute: 0,
  ),
  _WaterSlotDef(
    title: 'Trước ngủ 1 tiếng',
    amount: '100–200 ml',
    note: 'Phòng chống nghẽn mạch máu về đêm',
    endHour: 22,
    endMinute: 0,
  ),
];

class _ExerciseSlotDef {
  const _ExerciseSlotDef({
    required this.title,
    required this.duration,
    required this.note,
    required this.endHour,
    required this.endMinute,
    this.optional = false,
  });

  final String title;
  final String duration;
  final String note;
  final int endHour;
  final int endMinute;
  final bool optional;

  bool isPast(DateTime now) {
    final end = DateTime(now.year, now.month, now.day, endHour, endMinute);
    return now.isAfter(end);
  }
}

const _exerciseSlotDefs = [
  _ExerciseSlotDef(
    title: 'Buổi sáng',
    duration: '10 phút',
    note: 'Ngay sau khi thức dậy',
    endHour: 9,
    endMinute: 0,
  ),
  _ExerciseSlotDef(
    title: 'Buổi xế chiều',
    duration: '15 phút',
    note: '16:00 – 17:30',
    endHour: 17,
    endMinute: 30,
  ),
  _ExerciseSlotDef(
    title: 'Buổi tối',
    duration: '10 phút',
    note: 'Trước khi ngủ 30 phút',
    endHour: 22,
    endMinute: 0,
    optional: true,
  ),
];

/// Số khung vận động bắt buộc (sáng + xế chiều). Buổi tối là tùy chọn.
const int _exerciseRequiredSlots = ProgressService.exerciseRequired;

class _ChallengesPageState extends State<ChallengesPage>
    with TickerProviderStateMixin {
  static const int mealPoints = ProgressService.mealPoints;
  static const int waterPoints = ProgressService.waterPoints;
  static const int exercisePoints = ProgressService.exercisePoints;
  static const int vipThreshold = 15;
  static const int choiceThreshold = 30;

  /// Đủ 5/6 khung uống là nhận điểm.
  static const int _waterPointsThreshold = ProgressService.waterThreshold;

  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _mealKey = GlobalKey();
  final GlobalKey _waterKey = GlobalKey();
  final GlobalKey _exerciseKey = GlobalKey();

  bool _loading = true;
  bool _animating = false;
  double _currentWeight = 57.2;

  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  double _animatedPoints = 0;

  ProgressService get _progress => ProgressService.instance;
  MealScheduleService get _meals => MealScheduleService.instance;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onServicesChanged);
    _meals.addListener(_onServicesChanged);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnim = AlwaysStoppedAnimation(_animatedPoints);
    _progressCtrl.addListener(() {
      setState(() => _animatedPoints = _progressAnim.value);
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_animating) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _progress.removeListener(_onServicesChanged);
    _meals.removeListener(_onServicesChanged);
    _progressCtrl.dispose();
    super.dispose();
  }

  void _onServicesChanged() {
    if (!mounted || _animating) return;
    setState(() {
      _animatedPoints = _progress.points.toDouble();
      _currentWeight = _progress.latestWeight ?? _currentWeight;
    });
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      final p = status.profile;
      if (p != null) {
        final w = (p['weightKg'] as num?)?.toDouble() ?? _currentWeight;
        await _progress.seedWeightIfEmpty(w);
        _currentWeight = _progress.latestWeight ?? w;
      } else {
        _currentWeight = _progress.latestWeight ?? _currentWeight;
      }
    } catch (_) {
      _currentWeight = _progress.latestWeight ?? _currentWeight;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _animatedPoints = _progress.points.toDouble();
        });
      }
    }
  }

  bool get _mealBreakfast => _meals.isCompleted(MealPeriod.breakfast);
  bool get _mealLunch => _meals.isCompleted(MealPeriod.lunch);
  bool get _mealDinner => _meals.isCompleted(MealPeriod.dinner);

  bool _mealMissed(MealPeriod period) {
    if (_meals.isCompleted(period)) return false;
    final now = AppClock.instance.now();
    final cfg = _meals.periods.firstWhere((p) => p.period == period);
    return now.isAfter(cfg.endOn(now));
  }

  int get _mealDoneCount =>
      (_mealBreakfast ? 1 : 0) +
      (_mealLunch ? 1 : 0) +
      (_mealDinner ? 1 : 0);

  int get _waterDoneCount => _progress.waterDoneCount;

  int get _exerciseRequiredDone => _progress.exerciseRequiredDone;

  /// Cân nặng × 35ml = tổng nhu cầu nước (ml).
  int get _totalWaterNeedMl => (_currentWeight * 35).round();

  /// ~25% từ thức ăn (trong khoảng 20–30%).
  int get _waterFromFoodMl => (_totalWaterNeedMl * 0.25).round();

  /// Lượng nước lọc cần uống (sau khi trừ ~25% từ thức ăn).
  int get _drinkTargetMl => _totalWaterNeedMl - _waterFromFoodMl;

  int get _todayEarned => _progress.todayEarned;

  int get _displayPoints => _progress.points;

  Future<void> _animateProgressTo(int target) async {
    final begin = _animatedPoints;
    _progressAnim = Tween<double>(begin: begin, end: target.toDouble()).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl
      ..reset()
      ..forward();
    await Future<void>.delayed(const Duration(milliseconds: 520));
  }

  Future<void> _toggleWaterSlot(int index) async {
    if (_animating || index < 0 || index >= _progress.waterSlots.length) {
      return;
    }

    final def = _waterSlotDefs[index];
    final now = AppClock.instance.now();
    if (def.isPast(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _progress.waterSlots[index]
                ? 'Khung "${def.title}" đã khóa — không thể bỏ tick.'
                : 'Đã bỏ lỡ "${def.title}" — không thể tick sau giờ.',
          ),
        ),
      );
      return;
    }

    final current = _progress.waterSlots[index];
    final wasComplete =
        _progress.awardedWater || _progress.waterComplete;
    final label = def.title;

    if (current) {
      await _progress.toggleWaterSlot(index);
      if (!mounted) return;
      await _animateProgressTo(_displayPoints);
      return;
    }

    setState(() => _animating = true);

    await _progress.toggleWaterSlot(index);
    if (!mounted) return;

    final nowComplete =
        _progress.awardedWater || _progress.waterComplete;

    if (!wasComplete && nowComplete) {
      final from = globalCenterOf(_waterKey) ??
          Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.55,
          );
      final ahead = _displayPoints.toDouble() / choiceThreshold;
      final to = progressTipOf(_progressKey, ahead) ??
          Offset(MediaQuery.sizeOf(context).width * 0.5, 160);

      await playSemicirclePointFlight(
        context: context,
        vsync: this,
        from: from,
        to: to,
        points: waterPoints,
      );
      if (!mounted) return;
      await _animateProgressTo(_displayPoints);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label · Tiến độ $_waterDoneCount/${_progress.waterSlots.length} — đủ $_waterPointsThreshold lần uống là +$waterPoints điểm',
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _animating = false;
      _animatedPoints = _displayPoints.toDouble();
    });
  }

  Future<void> _toggleExerciseSlot(int index) async {
    if (_animating || index < 0 || index >= _progress.exerciseSlots.length) {
      return;
    }

    final def = _exerciseSlotDefs[index];
    final now = AppClock.instance.now();
    if (def.isPast(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _progress.exerciseSlots[index]
                ? 'Khung "${def.title}" đã khóa — không thể bỏ tick.'
                : 'Đã bỏ lỡ "${def.title}" — không thể tick sau giờ.',
          ),
        ),
      );
      return;
    }

    final current = _progress.exerciseSlots[index];
    final wasComplete =
        _progress.awardedExercise || _progress.exerciseComplete;

    if (current) {
      await _progress.toggleExerciseSlot(index);
      if (!mounted) return;
      await _animateProgressTo(_displayPoints);
      return;
    }

    setState(() => _animating = true);

    await _progress.toggleExerciseSlot(index);
    if (!mounted) return;

    final nowComplete =
        _progress.awardedExercise || _progress.exerciseComplete;

    if (!wasComplete && nowComplete) {
      final from = globalCenterOf(_exerciseKey) ??
          Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.55,
          );
      final ahead = _displayPoints.toDouble() / choiceThreshold;
      final to = progressTipOf(_progressKey, ahead) ??
          Offset(MediaQuery.sizeOf(context).width * 0.5, 160);

      await playSemicirclePointFlight(
        context: context,
        vsync: this,
        from: from,
        to: to,
        points: exercisePoints,
      );
      if (!mounted) return;
      await _animateProgressTo(_displayPoints);
    } else if (mounted) {
      final msg = def.optional
          ? '${def.title} (tùy chọn) · Đã ghi nhận'
          : '${def.title} · Tiến độ $_exerciseRequiredDone/$_exerciseRequiredSlots — đủ sáng + xế chiều mới +$exercisePoints điểm';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }

    if (!mounted) return;
    setState(() {
      _animating = false;
      _animatedPoints = _displayPoints.toDouble();
    });
  }

  Future<void> _claimReward(int need, String name) async {
    if (_displayPoints < need) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cần $need điểm (hiện có $_displayPoints).')),
      );
      return;
    }
    final ok = await _progress.spendPoints(need, resetDaily: true);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cần $need điểm (hiện có $_displayPoints).')),
      );
      return;
    }
    setState(() => _animatedPoints = _progress.points.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎉 Đã đổi "$name"!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final points = _displayPoints;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageMenuBanner(
              title: 'Thử thách',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_animatedPoints.round()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  children: [
              RewardChestPanel(
                points: _animatedPoints.round(),
                vipThreshold: vipThreshold,
                superVipThreshold: choiceThreshold,
                progressKey: _progressKey,
                animatedProgress: _animatedPoints,
              ),
              const SizedBox(height: 12),
              StreakBar(streak: _progress.displayStreak),
              const SizedBox(height: 18),
              const Text(
                'Thành tích hôm nay',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Đã kiếm $_todayEarned / ${mealPoints + waterPoints + exercisePoints} điểm hôm nay',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              KeyedSubtree(
                key: _mealKey,
                child: _MealOnTimeGroup(
                  breakfast: _mealBreakfast,
                  lunch: _mealLunch,
                  dinner: _mealDinner,
                  breakfastMissed: _mealMissed(MealPeriod.breakfast),
                  lunchMissed: _mealMissed(MealPeriod.lunch),
                  dinnerMissed: _mealMissed(MealPeriod.dinner),
                  doneCount: _mealDoneCount,
                  rewardPoints: mealPoints,
                  awarded: _progress.awardedMeal || _progress.mealComplete,
                ),
              ),
              KeyedSubtree(
                key: _waterKey,
                child: _WaterIntakeGroup(
                  slots: List<bool>.from(_progress.waterSlots),
                  defs: _waterSlotDefs,
                  doneCount: _waterDoneCount,
                  pointsThreshold: _waterPointsThreshold,
                  rewardPoints: waterPoints,
                  awarded: _progress.awardedWater || _progress.waterComplete,
                  weightKg: _currentWeight,
                  totalNeedMl: _totalWaterNeedMl,
                  fromFoodMl: _waterFromFoodMl,
                  drinkTargetMl: _drinkTargetMl,
                  onToggle: _toggleWaterSlot,
                ),
              ),
              KeyedSubtree(
                key: _exerciseKey,
                child: _ExerciseGroup(
                  slots: List<bool>.from(_progress.exerciseSlots),
                  defs: _exerciseSlotDefs,
                  requiredDone: _exerciseRequiredDone,
                  requiredTotal: _exerciseRequiredSlots,
                  rewardPoints: exercisePoints,
                  awarded:
                      _progress.awardedExercise || _progress.exerciseComplete,
                  onToggle: _toggleExerciseSlot,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mốc đổi quà',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _RewardMilestone(
                icon: AppIcons.diemThuong,
                title: 'Quà VIP',
                need: vipThreshold,
                current: points,
                onClaim: () => _claimReward(vipThreshold, 'Quà VIP'),
                isCoinIcon: true,
              ),
              _RewardMilestone(
                icon: AppIcons.anMungDatMoc,
                title: 'Quà tự chọn (Super VIP)',
                need: choiceThreshold,
                current: points,
                onClaim: () => _claimReward(choiceThreshold, 'Quà tự chọn'),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterIntakeGroup extends StatelessWidget {
  const _WaterIntakeGroup({
    required this.slots,
    required this.defs,
    required this.doneCount,
    required this.pointsThreshold,
    required this.rewardPoints,
    required this.awarded,
    required this.weightKg,
    required this.totalNeedMl,
    required this.fromFoodMl,
    required this.drinkTargetMl,
    required this.onToggle,
  });

  final List<bool> slots;
  final List<_WaterSlotDef> defs;
  final int doneCount;
  final int pointsThreshold;
  final int rewardPoints;
  final bool awarded;
  final double weightKg;
  final int totalNeedMl;
  final int fromFoodMl;
  final int drinkTargetMl;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    final total = slots.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: awarded
            ? AppColors.primary.withValues(alpha: 0.22)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AppIcons.uongNuocAm, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uống đủ nước',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      awarded
                          ? 'Đã nhận +$rewardPoints điểm'
                          : 'Đủ $pointsThreshold/$total lần uống để +$rewardPoints điểm',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$doneCount/$total',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: awarded ? AppColors.success : AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Cân nặng ${weightKg.toStringAsFixed(1)} kg × 35 ml = $totalNeedMl ml/ngày.\n'
              '≈$fromFoodMl ml từ thức ăn (20–30%) → cần uống khoảng $drinkTargetMl ml nước lọc '
              '(thường 1,5–2 lít).',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (doneCount / pointsThreshold).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: awarded ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < defs.length; i++)
            _WaterSlotChip(
              title: defs[i].title,
              amount: defs[i].amount,
              note: defs[i].note,
              done: slots[i],
              missed: !slots[i] && defs[i].isPast(AppClock.instance.now()),
              locked: defs[i].isPast(AppClock.instance.now()),
              onTap: () => onToggle(i),
            ),
        ],
      ),
    );
  }
}

class _WaterSlotChip extends StatelessWidget {
  const _WaterSlotChip({
    required this.title,
    required this.amount,
    required this.note,
    required this.done,
    required this.missed,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final String amount;
  final String note;
  final bool done;
  final bool missed;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    final Color iconColor;
    final String? status;

    if (done) {
      bg = AppColors.primary.withValues(alpha: 0.28);
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      status = locked ? 'Đã khóa' : null;
    } else if (missed) {
      bg = AppColors.error.withValues(alpha: 0.08);
      icon = Icons.cancel_rounded;
      iconColor = AppColors.error;
      status = 'Đã bỏ lỡ';
    } else {
      bg = AppColors.background;
      icon = Icons.radio_button_unchecked;
      iconColor = AppColors.textSecondary;
      status = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: missed
                  ? Border.all(color: AppColors.error.withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title · $amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: missed
                              ? AppColors.error
                              : AppColors.textPrimary,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: missed
                              ? AppColors.error.withValues(alpha: 0.75)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null)
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: missed ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseGroup extends StatelessWidget {
  const _ExerciseGroup({
    required this.slots,
    required this.defs,
    required this.requiredDone,
    required this.requiredTotal,
    required this.rewardPoints,
    required this.awarded,
    required this.onToggle,
  });

  final List<bool> slots;
  final List<_ExerciseSlotDef> defs;
  final int requiredDone;
  final int requiredTotal;
  final int rewardPoints;
  final bool awarded;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: awarded
            ? AppColors.primary.withValues(alpha: 0.22)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AppIcons.vanDongNhe, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoàn thành vận động',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      awarded
                          ? 'Đã nhận +$rewardPoints điểm'
                          : 'Đủ sáng + xế chiều để +$rewardPoints điểm (tối tùy chọn)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$requiredDone/$requiredTotal',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: awarded ? AppColors.success : AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: requiredTotal == 0 ? 0 : requiredDone / requiredTotal,
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: awarded ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < defs.length; i++)
            _ExerciseSlotChip(
              title: defs[i].title,
              duration: defs[i].duration,
              note: defs[i].note,
              optional: defs[i].optional,
              done: slots[i],
              missed: !slots[i] && defs[i].isPast(AppClock.instance.now()),
              locked: defs[i].isPast(AppClock.instance.now()),
              onTap: () => onToggle(i),
            ),
        ],
      ),
    );
  }
}

class _ExerciseSlotChip extends StatelessWidget {
  const _ExerciseSlotChip({
    required this.title,
    required this.duration,
    required this.note,
    required this.optional,
    required this.done,
    required this.missed,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final String duration;
  final String note;
  final bool optional;
  final bool done;
  final bool missed;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        optional ? '$title (tùy chọn) · $duration' : '$title · $duration';

    final Color bg;
    final IconData icon;
    final Color iconColor;
    final String? status;

    if (done) {
      bg = AppColors.primary.withValues(alpha: 0.28);
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      status = locked ? 'Đã khóa' : null;
    } else if (missed) {
      bg = AppColors.error.withValues(alpha: 0.08);
      icon = Icons.cancel_rounded;
      iconColor = AppColors.error;
      status = optional ? 'Bỏ lỡ (tùy chọn)' : 'Đã bỏ lỡ';
    } else {
      bg = AppColors.background;
      icon = Icons.radio_button_unchecked;
      iconColor = AppColors.textSecondary;
      status = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: missed
                  ? Border.all(color: AppColors.error.withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: missed
                              ? AppColors.error
                              : AppColors.textPrimary,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: missed
                              ? AppColors.error.withValues(alpha: 0.75)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null)
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: missed ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealOnTimeGroup extends StatelessWidget {
  const _MealOnTimeGroup({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.breakfastMissed,
    required this.lunchMissed,
    required this.dinnerMissed,
    required this.doneCount,
    required this.rewardPoints,
    required this.awarded,
  });

  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final bool breakfastMissed;
  final bool lunchMissed;
  final bool dinnerMissed;
  final int doneCount;
  final int rewardPoints;
  final bool awarded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: awarded
            ? AppColors.primary.withValues(alpha: 0.22)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AppIcons.khungGio, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ăn đúng giờ',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      awarded
                          ? 'Đã nhận +$rewardPoints điểm'
                          : 'Chụp/up ảnh trong khung giờ · 3/3 bữa để +$rewardPoints điểm',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$doneCount/3',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: awarded ? AppColors.success : AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: doneCount / 3,
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: awarded ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _MealSlotChip(
            label: 'Buổi sáng',
            done: breakfast,
            missed: breakfastMissed,
          ),
          _MealSlotChip(
            label: 'Buổi trưa',
            done: lunch,
            missed: lunchMissed,
          ),
          _MealSlotChip(
            label: 'Buổi tối',
            done: dinner,
            missed: dinnerMissed,
          ),
        ],
      ),
    );
  }
}

class _MealSlotChip extends StatelessWidget {
  const _MealSlotChip({
    required this.label,
    required this.done,
    this.missed = false,
  });

  final String label;
  final bool done;
  final bool missed;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    final Color iconColor;
    final String status;
    final Color statusColor;

    if (done) {
      bg = AppColors.primary.withValues(alpha: 0.28);
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      status = 'Đã xác minh';
      statusColor = AppColors.success;
    } else if (missed) {
      bg = AppColors.error.withValues(alpha: 0.08);
      icon = Icons.cancel_rounded;
      iconColor = AppColors.error;
      status = 'Đã bỏ lỡ';
      statusColor = AppColors.error;
    } else {
      bg = AppColors.background;
      icon = Icons.radio_button_unchecked;
      iconColor = AppColors.textSecondary;
      status = 'Chờ ảnh';
      statusColor = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: missed
              ? Border.all(color: AppColors.error.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: missed ? AppColors.error : AppColors.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardMilestone extends StatelessWidget {
  const _RewardMilestone({
    required this.icon,
    required this.title,
    required this.need,
    required this.current,
    required this.onClaim,
    this.isCoinIcon = false,
  });

  final String icon;
  final String title;
  final int need;
  final int current;
  final VoidCallback onClaim;
  final bool isCoinIcon;

  @override
  Widget build(BuildContext context) {
    final progress = (current / need).clamp(0.0, 1.0);
    final ready = current >= need;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCoinIcon)
                const CoinIcon(size: 36)
              else
                Image.asset(icon, width: 36, height: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$current / $need điểm',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: ready ? onClaim : null,
                child: Text(ready ? 'Đổi quà' : 'Chưa đủ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
