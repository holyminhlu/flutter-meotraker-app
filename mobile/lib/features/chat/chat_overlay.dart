import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/core/time/exercise_fab_schedule.dart';
import 'package:meo_traker/data/services/chat_api.dart';
import 'package:meo_traker/features/chat/widgets/ai_chat_fab.dart';
import 'package:meo_traker/features/chat/widgets/exercise_quick_sheet.dart';
import 'package:meo_traker/features/chat/widgets/exercise_fab_badge.dart';

/// Kích thước cụm nút nổi (vận động + AI).
class _FloatingFabMetrics {
  _FloatingFabMetrics._();

  static const exerciseBadgeSize = 40.0;
  static const gap = 6.0;
  /// Khoảng cách tối thiểu giữa đáy cụm và thanh menu dưới.
  static const menuClearance = 12.0;

  static double stackWidth(double fabSize) =>
      exerciseBadgeSize + gap + fabSize;

  /// Chiều cao cụm = nút cao nhất (thường là nút AI).
  static double stackHeight(double fabSize) => fabSize;
}

/// Bong bóng chat AI kéo thả + panel trò chuyện.
class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key, this.onOpenChallenges});

  /// Chuyển sang tab Thử thách (ghi nhận vận động).
  final VoidCallback? onOpenChallenges;

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  static const _fabSize = 52.0;

  Offset? _position;
  bool _panelOpen = false;
  bool _loadingGreeting = false;
  bool _sending = false;
  String? _hint;
  String? _error;

  final _messages = <ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGreeting());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGreeting() async {
    if (_loadingGreeting) return;
    setState(() {
      _loadingGreeting = true;
      _error = null;
    });
    try {
      final text = await ChatApi.fetchGreeting();
      if (!mounted) return;
      setState(() {
        _hint = text;
        _loadingGreeting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hint = 'Xin chào! Mình là Meo AI — hỏi mình về dinh dưỡng nhé 🐱';
        _loadingGreeting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _togglePanel() {
    final opening = !_panelOpen;
    setState(() => _panelOpen = opening);
    if (opening) {
      if (_messages.isEmpty && _hint != null) {
        _messages.add(ChatMessage(role: 'assistant', content: _hint!));
      } else if (_messages.isEmpty && _hint == null && !_loadingGreeting) {
        _loadGreeting().then((_) {
          if (!mounted || !_panelOpen || _messages.isNotEmpty) return;
          if (_hint != null) {
            setState(() {
              _messages.add(ChatMessage(role: 'assistant', content: _hint!));
            });
          }
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _sending = true;
      _error = null;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final reply = await ChatApi.send(messages: List.from(_messages));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }

        final stackW = _FloatingFabMetrics.stackWidth(_fabSize);
        final stackH = _FloatingFabMetrics.stackHeight(_fabSize);
        final menuGap = _FloatingFabMetrics.menuClearance;
        final minTop = padding.top + 8;
        final minLeft = 8.0;
        // Dùng constraints của body (không phải full màn hình) để không bị đẩy xuống dưới menu.
        final maxTop = math.max(minTop, h - stackH - menuGap);
        final maxLeft = math.max(minLeft, w - stackW - 8);
        final defaultPos = Offset(maxLeft, maxTop);
        final raw = _position ?? defaultPos;
        final clampedX = raw.dx.clamp(minLeft, maxLeft);
        final clampedY = raw.dy.clamp(minTop, maxTop);
        final panelHeight = (h * 0.82).clamp(280.0, h - 24);

        return ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_panelOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _panelOpen = false),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  height: panelHeight,
                  child: _ChatPanel(
                    height: panelHeight,
                    messages: _messages,
                    sending: _sending,
                    error: _error,
                    inputCtrl: _inputCtrl,
                    scrollCtrl: _scrollCtrl,
                    onClose: () => setState(() => _panelOpen = false),
                    onSend: _send,
                    onRefreshGreeting: _loadGreeting,
                  ),
                ),
              ],
              if (!_panelOpen)
                Positioned.fill(
                  child: _DraggableFabLayer(
                    position: Offset(clampedX, clampedY),
                    fabSize: _fabSize,
                    onOpenChallenges: widget.onOpenChallenges,
                    bounds: Rect.fromLTWH(
                      minLeft,
                      minTop,
                      maxLeft,
                      maxTop,
                    ),
                    onMoved: (next) => setState(() => _position = next),
                    onTap: _togglePanel,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableFabLayer extends StatefulWidget {
  const _DraggableFabLayer({
    required this.position,
    required this.fabSize,
    required this.bounds,
    required this.onMoved,
    required this.onTap,
    this.onOpenChallenges,
  });

  final Offset position;
  final double fabSize;
  final Rect bounds;
  final ValueChanged<Offset> onMoved;
  final VoidCallback onTap;
  final VoidCallback? onOpenChallenges;

  @override
  State<_DraggableFabLayer> createState() => _DraggableFabLayerState();
}

class _DraggableFabLayerState extends State<_DraggableFabLayer> {
  Offset _dragDelta = Offset.zero;
  bool _exerciseActive = ExerciseFabSchedule.isActive();
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = ExerciseFabSchedule.isActive();
      if (next != _exerciseActive && mounted) {
        setState(() => _exerciseActive = next);
      }
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  void _onExerciseTap() {
    ExerciseQuickSheet.show(
      context,
      onOpenChallenges: widget.onOpenChallenges,
    );
  }

  Offset _clamp(Offset p) {
    return Offset(
      p.dx.clamp(widget.bounds.left, widget.bounds.right),
      p.dy.clamp(widget.bounds.top, widget.bounds.bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.position;
    final visual = _clamp(base + _dragDelta);
    final translate = visual - base;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: base.dx,
          top: base.dy,
          child: Transform.translate(
            offset: translate,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                setState(() => _dragDelta += d.delta);
              },
              onPanEnd: (_) {
                widget.onMoved(visual);
                setState(() => _dragDelta = Offset.zero);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExerciseFabBadge(
                    size: _FloatingFabMetrics.exerciseBadgeSize,
                    highlighted: _exerciseActive,
                    onTap: _onExerciseTap,
                  ),
                  const SizedBox(width: _FloatingFabMetrics.gap),
                  AiChatFab(
                    size: widget.fabSize,
                    onTap: widget.onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.height,
    required this.messages,
    required this.sending,
    required this.error,
    required this.inputCtrl,
    required this.scrollCtrl,
    required this.onClose,
    required this.onSend,
    required this.onRefreshGreeting,
  });

  final double height;
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
  final TextEditingController inputCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onClose;
  final VoidCallback onSend;
  final VoidCallback onRefreshGreeting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 12,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            _buildHeader(context),
            Divider(height: 1, color: AppColors.border),
            _buildMessages(context),
            if (error != null) _buildError(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFAD21), Color(0xFFFFD60F)],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFEA50),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meo AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Dinh dưỡng · động viên · nhắc nhở',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Làm mới gợi ý',
            onPressed: onRefreshGreeting,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: messages.length + (sending ? 1 : 0),
        itemBuilder: (context, i) {
          if (sending && i == messages.length) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final m = messages[i];
          final isUser = m.role == 'user';
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                m.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        error!,
        style: TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: inputCtrl,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Hỏi Meo AI...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: sending ? null : onSend,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.send_rounded, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
