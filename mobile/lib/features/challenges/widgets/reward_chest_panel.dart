import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/features/challenges/widgets/coin_icon.dart';

/// Horizontal VIP chest banner + progress track toward reward milestones.
class RewardChestPanel extends StatelessWidget {
  const RewardChestPanel({
    super.key,
    required this.points,
    required this.vipThreshold,
    required this.superVipThreshold,
    required this.progressKey,
    required this.animatedProgress,
  });

  final int points;
  final int vipThreshold;
  final int superVipThreshold;
  final GlobalKey progressKey;
  final double animatedProgress;

  /// When within 5 points of super VIP (30), switch banner.
  bool get isSuperVip => points >= (superVipThreshold - 5);

  @override
  Widget build(BuildContext context) {
    final banner = isSuperVip ? AppIcons.ruongSuperVip : AppIcons.ruongVip;
    final title = isSuperVip ? 'Rương Super VIP' : 'Rương VIP';
    final remain = (superVipThreshold - points).clamp(0, 999);
    final subtitle = isSuperVip
        ? (remain == 0
            ? 'Đủ điểm mở quà Super VIP!'
            : 'Còn $remain điểm nữa mở quà tự chọn!')
        : 'Tích điểm để mở quà VIP & Super VIP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(banner, fit: BoxFit.cover),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CoinIcon(size: 28),
                        const SizedBox(width: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: progressKey,
          child: _RewardProgressBar(
            progress: animatedProgress / superVipThreshold,
            points: animatedProgress.round(),
            vipAt: vipThreshold / superVipThreshold,
            maxPoints: superVipThreshold,
          ),
        ),
      ],
    );
  }
}

class _RewardProgressBar extends StatelessWidget {
  const _RewardProgressBar({
    required this.progress,
    required this.points,
    required this.vipAt,
    required this.maxPoints,
  });

  final double progress;
  final int points;
  final double vipAt;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Tiến trình nhận thưởng',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '$points / $maxPoints',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (w * vipAt) - 1,
                  top: -2,
                  child: Container(
                    width: 2,
                    height: 20,
                    color: AppColors.onPrimary.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  left: (w * vipAt) - 18,
                  top: 20,
                  child: const Text(
                    'VIP 15',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 20,
                  child: Text(
                    'Super 30',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

Offset? globalCenterOf(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

Offset? progressTipOf(GlobalKey key, double progress01) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final local = Offset(
    box.size.width * progress01.clamp(0.05, 0.98),
    28,
  );
  return box.localToGlobal(local);
}

/// Flies coin chips along a semicircle arc from [from] to [to].
Future<void> playSemicirclePointFlight({
  required BuildContext context,
  required TickerProvider vsync,
  required Offset from,
  required Offset to,
  required int points,
  int particleCount = 6,
}) async {
  final overlay = Overlay.of(context);
  final entries = <OverlayEntry>[];
  final controllers = <AnimationController>[];
  final futures = <Future<void>>[];

  for (var i = 0; i < particleCount; i++) {
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 650 + i * 55),
    );
    controllers.add(controller);

    final entry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, child) {
            final t = Curves.easeInOutCubic.transform(controller.value);
            final mid = Offset(
              (from.dx + to.dx) / 2,
              math.min(from.dy, to.dy) - 100 - (i * 6),
            );
            final pos = _quadBezier(from, mid, to, t);
            final fade = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15);
            return Positioned(
              left: pos.dx - 14,
              top: pos.dy - 14,
              child: Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + 0.35 * math.sin(t * math.pi),
                  child: child,
                ),
              ),
            );
          },
          child: const CoinIcon(size: 28),
        );
      },
    );
    entries.add(entry);
    overlay.insert(entry);
    futures.add(
      Future<void>.delayed(Duration(milliseconds: i * 45)).then((_) async {
        await controller.forward();
      }),
    );
  }

  final labelCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 850),
  );
  controllers.add(labelCtrl);
  final labelEntry = OverlayEntry(
    builder: (_) {
      return AnimatedBuilder(
        animation: labelCtrl,
        builder: (_, child) {
          final t = Curves.easeOut.transform(labelCtrl.value);
          final mid = Offset(
            (from.dx + to.dx) / 2,
            math.min(from.dy, to.dy) - 120,
          );
          final pos = _quadBezier(from, mid, to, t);
          return Positioned(
            left: pos.dx - 18,
            top: pos.dy - 22,
            child: Opacity(
              opacity: (1 - t * 0.85).clamp(0.0, 1.0),
              child: Text(
                '+$points',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.onPrimary,
                  shadows: [Shadow(color: AppColors.primary, blurRadius: 10)],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  overlay.insert(labelEntry);
  entries.add(labelEntry);
  futures.add(labelCtrl.forward());

  await Future.wait(futures);
  await Future<void>.delayed(const Duration(milliseconds: 60));

  for (final e in entries) {
    e.remove();
  }
  for (final c in controllers) {
    c.dispose();
  }
}

Offset _quadBezier(Offset a, Offset b, Offset c, double t) {
  final u = 1 - t;
  return Offset(
    u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
    u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
  );
}
