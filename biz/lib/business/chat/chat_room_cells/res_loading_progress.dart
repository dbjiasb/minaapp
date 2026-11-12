import 'dart:async';
import 'dart:math' as math;

import 'package:biz/shared/app_theme.dart';
import 'package:flutter/material.dart';

class ResLoadingProgress extends StatefulWidget {
  final DateTime startTime;
  final int estimatedSeconds;

  const ResLoadingProgress({
    super.key,
    required this.startTime,
    required this.estimatedSeconds,
  }) : assert(estimatedSeconds > 0);

  @override
  State<ResLoadingProgress> createState() => _ResLoadingProgressState();
}

class _ResLoadingProgressState extends State<ResLoadingProgress> {
  static const _maxProgress = 0.99;
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startUpdates();
  }

  @override
  void didUpdateWidget(covariant ResLoadingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime ||
        oldWidget.estimatedSeconds != widget.estimatedSeconds) {
      _startUpdates();
    }
  }

  void _startUpdates() {
    _timer?.cancel();
    _progress = _calculateProgress();
    if (_progress < _maxProgress) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        final progress = math.max(_progress, _calculateProgress());
        if (progress != _progress) setState(() => _progress = progress);
        if (progress >= _maxProgress) timer.cancel();
      });
    }
  }

  double _calculateProgress() {
    final elapsedMs = DateTime.now()
        .difference(widget.startTime)
        .inMilliseconds;
    final fraction = (elapsedMs / (widget.estimatedSeconds * 1000)).clamp(
      0.0,
      1.0,
    );
    final remaining = 1 - fraction;
    return math.min(1 - remaining * remaining * remaining, _maxProgress);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = '${(_progress * 100).floor()}%';
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 60,
          child: CircularProgressIndicator(
            value: _progress,
            color: AppColors.primary,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            strokeWidth: 4,
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
