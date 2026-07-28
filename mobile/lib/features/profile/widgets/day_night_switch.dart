import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Toggle sáng/tối kiểu Uiverse (sun–moon, mây, sao).
/// [value] == true → chế độ tối.
class DayNightSwitch extends StatefulWidget {
  const DayNightSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<DayNightSwitch> createState() => _DayNightSwitchState();
}

class _DayNightSwitchState extends State<DayNightSwitch>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _cloudCtrl;
  late final AnimationController _starCtrl;

  static const double _w = 60;
  static const double _h = 34;
  static const double _knob = 26;
  static const double _pad = 4;
  static const double _travel = _w - _knob - _pad * 2;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.value ? 1 : 0,
    );
    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DayNightSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _slideCtrl.forward();
      } else {
        _slideCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _cloudCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged(!widget.value);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: widget.value,
      button: true,
      label: widget.value ? 'Chế độ tối' : 'Chế độ sáng',
      child: GestureDetector(
        onTap: _toggle,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideCtrl, _cloudCtrl, _starCtrl]),
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_slideCtrl.value);
              final cloudPhase = _cloudCtrl.value * math.pi * 2;
              final cloudX = math.sin(cloudPhase) * 4;
              final cloudX2 = math.sin(cloudPhase - 1) * 4;
              final starTwinkle = 1 + 0.2 * math.sin(_starCtrl.value * math.pi * 2);

              return ClipRRect(
                borderRadius: BorderRadius.circular(_h / 2),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Track
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF2196F3),
                          Colors.black,
                          t,
                        ),
                        borderRadius: BorderRadius.circular(_h / 2),
                      ),
                    ),
                    // Clouds (visible in day)
                    Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(cloudX2, 0),
                        child: Stack(
                          children: [
                            _cloud(const Offset(18, 24), 30, const Color(0xFFCCCCCC)),
                            _cloud(const Offset(30, 15), 40, const Color(0xFFCCCCCC)),
                            _cloud(const Offset(44, 10), 20, const Color(0xFFCCCCCC)),
                          ],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(cloudX, 0),
                        child: Stack(
                          children: [
                            _cloud(const Offset(22, 26), 30, const Color(0xFFEEEEEE)),
                            _cloud(const Offset(36, 18), 40, const Color(0xFFEEEEEE)),
                            _cloud(const Offset(48, 14), 20, const Color(0xFFEEEEEE)),
                          ],
                        ),
                      ),
                    ),
                    // Stars (visible at night)
                    Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, -32 * (1 - t)),
                        child: Stack(
                          children: [
                            _star(const Offset(3, 2), 10 * starTwinkle, 0.3),
                            _star(const Offset(3, 16), 3, 0),
                            _star(const Offset(10, 20), 6 * starTwinkle, 0.6),
                            _star(const Offset(18, 0), 9 * starTwinkle, 1.3),
                          ],
                        ),
                      ),
                    ),
                    // Sun / Moon knob
                    Positioned(
                      left: _pad + _travel * t,
                      bottom: _pad,
                      child: Transform.rotate(
                        angle: t * math.pi * 0.35,
                        child: SizedBox(
                          width: _knob,
                          height: _knob,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Light rays (day)
                              if (t < 0.85) ...[
                                Opacity(
                                  opacity: (1 - t) * 0.12,
                                  child: Align(
                                    child: Container(
                                      width: 43,
                                      height: 43,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: (1 - t) * 0.1,
                                  child: Align(
                                    child: Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              Container(
                                width: _knob,
                                height: _knob,
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.yellow,
                                    Colors.white,
                                    t,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              // Moon dots
                              Opacity(
                                opacity: t,
                                child: Stack(
                                  children: [
                                    _moonDot(const Offset(10, 3), 6),
                                    _moonDot(const Offset(2, 10), 10),
                                    _moonDot(const Offset(16, 18), 3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cloud(Offset pos, double size, Color color) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        width: size * 0.55,
        height: size * 0.4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _moonDot(Offset pos, double size) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF9E9E9E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _star(Offset pos, double size, double delayPhase) {
    final twinkle =
        1 + 0.2 * math.sin((_starCtrl.value + delayPhase) * math.pi * 2);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Transform.scale(
        scale: twinkle,
        child: CustomPaint(
          size: Size(size, size),
          painter: _StarPainter(),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    path.moveTo(cx, cy - r);
    path.quadraticBezierTo(cx, cy, cx + r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + r);
    path.quadraticBezierTo(cx, cy, cx - r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - r);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
