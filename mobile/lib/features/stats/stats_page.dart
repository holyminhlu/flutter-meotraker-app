import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/core/widgets/page_menu_banner.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/stats/widgets/challenge_stats_charts.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  double _currentWeight = 0;
  double _targetWeight = 65;
  double _heightCm = 165;
  int _age = 22;
  String _gender = 'Nam';

  /// Tháng đang xem (ngày 1 của tháng).
  DateTime _viewMonth = DateTime(
    AppClock.instance.now().year,
    AppClock.instance.now().month,
  );

  /// Tuần trong tháng: 0 = ngày 1–7, 1 = 8–14, ...
  int _weekIndex = 0;

  ProgressService get _progress => ProgressService.instance;

  @override
  void initState() {
    super.initState();
    final now = AppClock.instance.now();
    _viewMonth = DateTime(now.year, now.month);
    _weekIndex = _weekIndexForDay(now.day);
    _progress.addListener(_onProgress);
    _load();
  }

  int _weekIndexForDay(int day) => ((day - 1) / 7).floor();

  int get _daysInMonth {
    final y = _viewMonth.year;
    final m = _viewMonth.month;
    return DateTime(y, m + 1, 0).day;
  }

  int get _weekCount => (_daysInMonth / 7).ceil();

  /// Các ngày (1-based) trong tuần đang chọn.
  List<int> get _daysInSelectedWeek {
    final start = _weekIndex * 7 + 1;
    final end = math.min(start + 6, _daysInMonth);
    return [for (var d = start; d <= end; d++) d];
  }

  List<DayProgressEntry> get _weekEntries {
    final y = _viewMonth.year;
    final m = _viewMonth.month;
    return [
      for (final day in _daysInSelectedWeek)
        DayProgressEntry(
          dateKey:
              '$y-${m.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          progress: _progress.progressForDate(
            '$y-${m.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          ),
        ),
    ];
  }

  List<DailyCompletionPoint> get _chartPoints {
    return [
      for (var i = 0; i < _weekEntries.length; i++)
        DailyCompletionPoint(
          label: '${_daysInSelectedWeek[i]}',
          dateKey: _weekEntries[i].dateKey,
          completed: _weekEntries[i].progress.tasksDone,
          total: _weekEntries[i].progress.tasksTotal,
        ),
    ];
  }

  String get _monthLabel {
    return 'Tháng ${_viewMonth.month}/${_viewMonth.year}';
  }

  String get _weekLabel {
    final days = _daysInSelectedWeek;
    if (days.isEmpty) return '—';
    return 'Tuần ${_weekIndex + 1}: ngày ${days.first}–${days.last}';
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
      _weekIndex = 0;
      if (_weekIndex >= _weekCount) _weekIndex = _weekCount - 1;
    });
  }

  Future<void> _pickMonth() async {
    final now = AppClock.instance.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _viewMonth.year,
        _viewMonth.month,
        math.min(now.day, _daysInMonth),
      ),
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month + 1, 0),
      helpText: 'Chọn tháng xem thống kê',
      fieldLabelText: 'Tháng',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _viewMonth = DateTime(picked.year, picked.month);
      _weekIndex = 0;
    });
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      final p = status.profile;
      if (p != null) {
        final w = (p['weightKg'] as num?)?.toDouble();
        if (w != null) {
          await _progress.seedWeightIfEmpty(w);
          _currentWeight = _progress.latestWeight ?? w;
        }
        _targetWeight =
            (p['targetWeightKg'] as num?)?.toDouble() ?? _targetWeight;
        _heightCm = (p['heightCm'] as num?)?.toDouble() ?? _heightCm;
        _age = (p['age'] as num?)?.toInt() ?? _age;
        final g = p['sex']?.toString() ?? p['gender']?.toString();
        if (g != null && g.isNotEmpty) {
          _gender = g.toLowerCase().startsWith('f') || g.contains('nữ')
              ? 'Nữ'
              : (g.toLowerCase().startsWith('m') || g.contains('nam')
                  ? 'Nam'
                  : 'Khác');
        }
      }
      _currentWeight = _progress.latestWeight ?? _currentWeight;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _startWeight => _progress.startWeight ?? _currentWeight;
  double get _gained => _currentWeight - _startWeight;
  double get _remain => (_targetWeight - _currentWeight).clamp(0, 999);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rates = _progress.computeChallengeRates(days: 30);
    final challengeRates = [
      ChallengeRate(
        label: 'Ăn đúng giờ',
        rate: rates.meal,
        color: const Color(0xFFE6B800),
      ),
      ChallengeRate(
        label: 'Uống đủ nước',
        rate: rates.water,
        color: const Color(0xFF1E88E5),
      ),
      ChallengeRate(
        label: 'Vận động nhẹ',
        rate: rates.exercise,
        color: const Color(0xFF2E7D32),
      ),
    ];
    final overall = (rates.meal + rates.water + rates.exercise) / 3;
    final pageItems = _chartPoints;
    final pageEntries = _weekEntries;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageMenuBanner(title: 'Thống kê'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _progress.load();
                  await _load();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  children: [
              const Text(
                'Thông số cá nhân hiện tại',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.canNang,
                      label: 'Cân nặng',
                      value: _currentWeight > 0
                          ? '${_currentWeight.toStringAsFixed(1)} kg'
                          : '—',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.mucTieu,
                      label: 'Mục tiêu',
                      value: '${_targetWeight.toStringAsFixed(0)} kg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.anMungDatMoc,
                      label: 'Đã tăng',
                      value: '+${_gained.toStringAsFixed(1)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.chieuCao,
                      label: 'Chiều cao',
                      value: '${_heightCm.toStringAsFixed(0)} cm',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.soThich,
                      label: 'Tuổi / GT',
                      value: '$_age · $_gender',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.xu,
                      label: 'Streak / Xu',
                      value: '${_progress.displayStreak} · ${_progress.points}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currentWeight > 0
                    ? 'Còn ${_remain.toStringAsFixed(1)} kg nữa tới mục tiêu'
                    : 'Hoàn thành onboarding để xem chỉ số cân nặng',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tỉ lệ hoàn thành thử thách',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TB ${(overall * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Dựa trên dữ liệu đã ghi nhận (kể cả hôm nay)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ChallengeRateChart(rates: challengeRates),
              const SizedBox(height: 22),
              const Text(
                'Lịch sử hoàn thành chỉ tiêu',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Xem theo tháng · mỗi trang = 1 tuần (7 ngày kế nhau trong tháng)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _MonthSelector(
                label: _monthLabel,
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
                onPick: _pickMonth,
              ),
              const SizedBox(height: 8),
              _HistoryPager(
                page: _weekIndex,
                pageCount: _weekCount,
                title: _weekLabel,
                fromLabel: _daysInSelectedWeek.isEmpty
                    ? '—'
                    : 'Ngày ${_daysInSelectedWeek.first}',
                toLabel: _daysInSelectedWeek.isEmpty
                    ? '—'
                    : 'Ngày ${_daysInSelectedWeek.last}',
                onPrev: _weekIndex > 0
                    ? () => setState(() => _weekIndex--)
                    : null,
                onNext: _weekIndex < _weekCount - 1
                    ? () => setState(() => _weekIndex++)
                    : null,
              ),
              const SizedBox(height: 10),
              DailyCompletionChart(points: pageItems),
              const SizedBox(height: 10),
              for (final e in pageEntries.reversed)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.dateKey,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${e.progress.tasksDone}/${e.progress.tasksTotal}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${(e.progress.rate * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: e.progress.rate >= 1
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.onPrimary,
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Chạm để chọn tháng',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _HistoryPager extends StatelessWidget {
  const _HistoryPager({
    required this.page,
    required this.pageCount,
    required this.title,
    required this.fromLabel,
    required this.toLabel,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final String title;
  final String fromLabel;
  final String toLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: onPrev == null ? AppColors.border : AppColors.onPrimary,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Tuần ${page + 1}/$pageCount · $fromLabel → $toLabel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: onNext == null ? AppColors.border : AppColors.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Image.asset(icon, width: 32, height: 32),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
