import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class PrivacyCompanionPage extends StatefulWidget {
  const PrivacyCompanionPage({super.key});

  @override
  State<PrivacyCompanionPage> createState() => _PrivacyCompanionPageState();
}

class _PrivacyCompanionPageState extends State<PrivacyCompanionPage> {
  bool _telegramEnabled = false;
  bool _shareChart = true;
  bool _shareCalories = true;
  bool _shareMealPhotos = false;
  bool _linked = false;
  bool _mutualView = true;
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền riêng tư & Đồng hành')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Image.asset(AppIcons.quyenRiengTu, width: 28, height: 28),
              const SizedBox(width: 8),
              const Text(
                'Chia sẻ Telegram',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Gửi tin qua Telegram',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            value: _telegramEnabled,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _telegramEnabled = v),
          ),
          if (_telegramEnabled) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chỉ gửi biểu đồ'),
              value: _shareChart,
              activeColor: AppColors.primary,
              checkColor: AppColors.onPrimary,
              onChanged: (v) => setState(() => _shareChart = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gửi tổng calo'),
              value: _shareCalories,
              activeColor: AppColors.primary,
              checkColor: AppColors.onPrimary,
              onChanged: (v) => setState(() => _shareCalories = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gửi ảnh món ăn'),
              value: _shareMealPhotos,
              activeColor: AppColors.primary,
              checkColor: AppColors.onPrimary,
              onChanged: (v) => setState(() => _shareMealPhotos = v ?? false),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Chế độ đồng hành 2 chiều',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (!_linked) ...[
            TextField(
              controller: _inviteCtrl,
              decoration: const InputDecoration(
                labelText: 'Email / SĐT người đồng hành',
                hintText: 'banbe@email.com',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_inviteCtrl.text.trim().isEmpty) return;
                setState(() => _linked = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi lời mời đồng hành (demo)')),
                );
              },
              child: const Text('Gửi lời mời'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Đang liên kết với Miu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Cho phép xem tiến trình lẫn nhau',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              value: _mutualView,
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
              onChanged: (v) => setState(() => _mutualView = v),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _linked = false;
                  _inviteCtrl.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Hủy liên kết'),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu quyền riêng tư (local)')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
