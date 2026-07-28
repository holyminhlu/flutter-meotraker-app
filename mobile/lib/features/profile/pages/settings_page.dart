import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';
import 'package:meo_traker/features/profile/widgets/day_night_switch.dart';
import 'package:meo_traker/features/profile/widgets/profile_menu_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeSettingsService get _settings => ThemeSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const ProfileSectionLabel('GIAO DIỆN'),
          _SettingsCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sáng / Tối',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _settings.isDark
                            ? 'Đang dùng chế độ tối'
                            : 'Đang dùng chế độ sáng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                DayNightSwitch(
                  value: _settings.isDark,
                  onChanged: (v) => _settings.setDark(v),
                ),
              ],
            ),
          ),
          const ProfileSectionLabel('NHẮC NHỞ'),
          _SettingsCard(
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Nhắc bữa ăn',
                  subtitle: 'Thông báo trong khung giờ bữa sáng / trưa / tối',
                  value: _settings.mealReminders,
                  onChanged: _settings.setMealReminders,
                ),
                Divider(height: 20, color: AppColors.border),
                _ToggleRow(
                  title: 'Lời động viên',
                  subtitle: 'Slogan khuyến khích uống nước & ăn đúng giờ',
                  value: _settings.encouragementReminders,
                  onChanged: _settings.setEncouragementReminders,
                ),
              ],
            ),
          ),
          const ProfileSectionLabel('HIỂN THỊ'),
          _SettingsCard(
            child: _ToggleRow(
              title: 'Danh sách gọn',
              subtitle: 'Giảm khoảng cách các mục trong thử thách & thống kê',
              value: _settings.compactLists,
              onChanged: _settings.setCompactLists,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cài đặt được lưu trên thiết bị này.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
