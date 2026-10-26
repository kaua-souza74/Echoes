import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../art/game_assets.dart';
import 'camera_controller.dart';

/// Camera-displacement based layers, independent of frame rate and direction.
/// Mirrored repetition joins identical border pixels without uncovered gaps.
class ParallaxBackdrop extends Component {
  ParallaxBackdrop(this.assets, this.rig);
  final GameAssets assets;
  final FollowCamera rig;
  double _ambientTime = 0;
  final Map<String, double> eventAges = {};
  void trigger(String id) {
    eventAges.putIfAbsent(id, () => 0);
  }

  void resetEvents() {
    eventAges.clear();
  }

  @override
  void update(double dt) {
    _ambientTime += dt;
    eventAges.updateAll((key, value) => value + dt);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final paint = GameAssets.pixelPaint();
    for (final layer in assets.level.layers) {
      final image = assets.image(layer.asset);
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      final shift = rig.left * layer.factor;
      final shiftY = rig.top * layer.factorY;
      final start = (shift / width).floor();
      final startY = (shiftY / height).floor();
      for (var j = startY; j <= startY + 1; j++) {
        for (var i = start; i <= start + 2; i++) {
          final x = (i * width - shift).roundToDouble();
          final y = (j * height - shiftY).roundToDouble();
          canvas.save();
          canvas.translate(
            x + (i.isOdd ? width : 0),
            y + (j.isOdd ? height : 0),
          );
          canvas.scale(i.isOdd ? -1 : 1, j.isOdd ? -1 : 1);
          canvas.drawImage(image, Offset.zero, paint);
          canvas.restore();
        }
      }
    }
    _drawAmbientLife(canvas, paint);
    for (final event in assets.level.ambientEvents) {
      final age = eventAges[event.id];
      if (age == null || age > event.duration) continue;
      final t = age / event.duration;
      final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
      if (event.kind == 'crossing') {
        final spec = GameAssets.strips[event.sprite]!;
        final frame = (age * spec.fps).floor() % spec.frames;
        canvas.drawImageRect(
          assets.image(spec.path),
          Rect.fromLTWH(frame * spec.width, 0, spec.width, spec.height),
          Rect.fromLTWH(
            -spec.width + t * (640 + spec.width),
            68,
            spec.width,
            spec.height,
          ),
          paint..color = Color.fromRGBO(255, 255, 255, alpha * .46),
        );
      } else {
        final ray = Paint()
          ..color = Color.fromRGBO(198, 211, 255, alpha * .10)
          ..isAntiAlias = false;
        for (var x = 80; x < 640; x += 112) {
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), 0, 24, 360), ray);
        }
      }
    }
  }

  void _drawAmbientLife(Canvas canvas, Paint paint) {
    // Small, slow forms live behind the playable plane. Their positions use
    // the same camera displacement as the far architecture, so they recede.
    final time = _ambientTime;
    for (final actor in assets.level.ambientActors) {
      final image = assets.image(GameAssets.strips[actor.sprite]!.path);
      final frameWidth = GameAssets.strips[actor.sprite]!.width;
      final frameHeight = GameAssets.strips[actor.sprite]!.height;
      final frame = (time * GameAssets.strips[actor.sprite]!.fps).floor() % 4;
      final source = Rect.fromLTWH(
        frame * frameWidth,
        0,
        frameWidth,
        frameHeight,
      );
      final shift = rig.left * actor.factor;
      final tile = (shift / 640).floor();
      for (var i = tile; i <= tile + 2; i++) {
        final mirrored = i.isOdd;
        final localX = mirrored ? 640 - actor.x : actor.x;
        final x = (i * 640 + localX - shift).roundToDouble();
        final bob =
            math.sin(
              time * (actor.sprite == 'listener' ? .55 : .9) + actor.x / 100,
            ) *
            2;
        final y = (actor.y + bob).roundToDouble();
        if (x < -frameWidth || x > 640 + frameWidth) continue;
        final destination = Rect.fromLTWH(
          x - frameWidth / 2,
          y - frameHeight / 2,
          frameWidth,
          frameHeight,
        );
        canvas.save();
        if (mirrored) {
          canvas.translate(x + frameWidth / 2, 0);
          canvas.scale(-1, 1);
          canvas.translate(-(x + frameWidth / 2), 0);
        }
        canvas.drawImageRect(
          image,
          source,
          destination,
          paint..color = Color.fromRGBO(255, 255, 255, actor.opacity),
        );
        canvas.restore();
      }
    }

    // A deterministic dust field drifts at two speeds; points remain sparse
    // and subdued enough to preserve platform edges and the player's silhouette.
    final dustPaint = Paint()..isAntiAlias = false;
    for (var i = 0; i < 26; i++) {
      final seed = i * 37.17;
      final speed = i.isEven ? 4.5 : 1.8;
      final x = ((seed + time * speed) % 672) - 16;
      final y = 40 + ((seed * 2.31 + math.sin(time * .22 + i) * 8) % 276);
      final alpha = (24 + 20 * (0.5 + 0.5 * math.sin(time * .6 + i))).round();
      dustPaint.color = Color.fromARGB(alpha, 127, 175, 177);
      canvas.drawRect(
        Rect.fromLTWH(
          x.floorToDouble(),
          y.floorToDouble(),
          i % 7 == 0 ? 2 : 1,
          1,
        ),
        dustPaint,
      );
    }
  }
}
