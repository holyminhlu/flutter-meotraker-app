import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/features/capture/capture_page.dart';
import 'package:meo_traker/features/challenges/challenges_page.dart';
import 'package:meo_traker/features/home/home_page.dart';
import 'package:meo_traker/features/profile/profile_page.dart';
import 'package:meo_traker/features/stats/stats_page.dart';

/// App shell with 5-tab bottom navigation and a raised center camera action.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  /// 0 Home · 1 Challenges · 3 Stats · 4 Profile (2 reserved for camera)
  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab;
  Timer? _ticker;

  MealScheduleService get _schedule => MealScheduleService.instance;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab == 2 ? 0 : widget.initialTab;
    _schedule.addListener(_onScheduleChanged);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _schedule.removeListener(_onScheduleChanged);
    super.dispose();
  }

  void _onScheduleChanged() {
    if (mounted) setState(() {});
  }

  int get _stackIndex {
    switch (_tab) {
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  bool get _canCapture => canCaptureMealNow(
        periods: _schedule.periods,
        now: AppClock.instance.now(),
        isCompleted: _schedule.isCompleted,
      );

  Future<void> _openCapture() async {
    if (!_canCapture) {
      if (!mounted) return;
      final label = captureBlockedLabel(
        periods: _schedule.periods,
        now: AppClock.instance.now(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label)),
      );
      return;
    }

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CapturePage(),
      ),
    );
    if (ok == true && mounted) setState(() {});
  }

  void _selectTab(int tab) {
    setState(() => _tab = tab == 2 ? 0 : tab);
  }

  @override
  Widget build(BuildContext context) {
    final canCapture = _canCapture;

    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          HomePage(
            onCaptureTap: _openCapture,
            onSelectTab: _selectTab,
          ),
          const ChallengesPage(),
          const StatsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                selected: _tab == 0,
                onTap: () => _selectTab(0),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Thử thách',
                selected: _tab == 1,
                onTap: () => _selectTab(1),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Material(
                      color: canCapture
                          ? AppColors.primary
                          : AppColors.border,
                      shape: const CircleBorder(),
                      elevation: canCapture ? 4 : 0,
                      clipBehavior: Clip.none,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _openCapture,
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: Icon(
                            canCapture
                                ? Icons.photo_camera_rounded
                                : Icons.schedule_rounded,
                            size: 34,
                            color: canCapture
                                ? Colors.black87
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Thống kê',
                selected: _tab == 3,
                onTap: () => _selectTab(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Hồ sơ',
                selected: _tab == 4,
                onTap: () => _selectTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
