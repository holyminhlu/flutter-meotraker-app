import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/progress_service.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key, required this.points});

  final int points;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  static const _rewards = [
    ('Sticker động lực', 50),
    ('Theme vàng Meo', 100),
    ('Badge Hạng Bạc', 200),
    ('Voucher ăn nhẹ', 350),
  ];

  late int _points;

  @override
  void initState() {
    super.initState();
    _points = ProgressService.instance.points;
    ProgressService.instance.addListener(_onProgress);
  }

  @override
  void dispose() {
    ProgressService.instance.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() => _points = ProgressService.instance.points);
  }

  Future<void> _claim(String name, int cost) async {
    final ok = await ProgressService.instance.spendPoints(cost);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
              ok
                  ? 'Đã đổi "$name" (−$cost xu). Còn $_points xu.'
                  : 'Không đủ xu để đổi "$name".',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi quà')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(AppIcons.xu, width: 48, height: 48),
                const SizedBox(width: 12),
                Text(
                  'Xu hiện có: $_points',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._rewards.map((r) {
            final enough = _points >= r.$2;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading:
                    Image.asset(AppIcons.anMungDatMoc, width: 40, height: 40),
                title: Text(
                  r.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${r.$2} xu'),
                trailing: TextButton(
                  onPressed: enough ? () => _claim(r.$1, r.$2) : null,
                  child: Text(enough ? 'Đổi' : 'Thiếu xu'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
