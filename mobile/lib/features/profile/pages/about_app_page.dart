import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_constants.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phiên bản ứng dụng')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Image.asset(AppIcons.anMungDatMoc, width: 52, height: 52),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phiên bản ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: 'Giới thiệu',
            body:
                'Meo Traker giúp bạn theo dõi tăng cân lành mạnh: '
                'ghi nhận bữa ăn, uống nước, vận động nhẹ, thử thách điểm thưởng '
                'và nhắc nhở duy trì thói quen mỗi ngày.',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            title: 'Thông tin kỹ thuật',
            body:
                'Nền tảng: Flutter (Android / iOS / Windows)\n'
                'Backend: Node.js + Express + PostgreSQL\n'
                'Gói bản dựng: ${AppConstants.appVersion}+1',
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            title: 'Liên hệ & hỗ trợ',
            body:
                'Góp ý tính năng hoặc báo lỗi qua đội phát triển dự án Meo Traker.\n'
                '© 2026 Meo Traker. Mọi quyền được bảo lưu.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
