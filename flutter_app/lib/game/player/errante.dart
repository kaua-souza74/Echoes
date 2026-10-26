import 'package:flame/components.dart';
import '../art/game_assets.dart';
import 'player_state.dart';

class Errante extends PositionComponent {
  Errante(this.assets) : super(priority: 20);
  final GameAssets assets;
  late SpriteAnimationComponent visual;
  final Map<PlayerPose, SpriteAnimation> animations = {};
  PlayerPose _pose = PlayerPose.idle;

  @override
  Future<void> onLoad() async {
    for (final pose in PlayerPose.values) {
      animations[pose] = assets.animation(
        pose == PlayerPose.wallSlide ? 'wall_slide' : pose.name,
      );
    }
    visual = SpriteAnimationComponent(
      animation: animations[_pose],
      size: Vector2.all(48),
      anchor: Anchor(24 / 48, 44 / 48),
      paint: GameAssets.pixelPaint(),
    );
    await add(visual);
  }

  void sync(PlayerState body, PlayerPose nextPose) {
    position.setValues(body.x.roundToDouble(), body.y.roundToDouble());
    visual.scale.x = body.facing.toDouble();
    if (_pose != nextPose) {
      _pose = nextPose;
      visual.animation = animations[nextPose];
    }
  }
}
