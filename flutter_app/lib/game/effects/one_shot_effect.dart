import 'package:flame/components.dart';
import '../art/game_assets.dart';

class OneShotEffect extends SpriteAnimationComponent {
  OneShotEffect(
    GameAssets assets,
    String name, {
    required double x,
    required double y,
    int facing = 1,
  }) : super(
         animation: assets.animation(name, loop: false),
         size: Vector2(
           GameAssets.strips[name]!.width,
           GameAssets.strips[name]!.height,
         ),
         position: Vector2(x, y),
         anchor: Anchor.center,
         scale: Vector2(facing.toDouble(), 1),
         priority: 18,
         removeOnFinish: true,
         paint: GameAssets.pixelPaint(.8),
       );
}
