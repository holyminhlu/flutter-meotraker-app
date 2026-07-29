import 'package:flutter/material.dart';

/// Nút chat AI — theo thiết kế Uiverse (ilkhoeri): gradient vàng 45°, sparkle góc trái, chữ AI lớn giữa.
class AiChatFab extends StatefulWidget {
  const AiChatFab({
    super.key,
    required this.size,
    this.pulsing = true,
    this.onTap,
  });

  final double size;
  final bool pulsing;
  final VoidCallback? onTap;

  @override
  State<AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends State<AiChatFab>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulsing) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AiChatFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.pulsing && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final szBtn = widget.size;
    final space = szBtn / 5.5;
    final genSz = space * 2;
    final szText = szBtn - genSz;
    const radius = 12.0;

    final sparkleDefaultLeft = szText / 7;
    final sparkleDefaultTop = szText / 7;
    final sparkleHoverLeft = szText / 4;
    final sparkleHoverTop = genSz / 2;

    final expanded = _hovered;
    final sparkleLeft = expanded ? sparkleHoverLeft : sparkleDefaultLeft;
    final sparkleTop = expanded ? sparkleHoverTop : sparkleDefaultTop;
    final sparkleSize = expanded ? szText : genSz;

    Widget sparkle = _SparkleIcon(
      size: sparkleSize,
      color: expanded ? Colors.white : const Color(0xFFFFEA50),
    );

    if (widget.pulsing && !expanded) {
      sparkle = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: 0.55 + _pulseCtrl.value * 0.45,
            child: Transform.scale(
              scale: 0.92 + _pulseCtrl.value * 0.12,
              child: child,
            ),
          );
        },
        child: sparkle,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: szBtn,
            height: szBtn,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFAD21), Color(0xFFFFD60F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3C4043).withValues(alpha: 0.30),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: const Color(0xFF3C4043).withValues(alpha: 0.15),
                    blurRadius: 6,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 60,
                    spreadRadius: -30,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF343434)
                                  .withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      left: sparkleLeft,
                      top: sparkleTop,
                      width: sparkleSize,
                      height: sparkleSize,
                      child: sparkle,
                    ),
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: expanded ? 0 : 1,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'AI',
                            style: TextStyle(
                              fontSize: szText,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon sparkle 3 sao (tương đương SVG gốc Heroicons).
class _SparkleIcon extends StatelessWidget {
  const _SparkleIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: color,
    );
  }
}
