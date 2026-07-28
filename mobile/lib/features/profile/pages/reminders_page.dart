import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/meal/habit_slogans.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/local_notification_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late TimeOfDay _breakfast;
  late bool _mealReminders;
  late bool _warmWater;
  late bool _lightExercise;
  late bool _flexibleSkip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final svc = MealScheduleService.instance;
    await svc.load();
    if (!mounted) return;
    setState(() {
      _breakfast = svc.breakfast;
      _mealReminders = svc.mealRemindersEnabled;
      _warmWater = svc.warmWater;
      _lightExercise = svc.lightExercise;
      _flexibleSkip = svc.flexibleSkip;
      _loading = false;
    });
  }

  MealScheduleRow get _row => scheduleForBreakfast(_breakfast);

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    await MealScheduleService.instance.savePrefs(
      breakfastTime: _breakfast,
      mealReminders: _mealReminders,
      warmWaterHabit: _warmWater,
      lightExerciseHabit: _lightExercise,
      allowFlexibleSkip: _flexibleSkip,
    );
    // Đồng bộ cờ "Lời động viên" để lịch ngoài app khớp trang này.
    await ThemeSettingsService.instance.setEncouragementReminders(_mealReminders);
    await LocalNotificationService.instance.requestPermission();
    await LocalNotificationService.instance.rescheduleAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã lưu. Thông báo hệ thống sẽ hiện cả khi tắt app (đúng khung giờ).',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _testNotification() async {
    final ok = await LocalNotificationService.instance.requestPermission();
    await LocalNotificationService.instance.showNow(
      id: 999001,
      title: 'Meo Traker · thử thông báo',
      body: ok
          ? 'Nếu thấy dòng này trên thanh thông báo thì quyền đã OK. Đóng app — lời động viên vẫn gửi theo khung giờ.'
          : 'Chưa cấp quyền thông báo. Vào Cài đặt máy → Ứng dụng → Meo Traker → Thông báo.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã gửi thử — kéo thanh thông báo xuống để kiểm tra.'
              : 'Thiếu quyền thông báo trên máy.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final row = _row;
    final windows = buildEncouragementWindows(_breakfast);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt nhắc nhở')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Image.asset(AppIcons.khungGio, width: 28, height: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Giờ thức dậy / ăn sáng',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dùng làm mốc thông báo buổi sáng. Khung ăn cố định: sáng 07:00–09:00, '
            'trưa 12:30–13:30, tối 18:00–19:30.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TimeOfDay>(
                isExpanded: true,
                value: mealScheduleTable
                    .map((r) => r.breakfast)
                    .firstWhere(
                      (t) =>
                          t.hour == _breakfast.hour &&
                          t.minute == _breakfast.minute,
                      orElse: () => mealScheduleTable[2].breakfast,
                    ),
                items: [
                  for (final r in mealScheduleTable)
                    DropdownMenuItem(
                      value: r.breakfast,
                      child: Text('Thức dậy ${_fmtTod(r.breakfast)}'),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _breakfast = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoTile(title: 'Ăn trưa (lịch)', value: row.lunch.label),
          _InfoTile(title: 'Ăn tối (lịch)', value: row.dinner.label),
          _InfoTile(
            title: 'Giờ ngủ (tham khảo)',
            value: row.sleep.label,
            subtitle: 'Không gửi thông báo',
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Thông báo khuyến khích (ngoài app)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              '4 khung/ngày · hiện trên thanh thông báo cả khi tắt app. Slogan random.',
            ),
            value: _mealReminders,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _mealReminders = v),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Gửi thử thông báo ngay'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Khung thông báo hôm nay',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          for (final w in windows)
            _InfoTile(
              title: w.title,
              value: w.windowLabel,
              subtitle: w.theme == SloganTheme.water
                  ? 'Ưu tiên slogan uống nước'
                  : 'Ưu tiên slogan ăn đủ bữa',
            ),
          const SizedBox(height: 12),
          const Text(
            'Kho slogan (random)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          for (final s in habitSlogans)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                s.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Image.asset(AppIcons.khungGioNhacNho, width: 28, height: 28),
              const SizedBox(width: 8),
              const Text(
                'Nhắc nhở thói quen',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: AppIcons.uongNuocAm,
            title: 'Uống nước ấm buổi sáng',
            value: _warmWater,
            onChanged: (v) => setState(() => _warmWater = v),
          ),
          _ToggleTile(
            icon: AppIcons.vanDongNhe,
            title: 'Vận động nhẹ',
            value: _lightExercise,
            onChanged: (v) => setState(() => _lightExercise = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Cho phép “Để sau” trên thông báo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            value: _flexibleSkip,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _flexibleSkip = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Lưu cài đặt'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        secondary: Image.asset(icon, width: 36, height: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        value: value,
        activeThumbColor: AppColors.onPrimary,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
