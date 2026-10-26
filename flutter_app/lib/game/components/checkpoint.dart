import 'package:flame/components.dart';
import '../art/game_assets.dart';

class CheckpointBeacon extends PositionComponent {
  CheckpointBeacon(
    this.assets, {
    required double x,
    required double y,
    required this.label,
    required this.order,
    this.isGoal = false,
  }) : super(position: Vector2(x, y), priority: 10);
  final GameAssets assets;
  final String label;
  final int order;
  final bool isGoal;
  late SpriteAnimationComponent lamp, glow;

  @override
  Future<void> onLoad() async {
    glow = SpriteAnimationComponent(
      animation: assets.animation('glow'),
      size: Vector2.all(96),
      position: Vector2(0, -36),
      anchor: Anchor.center,
      paint: GameAssets.pixelPaint(.28),
    );
    lamp = SpriteAnimationComponent(
      animation: assets.animation('checkpoint'),
      size: Vector2(48, 64),
      anchor: Anchor(0.5, 61 / 64),
      paint: GameAssets.pixelPaint(.5),
    );
    await addAll([glow, lamp]);
  }

  void illuminate(bool active) {
    lamp.opacity = active ? 1 : 0.5;
    glow.opacity = active ? 0.75 : 0.20;
  }
}
