import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/admin_api.dart';
import 'package:meo_traker/data/services/auth_service.dart';

/// Xem ảnh bữa ăn full + chi tiết món AI nhận diện.
class AdminMealPhotoDetailPage extends StatelessWidget {
  const AdminMealPhotoDetailPage({
    super.key,
    required this.userId,
    required this.displayName,
    required this.meal,
    required this.periodLabel,
  });

  final String userId;
  final String displayName;
  final Map<String, dynamic> meal;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final token = AuthService.instance.token;
    final hasImage = meal['hasImage'] == true && meal['id'] != null;
    final imageUrl = hasImage
        ? AdminApi.mealImageUri(userId, meal['id'] as String)
        : null;
    final foods = ((meal['foodItems'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final description = (meal['description'] as String?)?.trim() ?? '';
    final advice = (meal['advice'] as String?)?.trim() ?? '';
    final aiSummary = (meal['aiSummary'] as String?)?.trim() ?? '';
    final timing = (meal['timingStatus'] as String?)?.trim() ?? '';
    final dateKey = meal['dateKey']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$periodLabel${dateKey.isEmpty ? '' : ' · $dateKey'}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (imageUrl != null && token != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl.toString(),
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  headers: {'Authorization': 'Bearer $token'},
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    alignment: Alignment.center,
                    color: AppColors.border.withValues(alpha: 0.4),
                    child: const Text('Không tải được ảnh'),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Bữa này không có ảnh upload',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Món ăn nhận diện',
            child: foods.isEmpty
                ? Text(
                    'AI chưa liệt kê món cụ thể',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: foods
                        .map(
                          (f) => Chip(
                            label: Text(
                              f,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.25),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Mô tả bữa ăn',
              child: Text(
                description,
                style: TextStyle(
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (aiSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Tóm tắt AI',
              child: Text(
                aiSummary,
                style: TextStyle(
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Lời khuyên',
              child: Text(
                advice,
                style: TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Trạng thái',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  label: 'Ghi nhận bữa',
                  value: meal['marksCompleted'] == true ? 'Có' : 'Không',
                  ok: meal['marksCompleted'] == true,
                ),
                _StatusRow(
                  label: 'Món hợp lệ',
                  value: meal['foodValid'] == true ? 'Có' : 'Không / chưa rõ',
                  ok: meal['foodValid'] == true,
                ),
                if (timing.isNotEmpty)
                  _StatusRow(
                    label: 'Thời điểm',
                    value: _timingLabel(timing),
                    ok: timing == 'on_time' || timing == 'ok',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timingLabel(String raw) {
    switch (raw) {
      case 'on_time':
      case 'ok':
        return 'Đúng khung giờ';
      case 'early':
        return 'Sớm hơn khung giờ';
      case 'late':
        return 'Muộn hơn khung giờ';
      case 'outside':
        return 'Ngoài khung giờ';
      default:
        return raw;
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
