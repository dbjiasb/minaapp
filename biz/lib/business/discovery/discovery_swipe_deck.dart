import 'package:flutter/material.dart';

import '../../shared/app_theme.dart';

/// A horizontal card deck. A decision must succeed before the next card opens.
class DiscoverySwipeDeck extends StatefulWidget {
  const DiscoverySwipeDeck({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onDecision,
    required this.onChat,
    required this.onIndexChanged,
    required this.exhaustedBuilder,
    required this.chatLabel,
    required this.likeLabel,
    required this.dislikeLabel,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<bool> Function(int index, bool liked) onDecision;
  final ValueChanged<int> onChat;
  final ValueChanged<int> onIndexChanged;
  final WidgetBuilder exhaustedBuilder;
  final String chatLabel;
  final String likeLabel;
  final String dislikeLabel;

  @override
  State<DiscoverySwipeDeck> createState() => _DiscoverySwipeDeckState();
}

class _DiscoverySwipeDeckState extends State<DiscoverySwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
      )..addListener(() {
        setState(() => _offset = _motion.value);
      });
  Animation<Offset> _motion = const AlwaysStoppedAnimation(Offset.zero);
  Offset _offset = Offset.zero;
  double _width = 1;
  int _index = 0;
  bool _busy = false;

  Future<void> _animateTo(Offset end) async {
    _motion = Tween(
      begin: _offset,
      end: end,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    await _animation.forward(from: 0).orCancel;
  }

  Future<void> _decide(bool liked) async {
    if (_busy || _index >= widget.itemCount) return;
    setState(() => _busy = true);
    try {
      // Start the request and animation together; reject double taps meanwhile.
      final decision = _submitDecision(liked);
      await _animateTo(Offset((liked ? 1 : -1) * (_width + 80), 0));
      final accepted = await decision;
      if (!mounted) return;
      if (accepted) {
        setState(() {
          _index++;
          _offset = Offset.zero;
          _busy = false;
        });
        widget.onIndexChanged(_index);
      } else {
        await _animateTo(Offset.zero);
        if (mounted) setState(() => _busy = false);
      }
    } on TickerCanceled {
      // The deck was disposed while a card was moving.
    }
  }

  Future<bool> _submitDecision(bool liked) async {
    try {
      return await widget.onDecision(_index, liked);
    } catch (_) {
      return false;
    }
  }

  Future<void> _endDrag(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final farEnough = _offset.dx.abs() >= _width * 0.25;
    final fastEnough = velocity.abs() >= 900 && _offset.dx.abs() >= 24;
    if (farEnough || fastEnough) {
      await _decide(farEnough ? _offset.dx > 0 : velocity > 0);
    } else {
      await _returnToCenter();
    }
  }

  Future<void> _returnToCenter() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _animateTo(Offset.zero);
      if (mounted) setState(() => _busy = false);
    } on TickerCanceled {
      // The deck was disposed while returning to center.
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.itemCount) return widget.exhaustedBuilder(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _width = constraints.maxWidth;
                final progress = (_offset.dx.abs() / (_width * .25)).clamp(
                  0.0,
                  1.0,
                );
                return Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    if (_index + 1 < widget.itemCount)
                      Transform.translate(
                        offset: const Offset(0, 6),
                        child: Transform.scale(
                          scale: .97,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: _offset,
                      child: Transform.rotate(
                        angle: (_offset.dx / _width).clamp(-1.0, 1.0) * .16,
                        child: GestureDetector(
                          key: const ValueKey('discovery-swipe-card'),
                          onHorizontalDragStart: _busy
                              ? null
                              : (_) => _animation.stop(),
                          onHorizontalDragUpdate: _busy
                              ? null
                              : (details) {
                                  setState(
                                    () =>
                                        _offset += Offset(details.delta.dx, 0),
                                  );
                                },
                          onHorizontalDragEnd: _busy ? null : _endDrag,
                          onHorizontalDragCancel: _busy
                              ? null
                              : _returnToCenter,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                KeyedSubtree(
                                  key: ValueKey(_index),
                                  child: AbsorbPointer(
                                    absorbing: _busy,
                                    child: widget.itemBuilder(context, _index),
                                  ),
                                ),
                                if (progress > 0)
                                  Positioned(
                                    top: 28,
                                    left: _offset.dx > 0 ? 20 : null,
                                    right: _offset.dx < 0 ? 20 : null,
                                    child: IgnorePointer(
                                      child: Opacity(
                                        opacity: progress,
                                        child: _decisionStamp(_offset.dx > 0),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_busy)
                      const IgnorePointer(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentText,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _decisionButton(false),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('discovery-chat'),
                    onPressed: _busy ? null : () => widget.onChat(_index),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.accentForeground,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 24,
                    ),
                    label: Text(
                      widget.chatLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _decisionButton(true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decisionButton(bool liked) => SizedBox(
    width: 56,
    height: 56,
    child: IconButton.filled(
      key: ValueKey(liked ? 'discovery-like' : 'discovery-dislike'),
      tooltip: liked ? widget.likeLabel : widget.dislikeLabel,
      onPressed: _busy ? null : () => _decide(liked),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: liked ? AppColors.rose : AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.close_rounded,
        size: 28,
      ),
    ),
  );

  Widget _decisionStamp(bool liked) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(
        color: liked ? AppColors.rose : AppColors.textSecondary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          liked ? Icons.favorite_rounded : Icons.close_rounded,
          color: liked ? AppColors.rose : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          liked ? widget.likeLabel : widget.dislikeLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
