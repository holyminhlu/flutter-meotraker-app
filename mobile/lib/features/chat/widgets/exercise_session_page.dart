import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/features/chat/widgets/exercise_moves.dart';

/// Phiên tập 10 phút: ảnh lớn, tự đếm ngược và tự chuyển động tác.
class ExerciseSessionPage extends StatefulWidget {
  const ExerciseSessionPage({
    super.key,
    required this.slotIndex,
    required this.slotTitle,
  });

  final int slotIndex;
  final String slotTitle;

  @override
  State<ExerciseSessionPage> createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  int _index = 0;
  int _remaining = kExerciseSteps.first.seconds;
  bool _running = false;
  bool _finishing = false;
  bool _completed = false;
  bool _pointAwarded = false;
  Timer? _timer;

  ExerciseStep get _step => kExerciseSteps[_index];

  int get _elapsedBeforeCurrent => kExerciseSteps
      .take(_index)
      .fold<int>(0, (total, step) => total + step.seconds);

  int get _totalRemaining =>
      kExerciseTotalSeconds - _elapsedBeforeCurrent - (_step.seconds - _remaining);

  double get _progress =>
      (kExerciseTotalSeconds - _totalRemaining) / kExerciseTotalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _finishing) return;
    if (_remaining > 1) {
      setState(() => _remaining -= 1);
      return;
    }
    _advanceAutomatically();
  }

  void _advanceAutomatically() {
    if (_index >= kExerciseSteps.length - 1) {
      _timer?.cancel();
      _completeWorkout();
      return;
    }
    setState(() {
      _index += 1;
      _remaining = _step.seconds;
    });
  }

  Future<void> _completeWorkout() async {
    if (_finishing) return;
    setState(() {
      _finishing = true;
      _running = false;
    });

    final result = await ProgressService.instance.completeExerciseSession(
      widget.slotIndex,
    );
    if (!mounted) return;
    setState(() {
      _pointAwarded = result.pointAwarded;
      _completed = true;
      _finishing = false;
      _remaining = 0;
    });
  }

  String _clock(int seconds) {
    final safe = seconds.clamp(0, 9999);
    final minutes = safe ~/ 60;
    final secs = safe % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit() async {
    if (_completed || (!_running && _index == 0 && _remaining == _step.seconds)) {
      return true;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng buổi tập?'),
        content: const Text('Tiến độ chưa hoàn thành sẽ không được cộng điểm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _completed,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.slotTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _completed
                ? _CompletionView(
                    pointAwarded: _pointAwarded,
                    onDone: () => Navigator.of(context).pop(true),
                  )
                : _WorkoutView(
                    key: ValueKey(_index),
                    step: _step,
                    stepRemaining: _remaining,
                    totalRemaining: _totalRemaining,
                    progress: _progress,
                    running: _running,
                    onToggle: _finishing ? null : _toggleTimer,
                    clock: _clock,
                  ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutView extends StatelessWidget {
  const _WorkoutView({
    super.key,
    required this.step,
    required this.stepRemaining,
    required this.totalRemaining,
    required this.progress,
    required this.running,
    required this.onToggle,
    required this.clock,
  });

  final ExerciseStep step;
  final int stepRemaining;
  final int totalRemaining;
  final double progress;
  final bool running;
  final VoidCallback? onToggle;
  final String Function(int) clock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                clock(totalRemaining),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.phase,
            style: TextStyle(
              color: step.isRest ? AppColors.success : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: step.isRest ? 0.38 : 1,
                  child: Image.asset(
                    step.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.fitness_center_rounded,
                      size: 120,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            clock(stepRemaining),
            style: TextStyle(
              color: step.isRest ? AppColors.success : AppColors.onPrimary,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onToggle,
              icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(running ? 'TẠM DỪNG' : 'BẮT ĐẦU'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.pointAwarded,
    required this.onDone,
  });

  final bool pointAwarded;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'HOÀN THÀNH\nXUẤT SẮC!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pointAwarded ? '+1 ĐIỂM' : 'ĐÃ GHI NHẬN',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'XONG',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
