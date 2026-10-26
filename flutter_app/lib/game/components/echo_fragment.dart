import 'package:flame/components.dart';
import '../art/game_assets.dart';

class EchoFragment extends SpriteAnimationComponent with HasVisibility {
  EchoFragment(GameAssets assets, {required double x, required double y})
    : super(
        animation: assets.animation('echo'),
        size: Vector2.all(32),
        position: Vector2(x, y),
        anchor: Anchor.center,
        priority: 12,
        paint: GameAssets.pixelPaint(),
      );
}
