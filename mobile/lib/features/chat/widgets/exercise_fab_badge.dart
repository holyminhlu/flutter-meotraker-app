import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

/// Nút vận động nhẹ — cạnh nút AI.
class ExerciseFabBadge extends StatefulWidget {
  const ExerciseFabBadge({
    super.key,
    this.size = 40,
    this.highlighted = false,
    this.onTap,
  });

  final double size;
  /// Sáng + pulse khi trong khung giờ vận động.
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  State<ExerciseFabBadge> createState() => _ExerciseFabBadgeState();
}

class _ExerciseFabBadgeState extends State<ExerciseFabBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant ExerciseFabBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlighted != widget.highlighted) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.highlighted) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = !widget.highlighted;
    final radius = widget.size * 0.28;

    Widget badge = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.highlighted
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: widget.highlighted
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              width: widget.highlighted ? 2 : 1,
            ),
            boxShadow: widget.highlighted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.size * 0.18),
            child: Image.asset(
              AppIcons.vanDongNhe,
              fit: BoxFit.contain,
              color: dimmed ? Colors.grey : null,
              colorBlendMode: dimmed ? BlendMode.modulate : null,
            ),
          ),
        ),
      ),
    );

    if (widget.highlighted) {
      badge = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + _pulseCtrl.value * 0.06,
            child: child,
          );
        },
        child: badge,
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: dimmed ? 0.5 : 1,
      child: badge,
    );
  }
}
