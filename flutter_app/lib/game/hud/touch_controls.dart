import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../input/game_input.dart';

/// Landscape-first two-thumb controls. The left side is a floating horizontal
/// stick; the right side keeps jump, dash and strike within one thumb's reach.
class TouchControls extends StatelessWidget {
  const TouchControls({required this.input, required this.accent, super.key});

  final GameInput input;
  final Color accent;

  static bool shouldShowFor(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return true;
    }
    return MediaQuery.sizeOf(context).shortestSide < 620;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(12, 0, 14, 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final button = (constraints.maxHeight * .25)
            .clamp(66.0, 88.0)
            .toDouble();
        final dash = button * .78;
        final strike = button * .78;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              width: constraints.maxWidth * .47,
              height: constraints.maxHeight * .66,
              child: _FloatingThumbstick(input: input, accent: accent),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: button + dash + strike + 24,
              height: button + 12,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _HoldRuneButton(
                      label: 'PULAR',
                      icon: Icons.keyboard_arrow_up_rounded,
                      size: button,
                      accent: accent,
                      onChanged: (down) =>
                          input.setTouch(InputAction.jump, down),
                    ),
                  ),
                  Positioned(
                    right: button + 10,
                    bottom: 5,
                    child: _HoldRuneButton(
                      label: 'DASH',
                      icon: Icons.bolt_rounded,
                      size: dash,
                      accent: accent,
                      onChanged: (down) =>
                          input.setTouch(InputAction.dash, down),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 5,
                    child: _HoldRuneButton(
                      label: 'BATER',
                      icon: Icons.sports_martial_arts,
                      size: strike,
                      accent: accent,
                      onChanged: (down) =>
                          input.setTouch(InputAction.attack, down),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _FloatingThumbstick extends StatefulWidget {
  const _FloatingThumbstick({required this.input, required this.accent});
  final GameInput input;
  final Color accent;

  @override
  State<_FloatingThumbstick> createState() => _FloatingThumbstickState();
}

class _FloatingThumbstickState extends State<_FloatingThumbstick> {
  int? _pointer;
  Offset? _anchor, _knob;
  double _axis = 0;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _anchor = event.localPosition;
    _knob = event.localPosition;
    _move(event.localPosition);
  }

  void _move(Offset position) {
    final anchor = _anchor;
    if (anchor == null) return;
    final delta = position - anchor;
    final radius = 54.0;
    final distance = delta.distance;
    _knob = anchor + (distance > radius ? delta * (radius / distance) : delta);
    _axis = (delta.dx / radius).clamp(-1.0, 1.0).toDouble();
    widget.input.setTouch(InputAction.left, _axis < -.24);
    widget.input.setTouch(InputAction.right, _axis > .24);
    setState(() {});
  }

  void _end(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _release();
    setState(() {});
  }

  void _release() {
    _pointer = null;
    _anchor = null;
    _knob = null;
    _axis = 0;
    widget.input.setTouch(InputAction.left, false);
    widget.input.setTouch(InputAction.right, false);
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final idleAnchor = Offset(
        constraints.maxWidth * .43,
        constraints.maxHeight * .68,
      );
      final radius = math.min(54.0, constraints.maxHeight * .30).toDouble();
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: (event) {
          if (event.pointer == _pointer) _move(event.localPosition);
        },
        onPointerUp: _end,
        onPointerCancel: _end,
        child: CustomPaint(
          painter: _ThumbstickPainter(
            anchor: _anchor ?? idleAnchor,
            knob: _knob ?? idleAnchor,
            radius: radius,
            accent: widget.accent,
            active: _pointer != null,
            axis: _axis,
          ),
          child: const SizedBox.expand(),
        ),
      );
    },
  );
}

class _ThumbstickPainter extends CustomPainter {
  const _ThumbstickPainter({
    required this.anchor,
    required this.knob,
    required this.radius,
    required this.accent,
    required this.active,
    required this.axis,
  });

  final Offset anchor, knob;
  final double radius, axis;
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final visibility = active ? 1.0 : .42;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withAlpha((visibility * 100).round());
    final wash = Paint()
      ..color = const Color(0xff0b1722).withAlpha((visibility * 132).round());
    final glow = Paint()
      ..color = accent.withAlpha((visibility * (active ? 78 : 32)).round());
    canvas.drawCircle(anchor, radius, wash);
    canvas.drawCircle(anchor, radius, ring);
    canvas.drawCircle(anchor, radius * .53, ring..strokeWidth = 1);
    canvas.drawLine(
      Offset(anchor.dx - radius * .66, anchor.dy),
      Offset(anchor.dx + radius * .66, anchor.dy),
      ring,
    );
    canvas.drawCircle(knob, radius * .35, glow);
    canvas.drawCircle(
      knob,
      radius * .35,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withAlpha((visibility * 210).round()),
    );
    if (!active) {
      final marker = Paint()
        ..color = accent.withAlpha(110)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(anchor.dx - radius * .68, anchor.dy - radius * .70),
        Offset(anchor.dx - radius * .42, anchor.dy - radius * .70),
        marker,
      );
      canvas.drawLine(
        Offset(anchor.dx + radius * .42, anchor.dy - radius * .70),
        Offset(anchor.dx + radius * .68, anchor.dy - radius * .70),
        marker,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbstickPainter oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.knob != knob ||
      oldDelegate.radius != radius ||
      oldDelegate.accent != accent ||
      oldDelegate.active != active ||
      oldDelegate.axis != axis;
}

class _HoldRuneButton extends StatefulWidget {
  const _HoldRuneButton({
    required this.label,
    required this.icon,
    required this.size,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double size;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  State<_HoldRuneButton> createState() => _HoldRuneButtonState();
}

class _HoldRuneButtonState extends State<_HoldRuneButton> {
  final Set<int> _pointers = {};
  bool get _pressed => _pointers.isNotEmpty;

  void _change(int pointer, bool down) {
    final wasPressed = _pressed;
    setState(() {
      if (down) {
        _pointers.add(pointer);
      } else {
        _pointers.remove(pointer);
      }
    });
    if (wasPressed != _pressed) widget.onChanged(_pressed);
  }

  @override
  void dispose() {
    if (_pressed) widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (widget.label) {
      'PULAR' => 'Pular',
      'DASH' => 'Usar dash',
      _ => 'Bater em obstáculos',
    },
    button: true,
    onTap: () {
      widget.onChanged(true);
      widget.onChanged(false);
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _change(event.pointer, true),
      onPointerUp: (event) => _change(event.pointer, false),
      onPointerCancel: (event) => _change(event.pointer, false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? widget.accent.withAlpha(112)
              : const Color(0xd20b1722),
          border: Border.all(
            color: widget.accent.withAlpha(_pressed ? 235 : 125),
            width: _pressed ? 2.4 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withAlpha(_pressed ? 120 : 32),
              blurRadius: _pressed ? 18 : 8,
              spreadRadius: _pressed ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: const Color(0xffe0f5ef),
              size: widget.size * .42,
            ),
            Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xffd1e3df),
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
