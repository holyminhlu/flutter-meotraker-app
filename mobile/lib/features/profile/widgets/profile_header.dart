import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/avatar_service.dart';
import 'package:meo_traker/features/profile/pages/rewards_page.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.contact,
    required this.badgeLabel,
    required this.currentWeight,
    required this.targetWeight,
    required this.streakDays,
    required this.points,
  });

  final String displayName;
  final String contact;
  final String badgeLabel;
  final double currentWeight;
  final double targetWeight;
  final int streakDays;
  final int points;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  Uint8List? _avatarBytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final bytes = await AvatarService.instance.avatarBytes();
    if (!mounted) return;
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickAvatar() async {
    if (_busy) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (_avatarBytes != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    setState(() => _busy = true);
    try {
      if (action == 'remove') {
        await AvatarService.instance.clear();
        if (!mounted) return;
        setState(() => _avatarBytes = null);
      } else {
        final source =
            action == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final bytes =
            await AvatarService.instance.pickAndSave(source: source);
        if (!mounted) return;
        if (bytes != null) {
          setState(() => _avatarBytes = bytes);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _avatarBytes != null && _avatarBytes!.isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _busy ? null : _pickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: hasAvatar
                          ? DecorationImage(
                              image: MemoryImage(_avatarBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasAvatar
                        ? null
                        : const Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: AppColors.onPrimary,
                          ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: AppColors.onPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contact,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppIcons.anMungDatMoc,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.badgeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickStat(
                iconPath: AppIcons.canNang,
                label: 'Cân nặng',
                value:
                    '${widget.currentWeight.toStringAsFixed(1)} / ${widget.targetWeight.toStringAsFixed(0)} kg',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickStat(
                iconPath: AppIcons.anMungDatMoc,
                label: 'Streak',
                value: '${widget.streakDays} ngày 🔥',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickStat(
                iconPath: AppIcons.diemThuong,
                label: 'Điểm',
                value: '${widget.points}',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RewardsPage(points: widget.points),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.iconPath,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String iconPath;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Image.asset(iconPath, width: 28, height: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
