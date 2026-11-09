import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../levels/level_data.dart';

class BreakableObstacle extends PositionComponent {
  BreakableObstacle(this.spec, {required this.onDestroyed})
    : _hitsRemaining = spec.hits,
      super(
        position: Vector2(spec.x, spec.y),
        size: Vector2(spec.width, spec.height),
        priority: 15,
      );

  final BreakableSpec spec;
  final void Function() onDestroyed;
  int _hitsRemaining;
  double _clock = 0, _flash = 0, _breakTime = 0;
  bool _breaking = false;

  bool get destroyed => _breaking;

  bool strike() {
    if (_breaking) return false;
    _hitsRemaining--;
    _flash = .18;
    if (_hitsRemaining <= 0) {
      _breaking = true;
      _breakTime = 0;
      onDestroyed();
    }
    return true;
  }

  void restore() {
    _hitsRemaining = spec.hits;
    _flash = _breakTime = 0;
    _breaking = false;
  }

  @override
  void update(double dt) {
    _clock += dt;
    _flash = math.max(0.0, _flash - dt);
    if (_breaking) _breakTime += dt;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (_breaking) {
      _renderFragments(canvas);
      return;
    }
    final palette = _palette;
    final width = size.x;
    final height = size.y;
    final shake = _flash > 0 ? math.sin(_clock * 110) * 1.5 : 0.0;
    canvas.save();
    canvas.translate(shake, 0);

    final outline = Paint()
      ..color = palette.outline
      ..isAntiAlias = false;
    final body = Paint()
      ..color = _flash > 0 ? const Color(0xffe8ffff) : palette.body
      ..isAntiAlias = false;
    final path = Path()
      ..moveTo(6, 0)
      ..lineTo(width - 11, 0)
      ..lineTo(width - 11, 4)
      ..lineTo(width - 5, 4)
      ..lineTo(width - 5, 10)
      ..lineTo(width, 10)
      ..lineTo(width, height - 6)
      ..lineTo(width - 7, height - 6)
      ..lineTo(width - 7, height)
      ..lineTo(4, height)
      ..lineTo(4, height - 7)
      ..lineTo(0, height - 7)
      ..lineTo(0, 8)
      ..lineTo(6, 8)
      ..close();
    canvas.drawPath(path, outline);
    canvas.drawRect(Rect.fromLTWH(4, 5, width - 11, height - 11), body);
    _drawMaterial(canvas, palette, width, height);
    _drawCore(canvas, palette, width, height);
    if (_hitsRemaining < spec.hits) _drawCracks(canvas, palette, width, height);
    canvas.restore();
  }

  _ObstaclePalette get _palette => switch (spec.material) {
    'sandstone' => const _ObstaclePalette(
      outline: Color(0xff49362d),
      body: Color(0xffa87548),
      shade: Color(0xff754b37),
      light: Color(0xffd3a36c),
      accent: Color(0xfff0c47c),
    ),
    'heartwood' => const _ObstaclePalette(
      outline: Color(0xff182a25),
      body: Color(0xff43563f),
      shade: Color(0xff263a32),
      light: Color(0xff778653),
      accent: Color(0xffe8bd72),
    ),
    _ => const _ObstaclePalette(
      outline: Color(0xff111d29),
      body: Color(0xff425968),
      shade: Color(0xff293d4a),
      light: Color(0xff708b92),
      accent: Color(0xff84d9e8),
    ),
  };

  void _drawMaterial(
    Canvas canvas,
    _ObstaclePalette palette,
    double width,
    double height,
  ) {
    final shade = Paint()
      ..color = palette.shade
      ..isAntiAlias = false;
    final light = Paint()
      ..color = palette.light
      ..isAntiAlias = false;
    final baseY = height * .64;

    canvas.drawRect(Rect.fromLTWH(5, 7, width - 14, 3), light);
    canvas.drawRect(Rect.fromLTWH(5, height - 13, width - 10, 4), shade);
    if (spec.material == 'sandstone') {
      canvas.drawRect(Rect.fromLTWH(7, height * .34, width - 14, 3), shade);
      canvas.drawRect(Rect.fromLTWH(7, height * .38, width - 14, 2), light);
      canvas.drawRect(Rect.fromLTWH(8, height * .72, width - 15, 2), light);
      canvas.drawRect(Rect.fromLTWH(12, 16, 4, 2), shade);
      canvas.drawRect(Rect.fromLTWH(width - 16, 23, 3, 2), light);
    } else if (spec.material == 'heartwood') {
      canvas.drawRect(Rect.fromLTWH(8, 10, 5, height - 23), shade);
      canvas.drawRect(Rect.fromLTWH(13, 18, 4, 3), light);
      canvas.drawRect(Rect.fromLTWH(width - 14, 8, 5, height - 21), shade);
      canvas.drawRect(Rect.fromLTWH(width - 18, baseY, 4, 3), light);
      canvas.drawRect(Rect.fromLTWH(9, height * .48, width - 18, 4), shade);
      canvas.drawRect(Rect.fromLTWH(17, height * .52, width - 25, 2), light);
    } else {
      canvas.drawRect(Rect.fromLTWH(7, height * .35, width - 14, 3), shade);
      canvas.drawRect(Rect.fromLTWH(10, height * .74, width - 19, 3), light);
      canvas.drawRect(Rect.fromLTWH(8, 16, 4, 4), shade);
      canvas.drawRect(Rect.fromLTWH(width - 15, 21, 4, 4), shade);
    }
  }

