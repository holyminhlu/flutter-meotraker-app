import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/weather_service.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.displayName,
    required this.greeting,
    required this.streakDays,
  });

  final String displayName;
  final String greeting;
  final int streakDays;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _floatCtrl;
  AnimationController? _weatherSwapCtrl;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _greetFade;
  late final Animation<Offset> _greetSlide;
  late final Animation<double> _chipsFade;
  late final Animation<double> _chipsScale;
  late final Animation<double> _glowPulse;

  Timer? _weatherTimer;
  Timer? _weatherRefreshTimer;
  bool _showTemp = false;
  bool _swapping = false;

  WeatherService get _weather => WeatherService.instance;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _weatherSwapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _titleFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _greetFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.22, 0.7, curve: Curves.easeOutCubic),
    );
    _greetSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _chipsFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    );
    _chipsScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.4, 0.95, curve: Curves.easeOutBack),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _enterCtrl.forward();
    _weather.addListener(_onWeather);
    _weather.fetch();
    _weatherTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _swapWeatherFace();
    });
    _weatherRefreshTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      _weather.fetch();
    });
  }

  Future<void> _swapWeatherFace() async {
    final ctrl = _weatherSwapCtrl;
    if (!mounted || ctrl == null || _swapping) return;
    _swapping = true;
    try {
      await ctrl.forward();
      if (!mounted) return;
      setState(() => _showTemp = !_showTemp);
      await ctrl.reverse();
    } finally {
      _swapping = false;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _weatherSwapCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  void _onWeather() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.greeting != widget.greeting ||
        oldWidget.displayName != widget.displayName) {
      _enterCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _weather.removeListener(_onWeather);
    _weatherTimer?.cancel();
    _weatherRefreshTimer?.cancel();
    _enterCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _weatherSwapCtrl?.dispose();
    super.dispose();
  }

  /// Ngày/đêm theo giờ VN tại khu vực (Vĩnh Long · Asia/Ho_Chi_Minh).
  bool get _isDayLocal {
    if (_weather.temperatureC != null) return _weather.isDay;
    final h = AppClock.instance.now().hour;
    return h >= 6 && h < 18;
  }

  @override
  Widget build(BuildContext context) {
    final streakIcon = AppIcons.streakForDays(widget.streakDays);
    final dayNightIcon =
        _isDayLocal ? Icons.wb_sunny_rounded : Icons.nightlight_round;

    final weatherSwap = _weatherSwapCtrl;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _enterCtrl,
        _shimmerCtrl,
        _floatCtrl,
        if (weatherSwap != null) weatherSwap,
      ]),
      builder: (context, _) {
        final floatY = math.sin(_floatCtrl.value * math.pi) * 3;
        final swapT = weatherSwap?.value ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -8,
              top: -6,
              child: Opacity(
                opacity: _glowPulse.value * _titleFade.value,
                child: Container(
                  width: 120,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.55),
                        AppColors.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Transform.translate(
                            offset: Offset(0, floatY),
                            child: _ShimmerName(
                              label: 'Chào ${widget.displayName}',
                              shimmer: _shimmerCtrl.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _greetFade,
                        child: SlideTransition(
                          position: _greetSlide,
                          child: Text(
                            widget.greeting,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _greetFade,
                        child: _AccentWave(progress: _shimmerCtrl.value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FadeTransition(
                  opacity: _chipsFade,
                  child: ScaleTransition(
                    scale: _chipsScale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatChip(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              child: Opacity(
                                opacity: 1 - swapT,
                                child: Transform.translate(
                                  offset: Offset(0, swapT * 6),
                                  child: _showTemp
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.thermostat_rounded,
                                              size: 20,
                                              color: AppColors.onPrimary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _weather.tempLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.onPrimary,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _weather.weatherIcon,
                                              size: 22,
                                              color: AppColors.onPrimary,
                                            ),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 88,
                                              ),
                                              child: Text(
                                                _weather.loading
                                                    ? '…'
                                                    : _weather.weatherLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  color: AppColors.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatChip(
                              color: _isDayLocal
                                  ? const Color(0xFFFFF3B0)
                                  : const Color(0xFFE8E4F8),
                              bordered: true,
                              child: Icon(
                                dayNightIcon,
                                size: 20,
                                color: _isDayLocal
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF3949AB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              WeatherService.locationLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              color: AppColors.surface,
                              bordered: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    streakIcon,
                                    width: 22,
                                    height: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.streakDays == 0
                                        ? '0'
                                        : '${widget.streakDays}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerName extends StatelessWidget {
  const _ShimmerName({required this.label, required this.shimmer});

  final String label;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final t = shimmer;
        return LinearGradient(
          begin: Alignment(-1.2 + t * 2.4, 0),
          end: Alignment(-0.2 + t * 2.4, 0),
          colors: [
            AppColors.textPrimary,
            AppColors.textPrimary,
            Color(0xFF8A7000),
            AppColors.primary,
            Color(0xFF8A7000),
            AppColors.textPrimary,
            AppColors.textPrimary,
          ],
          stops: const [0.0, 0.35, 0.45, 0.5, 0.55, 0.65, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          height: 1.15,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AccentWave extends StatelessWidget {
  const _AccentWave({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 4,
      child: CustomPaint(
        painter: _WavePainter(progress: progress),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.2),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    final mid = size.width * (0.35 + 0.3 * math.sin(progress * math.pi * 2));
    path.quadraticBezierTo(
      mid,
      size.height * (0.1 + 0.2 * math.sin(progress * math.pi * 2)),
      size.width,
      size.height * 0.55,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.child,
    required this.color,
    this.bordered = false,
  });

  final Widget child;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: bordered ? Border.all(color: AppColors.border) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
