import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/widgets/page_menu_banner.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/onboarding_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/auth/login_page.dart';
import 'package:meo_traker/features/home/widgets/motivation_badge_cards.dart';
import 'package:meo_traker/features/profile/pages/about_app_page.dart';
import 'package:meo_traker/features/profile/pages/dashboard_overview_page.dart';
import 'package:meo_traker/features/profile/pages/nutrition_prefs_page.dart';
import 'package:meo_traker/features/profile/pages/reminders_page.dart';
import 'package:meo_traker/features/profile/pages/settings_page.dart';
import 'package:meo_traker/features/profile/widgets/profile_header.dart';
import 'package:meo_traker/features/profile/widgets/profile_menu_tile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  double _currentWeight = 55;
  double _targetWeight = 65;

  ProgressService get _progress => ProgressService.instance;

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
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      final p = status.profile;
      if (p != null) {
        final w = (p['weightKg'] as num?)?.toDouble() ?? _currentWeight;
        await _progress.seedWeightIfEmpty(w);
        _currentWeight = _progress.latestWeight ?? w;
        _targetWeight =
            (p['targetWeightKg'] as num?)?.toDouble() ?? _targetWeight;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page))
        .then((_) {
      _load();
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục dùng app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Người dùng';
    final contact = user?.email ?? user?.phone ?? '';
    final streak = _progress.displayStreak;
    final points = _progress.points;
    final badge = badgeLabelForStreak(streak);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const PageMenuBanner(title: 'Hồ sơ'),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                        children: [
                    ProfileHeader(
                      displayName: name,
                      contact: contact,
                      badgeLabel: badge,
                      currentWeight: _currentWeight,
                      targetWeight: _targetWeight,
                      streakDays: streak,
                      points: points,
                    ),
                    const ProfileSectionLabel('PHÂN HỆ'),
                    ProfileMenuTile(
                      iconPath: AppIcons.lichSuBieuDo,
                      title: 'Dashboard tổng quan',
                      subtitle: 'Biểu đồ cân nặng, BMI/BMR, cập nhật cân',
                      onTap: () => _open(const DashboardOverviewPage()),
                    ),
                    ProfileMenuTile(
                      iconPath: AppIcons.soThich,
                      title: 'Dinh dưỡng & sở thích',
                      subtitle: 'Thích/ghét, dị ứng, ngân sách, vận động',
                      onTap: () => _open(const NutritionPrefsPage()),
                    ),
                    ProfileMenuTile(
                      iconPath: AppIcons.khungGioNhacNho,
                      title: 'Cài đặt nhắc nhở',
                      subtitle: 'Khung giờ bữa ăn & thói quen',
                      onTap: () => _open(const RemindersPage()),
                    ),
                    const ProfileSectionLabel('ỨNG DỤNG'),
                    ProfileMenuTile(
                      iconPath: AppIcons.khungGio,
                      title: 'Cài đặt',
                      subtitle: 'Giao diện sáng/tối, nhắc nhở, hiển thị',
                      onTap: () => _open(const SettingsPage()),
                    ),
                    ProfileMenuTile(
                      iconPath: AppIcons.mucTieu,
                      title: 'Phiên bản ứng dụng',
                      subtitle: 'Thông tin Meo Traker & bản dựng',
                      onTap: () => _open(const AboutAppPage()),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontWeight: FontWeight.w800),
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