  void _drawCore(
    Canvas canvas,
    _ObstaclePalette palette,
    double width,
    double height,
  ) {
    final cx = width * .5;
    final cy = height * .47;
    final radius = spec.material == 'heartwood' ? 8.0 : 6.0;
    final diamond = Path()
      ..moveTo(cx, cy - radius)
      ..lineTo(cx + radius, cy)
      ..lineTo(cx, cy + radius)
      ..lineTo(cx - radius, cy)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = palette.accent.withAlpha(54)
        ..isAntiAlias = false,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 1.5, cy - 4, 3, 8),
      Paint()
        ..color = palette.accent.withAlpha(170)
        ..isAntiAlias = false,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 5, cy - 1.5, 10, 3),
      Paint()
        ..color = palette.accent.withAlpha(170)
        ..isAntiAlias = false,
    );
  }

  void _drawCracks(
    Canvas canvas,
    _ObstaclePalette palette,
    double width,
    double height,
  ) {
    final crack = Paint()
      ..color = const Color(0xff101923)
      ..isAntiAlias = false;
    final glint = Paint()
      ..color = palette.accent.withAlpha(190)
      ..isAntiAlias = false;
    final cx = width * .5;
    final cy = height * .46;
    canvas.drawRect(Rect.fromLTWH(cx - 1, cy - 12, 2, 8), crack);
    canvas.drawRect(Rect.fromLTWH(cx - 5, cy - 5, 4, 2), crack);
    canvas.drawRect(Rect.fromLTWH(cx - 1, cy - 4, 2, 9), crack);
    canvas.drawRect(Rect.fromLTWH(cx + 1, cy + 3, 6, 2), crack);
    canvas.drawRect(Rect.fromLTWH(cx + 6, cy + 5, 2, 9), crack);
    canvas.drawRect(Rect.fromLTWH(cx - 3, cy + 5, 3, 2), glint);
  }

  void _renderFragments(Canvas canvas) {
    if (_breakTime >= .34) return;
    final progress = (_breakTime / .34).clamp(0.0, 1.0).toDouble();
    final colors = [
      _palette.body,
      _palette.shade,
      _palette.light,
      _palette.accent,
    ];
    final fragmentPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(
        0xffffffff,
      ).withAlpha(((1 - progress) * 235).round());
    for (var i = 0; i < 10; i++) {
      final column = i % 4;
      final row = i ~/ 4;
      final originX = 5.0 + column * (size.x - 12) / 4;
      final originY = 6.0 + row * (size.y - 12) / 3;
      final direction = column < 2 ? -1.0 : 1.0;
      final x = originX + direction * (12 + row * 3) * progress;
      final y =
          originY - (7 + (i % 3) * 4) * progress + 90 * progress * progress;
      fragmentPaint.color = colors[i % colors.length].withAlpha(
        ((1 - progress) * 235).round(),
      );
      final side = i % 3 == 0 ? 5.0 : 3.0;
      canvas.drawRect(Rect.fromLTWH(x, y, side, side), fragmentPaint);
    }
  }
}

class AttackArc extends PositionComponent {
  AttackArc({
    required double x,
    required double y,
    required this.facing,
    required this.accent,
  }) : super(
         position: Vector2(x - 28, y - 49),
         size: Vector2(56, 48),
         priority: 30,
       );

  final int facing;
  final Color accent;
  double _age = 0;
  static const _duration = .18;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _duration) removeFromParent();
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _duration).clamp(0.0, 1.0).toDouble();
    final alpha = ((1 - progress) * 220).round();
    final pixel = Paint()
      ..color = accent.withAlpha(alpha)
      ..isAntiAlias = false;
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      final x = facing > 0 ? 13 + t * 34 : 43 - t * 34;
      final y = 33 - math.sin(t * math.pi) * 24 + progress * 5;
      final side = i.isEven ? 4.0 : 3.0;
      canvas.drawRect(Rect.fromLTWH(x, y, side, side), pixel);
    }
    final tipX = facing > 0 ? 48.0 : 8.0;
    canvas.drawRect(
      Rect.fromLTWH(tipX, 18 + progress * 5, 4, 2),
      Paint()
        ..color = const Color(0xffefffff).withAlpha(alpha)
        ..isAntiAlias = false,
    );
  }
}

class _ObstaclePalette {
  const _ObstaclePalette({
    required this.outline,
    required this.body,
    required this.shade,
    required this.light,
    required this.accent,
  });
  final Color outline, body, shade, light, accent;
}
