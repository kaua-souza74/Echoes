import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PixelWorldTransitionMode { revealWorld, coverWorld }

/// A pixel-grid curtain used when crossing the threshold into or out of a
/// chapter. Each square dissolves on a slightly different part of the wave.
class PixelWorldTransition extends StatefulWidget {
  const PixelWorldTransition({
    required this.mode,
    required this.color,
    required this.duration,
    required this.playing,
    this.onCompleted,
    super.key,
  });

  final PixelWorldTransitionMode mode;
  final Color color;
  final Duration duration;
  final bool playing;
  final VoidCallback? onCompleted;

  @override
  State<PixelWorldTransition> createState() => _PixelWorldTransitionState();
}

class _PixelWorldTransitionState extends State<PixelWorldTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_statusChanged);
    if (widget.playing) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PixelWorldTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!oldWidget.playing && widget.playing) {
      _didComplete = false;
      _controller.forward(from: 0);
    }
  }

  void _statusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_didComplete) {
      _didComplete = true;
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_statusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing:
        widget.mode == PixelWorldTransitionMode.revealWorld || widget.playing,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _PixelCurtainPainter(
          progress: widget.playing ? _controller.value : 0,
          color: widget.color,
          mode: widget.mode,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PixelCurtainPainter extends CustomPainter {
  const _PixelCurtainPainter({
    required this.progress,
    required this.color,
    required this.mode,
  });

  final double progress;
  final Color color;
  final PixelWorldTransitionMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 22.0;
    final columns = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final maxDistance = math.sqrt(.5 * .5 + .5 * .5);
    final cover = mode == PixelWorldTransitionMode.coverWorld;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final x = column * cell;
        final y = row * cell;
        final centerX = (x + cell * .5) / size.width;
        final centerY = (y + cell * .5) / size.height;
        final distance = math.sqrt(
          math.pow(centerX - .5, 2) + math.pow(centerY - .5, 2),
        );
        final noise =
            ((row * 47 + column * 71 + row * column * 13) % 101) / 100;
        final threshold = ((distance / maxDistance + noise * .2) / 1.2).clamp(
          0.0,
          1.0,
        );
        final local = ((progress - threshold) / .19).clamp(0.0, 1.0);
        final alpha = cover ? local : 1 - local;
        if (alpha <= 0) continue;
        paint.color = color.withAlpha((alpha * 255).round());
        canvas.drawRect(Rect.fromLTWH(x, y, cell + .6, cell + .6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelCurtainPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.mode != mode;
}
