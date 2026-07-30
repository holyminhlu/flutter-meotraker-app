import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/admin_api.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/features/admin/admin_day_detail_page.dart';
import 'package:meo_traker/features/admin/admin_meal_photo_detail_page.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _meals = [];
  Map<String, dynamic>? _progress;
  DateTime _date = DateTime.now();
  String _range = 'today';
  String? _analysis;
  bool _analyzing = false;
  late final TabController _tabs;

  String get _dateKey =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminApi.getUserDetail(widget.userId, date: _dateKey);
      if (!mounted) return;
      setState(() {
        _detail = Map<String, dynamic>.from(data['user'] as Map? ?? {});
        _meals = ((data['meals'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _progress = data['progress'] == null
            ? null
            : Map<String, dynamic>.from(data['progress'] as Map);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _load();
  }

  void _shiftDay(int delta) {
    final next = _date.add(Duration(days: delta));
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final earliest = todayOnly.subtract(const Duration(days: 365));
    if (next.isAfter(todayOnly) || next.isBefore(earliest)) return;
    setState(() => _date = next);
    _load();
  }

  Future<void> _openDayDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminDayDetailPage(
          userId: widget.userId,
          displayName: widget.displayName,
          initialDate: _date,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _runAnalysis(String range) async {
    setState(() {
      _range = range;
      _analyzing = true;
      _analysis = null;
    });
    try {
      final data = await AdminApi.getAnalysis(widget.userId, range: range);
      if (!mounted) return;
      setState(() {
        _analysis = data['analysis']?.toString() ?? 'Không có phân tích';
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analysis = e.toString().replaceFirst('Exception: ', '');
        _analyzing = false;
      });
    }
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      default:
        return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_detail?['displayName'] as String?)?.trim().isNotEmpty == true
        ? _detail!['displayName'] as String
        : widget.displayName;
    final contact = (_detail?['email'] as String?) ??
        (_detail?['phone'] as String?) ??
        '—';
    final profile = _detail?['profile'] as Map?;
    final dietary = _detail?['dietary'] as Map?;
    final appSettings = _detail?['appSettings'] as Map?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 168,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Chọn ngày',
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_rounded),
                        ),
                        IconButton(
                          tooltip: 'Làm mới',
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _ProfileHero(
                          name: name,
                          contact: contact,
                          authProvider: _authProviderLabel(
                            _detail?['authProvider'],
                          ),
                          createdAt: _fmtDate(_detail?['createdAt']),
                          onboarded: profile?['onboardingCompleted'] == true,
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabs,
                          labelColor: AppColors.onPrimary,
                          unselectedLabelColor:
                              AppColors.onPrimary.withValues(alpha: 0.55),
                          indicatorColor: AppColors.onPrimary,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Tổng quan'),
                            Tab(text: 'Hồ sơ'),
                            Tab(text: 'Cài đặt'),
                            Tab(text: 'Ngày'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(
                        profile: profile,
                        progress: _progress,
                        mealCount: _meals.length,
                        photoCount:
                            _meals.where((m) => m['hasImage'] == true).length,
                        dateKey: _dateKey,
                        range: _range,
                        analyzing: _analyzing,
                        analysis: _analysis,
                        onOpenDay: () {
                          _tabs.animateTo(3);
                        },
                        onAnalyze: _runAnalysis,
                        sexLabel: _sexLabel,
                        activityLabel: _activityLabel,
                        goalLabel: _goalLabel,
                      ),
                      _ProfileTab(
                        detail: _detail,
                        profile: profile,
                        dietary: dietary,
                        sexLabel: _sexLabel,
                        activityLabel: _activityLabel,
                        goalLabel: _goalLabel,
                        budgetLabel: _budgetLabel,
                        authProviderLabel: _authProviderLabel,
                        fmtDate: _fmtDate,
                        join: _join,
                      ),
                      _SettingsTab(
                        appSettings: appSettings,
                        updatedAt: _fmtDate(_detail?['appSettingsUpdatedAt']),
                        onOff: _onOff,
                        padTime: _padTime,
                        mealWindow: _mealWindow,
                      ),
                      _DayTab(
                        dateKey: _dateKey,
                        progress: _progress,
                        meals: _meals,
                        userId: widget.userId,
                        periodLabel: _periodLabel,
                        onPrev: () => _shiftDay(-1),
                        onNext: () => _shiftDay(1),
                        onPickDate: _pickDate,
                        onOpenFull: _openDayDetail,
                        onOpenMeal: (meal) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminMealPhotoDetailPage(
                                userId: widget.userId,
                                displayName: name,
                                meal: meal,
                                periodLabel: _periodLabel(
                                  meal['period']?.toString() ?? '',
                                ),
                              ),
                            ),
                          );
                        },
                        countTrue: _countTrue,
                      ),
                    ],
                  ),
                ),
    );
  }

  String _join(dynamic list) {
    if (list is! List || list.isEmpty) return '—';
    return list.map((e) => e.toString()).join(', ');
  }

  String _onOff(dynamic v) {
    if (v == null) return '—';
    return v == true ? 'Bật' : 'Tắt';
  }

  String _padTime(dynamic hour, dynamic minute) {
    if (hour == null || minute == null) return '—';
    final h = (hour as num).toInt().toString().padLeft(2, '0');
    final m = (minute as num).toInt().toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _mealWindow(dynamic raw) {
    if (raw is! Map) return '—';
    final start = raw['start']?.toString();
    final end = raw['end']?.toString();
    if (start == null || end == null) return '—';
    return '$start – $end';
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.length >= 19) return s.substring(0, 19).replaceFirst('T', ' ');
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String _sexLabel(dynamic v) {
    switch (v?.toString()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return v?.toString() ?? '—';
    }
  }

  String _activityLabel(dynamic v) {
    switch (v?.toString()) {
      case 'sedentary':
        return 'Ít vận động';
      case 'light':
        return 'Nhẹ';
      case 'moderate':
        return 'Trung bình';
      case 'active':
        return 'Năng động';
      case 'very_active':
        return 'Rất năng động';
      default:
        return v?.toString() ?? '—';
    }
  }

  String _goalLabel(dynamic v) {
    switch (v?.toString()) {
      case 'gain_weight':
        return 'Tăng cân';
      case 'lose_weight':
        return 'Giảm cân';
      case 'maintain':
        return 'Giữ cân';
      default:
        return v?.toString() ?? '—';
    }
  }

  String _budgetLabel(dynamic v) {
    switch (v?.toString()) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return v?.toString() ?? '—';
    }
  }

  String _authProviderLabel(dynamic v) {
    switch (v?.toString()) {
      case 'email':
        return 'Email';
      case 'phone':
        return 'SĐT';
      case 'google':
        return 'Google';
      default:
        return v?.toString() ?? '—';
    }
  }

  int _countTrue(dynamic list) {
    if (list is! List) return 0;
    return list.where((e) => e == true).length;
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.contact,
    required this.authProvider,
    required this.createdAt,
    required this.onboarded,
  });

  final String name;
  final String contact;
  final String authProvider;
  final String createdAt;
  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
            const Color(0xFFFFE566),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 56,
        20,
        16,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeroChip(icon: Icons.lock_outline, label: authProvider),
                    _HeroChip(
                      icon: onboarded
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                      label: onboarded ? 'Đã onboard' : 'Chưa onboard',
                    ),
                    _HeroChip(icon: Icons.event, label: createdAt),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.onPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.primary,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.profile,
    required this.progress,
    required this.mealCount,
    required this.photoCount,
    required this.dateKey,
    required this.range,
    required this.analyzing,
    required this.analysis,
    required this.onOpenDay,
    required this.onAnalyze,
    required this.sexLabel,
    required this.activityLabel,
    required this.goalLabel,
  });

  final Map? profile;
  final Map<String, dynamic>? progress;
  final int mealCount;
  final int photoCount;
  final String dateKey;
  final String range;
  final bool analyzing;
  final String? analysis;
  final VoidCallback onOpenDay;
  final Future<void> Function(String range) onAnalyze;
  final String Function(dynamic) sexLabel;
  final String Function(dynamic) activityLabel;
  final String Function(dynamic) goalLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (profile != null) ...[
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Cân nặng',
                  value: '${profile!['weightKg']} kg',
                  hint: 'Mục tiêu ${profile!['targetWeightKg']} kg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'BMI',
                  value: '${profile!['bmi']}',
                  hint: sexLabel(profile!['sex']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Calo/ngày',
                  value: '${profile!['calorieTarget']}',
                  hint: goalLabel(profile!['goalType']),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Vận động',
                  value: activityLabel(profile!['activityLevel']),
                  hint: 'Tuổi ${profile!['age']}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else
          const _EmptyHint('Chưa có hồ sơ cơ thể'),
        _Panel(
          title: 'Hôm nay · $dateKey',
          trailing: TextButton(
            onPressed: onOpenDay,
            child: const Text('Xem ngày'),
          ),
          child: progress == null
              ? Text(
                  'Chưa đồng bộ thử thách',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Bữa',
                            value:
                                '${[
                                      progress!['mealBreakfast'],
                                      progress!['mealLunch'],
                                      progress!['mealDinner'],
                                    ].where((e) => e == true).length}/3',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Nước',
                            value:
                                '${(progress!['waterSlots'] as List?)?.where((e) => e == true).length ?? 0}/6',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'VĐ slot',
                            value:
                                '${(progress!['exerciseSlots'] as List?)?.where((e) => e == true).length ?? 0}/3',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Phiên tập',
                            value:
                                '${(progress!['exerciseSessionAwards'] as List?)?.where((e) => e == true).length ?? 0}/3',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Điểm',
                            value: '${progress!['points'] ?? 0}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$mealCount bữa · $photoCount ảnh',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Streak ${progress!['streakDays'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'AI phân tích',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final e in [
                    ('today', 'Hôm nay'),
                    ('7d', '7 ngày'),
                    ('30d', '30 ngày'),
                  ])
                    ChoiceChip(
                      label: Text(e.$2),
                      selected: range == e.$1,
                      selectedColor: AppColors.primary,
                      onSelected: analyzing ? null : (_) => onAnalyze(e.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (analyzing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (analysis != null)
                Text(
                  analysis!,
                  style: TextStyle(
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                Text(
                  'Chọn khoảng thời gian để AI phân tích',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.detail,
    required this.profile,
    required this.dietary,
    required this.sexLabel,
    required this.activityLabel,
    required this.goalLabel,
    required this.budgetLabel,
    required this.authProviderLabel,
    required this.fmtDate,
    required this.join,
  });

  final Map<String, dynamic>? detail;
  final Map? profile;
  final Map? dietary;
  final String Function(dynamic) sexLabel;
  final String Function(dynamic) activityLabel;
  final String Function(dynamic) goalLabel;
  final String Function(dynamic) budgetLabel;
  final String Function(dynamic) authProviderLabel;
  final String Function(dynamic) fmtDate;
  final String Function(dynamic) join;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _Panel(
          title: 'Tài khoản',
          child: Column(
            children: [
              _InfoRow(label: 'Tên', value: detail?['displayName']?.toString() ?? '—'),
              _InfoRow(label: 'Email', value: detail?['email']?.toString() ?? '—'),
              _InfoRow(label: 'SĐT', value: detail?['phone']?.toString() ?? '—'),
              _InfoRow(
                label: 'Đăng nhập',
                value: authProviderLabel(detail?['authProvider']),
              ),
              _InfoRow(label: 'Tạo lúc', value: fmtDate(detail?['createdAt'])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Hồ sơ cơ thể',
          child: profile == null
              ? const _EmptyHint('Chưa có hồ sơ')
              : Column(
                  children: [
                    _InfoRow(label: 'Chiều cao', value: '${profile!['heightCm']} cm'),
                    _InfoRow(label: 'Cân nặng', value: '${profile!['weightKg']} kg'),
                    _InfoRow(
                      label: 'Mục tiêu cân',
                      value: '${profile!['targetWeightKg']} kg',
                    ),
                    _InfoRow(label: 'Tuổi', value: '${profile!['age']}'),
                    _InfoRow(label: 'Giới tính', value: sexLabel(profile!['sex'])),
                    _InfoRow(
                      label: 'Vận động',
                      value: activityLabel(profile!['activityLevel']),
                    ),
                    _InfoRow(label: 'BMI', value: '${profile!['bmi']}'),
                    _InfoRow(label: 'BMR', value: '${profile!['bmr']}'),
                    _InfoRow(label: 'TDEE', value: '${profile!['tdee']}'),
                    _InfoRow(
                      label: 'Calo mục tiêu',
                      value: '${profile!['calorieTarget']}',
                    ),
                    _InfoRow(
                      label: 'Mục tiêu',
                      value: goalLabel(profile!['goalType']),
                    ),
                    _InfoRow(
                      label: 'Onboarding',
                      value: profile!['onboardingCompleted'] == true
                          ? 'Hoàn tất (${profile!['onboardingStep'] ?? 'done'})'
                          : 'Chưa xong (${profile!['onboardingStep'] ?? '—'})',
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Dinh dưỡng & sở thích',
          child: dietary == null
              ? const _EmptyHint('Chưa kê khai')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Ngân sách',
                      value: budgetLabel(dietary!['budgetLevel']),
                    ),
                    const SizedBox(height: 8),
                    _FoodGroup(title: 'Thích', items: dietary!['likedFoods']),
                    _FoodGroup(title: 'Ghét', items: dietary!['dislikedFoods']),
                    _FoodGroup(title: 'Dị ứng', items: dietary!['allergies']),
                    _FoodGroup(
                      title: 'Đủ điều kiện',
                      items: dietary!['eligibleFoods'],
                    ),
                    if ((dietary!['localFoodNotes'] as String?)?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ghi chú địa phương',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dietary!['localFoodNotes'] as String,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.appSettings,
    required this.updatedAt,
    required this.onOff,
    required this.padTime,
    required this.mealWindow,
  });

  final Map? appSettings;
  final String updatedAt;
  final String Function(dynamic) onOff;
  final String Function(dynamic, dynamic) padTime;
  final String Function(dynamic) mealWindow;

  @override
  Widget build(BuildContext context) {
    final theme = appSettings?['theme'] as Map?;
    final reminders = appSettings?['reminders'] as Map?;
    final mealWindows = appSettings?['mealWindows'] as Map?;

    if (appSettings == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: _EmptyHint(
            'Chưa đồng bộ cài đặt.\nUser cần mở app hoặc đổi setting một lần.',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Cập nhật lần cuối: $updatedAt',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Giao diện',
          child: Column(
            children: [
              _ToggleRow(label: 'Chế độ tối', value: onOff(theme?['isDark'])),
              _ToggleRow(
                label: 'Danh sách gọn',
                value: onOff(theme?['compactLists']),
              ),
              _ToggleRow(
                label: 'Nhắc bữa (chung)',
                value: onOff(theme?['mealReminders']),
              ),
              _ToggleRow(
                label: 'Nhắc động viên',
                value: onOff(theme?['encouragementReminders']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Nhắc nhở & thói quen',
          child: Column(
            children: [
              _ToggleRow(
                label: 'Bật nhắc bữa',
                value: onOff(reminders?['mealRemindersEnabled']),
              ),
              _InfoRow(
                label: 'Giờ thức dậy',
                value: padTime(
                  reminders?['breakfastHour'],
                  reminders?['breakfastMinute'],
                ),
              ),
              _ToggleRow(
                label: 'Uống nước ấm',
                value: onOff(reminders?['warmWater']),
              ),
              _ToggleRow(
                label: 'Vận động nhẹ',
                value: onOff(reminders?['lightExercise']),
              ),
              _ToggleRow(
                label: 'Bỏ qua linh hoạt',
                value: onOff(reminders?['flexibleSkip']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Khung giờ bữa',
          child: Column(
            children: [
              _InfoRow(
                label: 'Sáng',
                value: mealWindow(mealWindows?['breakfast']),
              ),
              _InfoRow(
                label: 'Trưa',
                value: mealWindow(mealWindows?['lunch']),
              ),
              _InfoRow(
                label: 'Tối',
                value: mealWindow(mealWindows?['dinner']),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.dateKey,
    required this.progress,
    required this.meals,
    required this.userId,
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
    required this.onOpenFull,
    required this.onOpenMeal,
    required this.countTrue,
  });

  final String dateKey;
  final Map<String, dynamic>? progress;
  final List<Map<String, dynamic>> meals;
  final String userId;
  final String Function(String) periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final VoidCallback onOpenFull;
  final void Function(Map<String, dynamic> meal) onOpenMeal;
  final int Function(dynamic) countTrue;

  Map<String, dynamic>? _mealEntry(String period) {
    for (final m in meals) {
      if (m['period']?.toString() == period) return m;
    }
    return null;
  }

  /// Bữa đạt khi tiến độ đã tick. Nếu chưa mà user vẫn có ảnh / ghi nhận thì
  /// báo "chưa đủ" thay vì ✗, để admin không tưởng user bỏ bữa.
  (_FlagState, String?) _mealFlag(String period) {
    if (progress?[_progressKey(period)] == true) return (_FlagState.done, null);
    final entry = _mealEntry(period);
    if (entry == null) return (_FlagState.none, null);
    return (
      _FlagState.partial,
      entry['hasImage'] == true ? 'Có ảnh' : 'Chưa đạt',
    );
  }

  static String _progressKey(String period) {
    switch (period) {
      case 'breakfast':
        return 'mealBreakfast';
      case 'lunch':
        return 'mealLunch';
      default:
        return 'mealDinner';
    }
  }

  _FlagState _countFlag(int value, int target) {
    if (value >= target) return _FlagState.done;
    return value > 0 ? _FlagState.partial : _FlagState.none;
  }

  Widget _buildProgressPanel() {
    final water = countTrue(progress?['waterSlots']);
    final exercise = countTrue(progress?['exerciseSlots']);
    final sessions = countTrue(progress?['exerciseSessionAwards']);
    final breakfast = _mealFlag('breakfast');
    final lunch = _mealFlag('lunch');
    final dinner = _mealFlag('dinner');

    return _Panel(
      title: 'Tiến độ ngày',
      trailing: TextButton(
        onPressed: onOpenFull,
        child: const Text('Chi tiết ảnh'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _DayFlag(
                label: 'Sáng',
                state: breakfast.$1,
                value: breakfast.$2,
              ),
              _DayFlag(label: 'Trưa', state: lunch.$1, value: lunch.$2),
              _DayFlag(label: 'Tối', state: dinner.$1, value: dinner.$2),
              _DayFlag(
                label: 'Nước',
                state: _countFlag(water, 6),
                value: '$water/6',
              ),
              _DayFlag(
                label: 'VĐ',
                state: _countFlag(exercise, 2),
                value: '$exercise/3',
              ),
              _DayFlag(
                label: 'Phiên',
                state: _countFlag(sessions, 1),
                value: '$sessions/3',
              ),
              _DayFlag(
                label: '+Điểm VĐ',
                state: _countFlag(sessions, 1),
                value: '+$sessions',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Xanh: đạt · Cam: có ghi nhận nhưng chưa đủ · Đỏ: chưa có',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          dateKey,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Chạm để chọn ngày',
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (progress != null || meals.isNotEmpty) _buildProgressPanel(),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Bữa & ảnh',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${meals.length} mục',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (meals.isEmpty)
          const _EmptyHint('Ngày này chưa có bữa / ảnh upload')
        else
          for (final meal in meals) ...[
            _MealCard(
              title: periodLabel(meal['period']?.toString() ?? ''),
              meal: meal,
              imageUrl: meal['hasImage'] == true && meal['id'] != null
                  ? AdminApi.mealImageUri(userId, meal['id'] as String)
                  : null,
              onTap: () => onOpenMeal(meal),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final on = value == 'Bật';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (on ? AppColors.success : AppColors.textSecondary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: on ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodGroup extends StatelessWidget {
  const _FoodGroup({required this.title, required this.items});

  final String title;
  final dynamic items;

  @override
  Widget build(BuildContext context) {
    final raw = items is List ? items as List : const <dynamic>[];
    final list = <String>[
      for (final e in raw)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Text('—', style: TextStyle(color: AppColors.textSecondary))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: list
                  .map(
                    (f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/// Đạt chỉ tiêu / có ghi nhận nhưng chưa đủ / chưa có gì.
enum _FlagState { done, partial, none }

class _DayFlag extends StatelessWidget {
  const _DayFlag({
    required this.label,
    required this.state,
    this.value,
  });

  final String label;
  final _FlagState state;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      _FlagState.done => (Icons.check_circle_rounded, AppColors.success),
      _FlagState.partial => (Icons.error_rounded, AppColors.warning),
      _FlagState.none => (Icons.cancel_rounded, AppColors.error),
    };

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value ?? label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (value != null)
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.title,
    required this.meal,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final Map<String, dynamic> meal;
  final Uri? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foods = <String>[
      for (final e in ((meal['foodItems'] as List?) ?? const []))
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
    final token = AuthService.instance.token;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null && token != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl.toString(),
                          fit: BoxFit.cover,
                          headers: {'Authorization': 'Bearer $token'},
                          errorBuilder: (_, error, stack) => Container(
                            color: AppColors.border.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: const Text('Không tải được ảnh'),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Xem món',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.3),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Text(
                    'Không có ảnh',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (meal['marksCompleted'] == true)
                          Text(
                            'Đã ghi nhận',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                    if (foods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: foods
                            .take(6)
                            .map(
                              (f) => Chip(
                                label: Text(
                                  f,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.2),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
