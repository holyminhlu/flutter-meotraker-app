import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/profile/pages/update_weight_page.dart';
import 'package:meo_traker/features/profile/widgets/weight_line_chart.dart';

class DashboardOverviewPage extends StatefulWidget {
  const DashboardOverviewPage({super.key});

  @override
  State<DashboardOverviewPage> createState() => _DashboardOverviewPageState();
}

class _DashboardOverviewPageState extends State<DashboardOverviewPage> {
  bool _loading = true;
  double _current = 55;
  double _target = 65;
  double _bmi = 19;
  double _bmr = 1500;
  double _calorie = 2800;
  bool _celebrate = false;
  String _range = 'week';

  ProgressService get _progress => ProgressService.instance;

  List<WeightPoint> get _chartPoints {
    final logs = _progress.weightHistory;
    if (logs.isEmpty) {
      return [WeightPoint(label: 'Nay', kg: _current)];
    }
    final take = _range == 'week' ? 7 : 30;
    final slice = logs.length <= take ? logs : logs.sublist(logs.length - take);
    return [
      for (final w in slice) WeightPoint(label: _label(w.dateKey), kg: w.kg),
    ];
  }

  String _label(String dateKey) {
    final p = dateKey.split('-');
    if (p.length == 3) return '${int.parse(p[2])}/${int.parse(p[1])}';
    return dateKey;
  }

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onProgress);
    _load();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    setState(() {
      _current = _progress.latestWeight ?? _current;
      _celebrate = _current >= _target;
    });
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      final p = status.profile;
      if (p != null) {
        final w = (p['weightKg'] as num?)?.toDouble() ?? _current;
        await _progress.seedWeightIfEmpty(w);
        _current = _progress.latestWeight ?? w;
        _target = (p['targetWeightKg'] as num?)?.toDouble() ?? _target;
        _bmi = (p['bmi'] as num?)?.toDouble() ?? _bmi;
        _bmr = (p['bmr'] as num?)?.toDouble() ?? _bmr;
        _calorie = (p['calorieTarget'] as num?)?.toDouble() ?? _calorie;
        _celebrate = _current >= _target;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUpdateWeight() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UpdateWeightPage(currentWeight: _current),
      ),
    );
    if (updated == true) {
      await _load();
      if (!mounted) return;
      if (_celebrate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Chạm mốc mục tiêu! Giữ nhịp đều đặn nhé.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final points = _chartPoints;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard tổng quan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('7 ngày'),
                selected: _range == 'week',
                selectedColor: AppColors.primary,
                onSelected: (_) => setState(() => _range = 'week'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('30 ngày'),
                selected: _range == 'month',
                selectedColor: AppColors.primary,
                onSelected: (_) => setState(() => _range = 'month'),
              ),
              const Spacer(),
              if (_celebrate)
                Image.asset(AppIcons.anMungDatMoc, width: 36, height: 36),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Biểu đồ cân nặng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          WeightLineChart(points: points, targetKg: _target),
          if (_celebrate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎉 Bạn đã chạm mốc cân nặng mục tiêu. Giữ nhịp đều đặn!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Chỉ số cơ thể',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  icon: AppIcons.canNang,
                  label: 'BMI',
                  value: _bmi.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  icon: AppIcons.nhuCauCalo,
                  label: 'BMR',
                  value: '${_bmr.toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  icon: AppIcons.mucTieu,
                  label: 'Calo/ngày',
                  value: '${_calorie.toInt()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openUpdateWeight,
            icon: Image.asset(AppIcons.canNang, width: 24, height: 24),
            label: const Text('Cập nhật cân nặng mới'),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
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
          Image.asset(icon, width: 28, height: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
