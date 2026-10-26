import 'dart:ui';
import 'package:flame/components.dart';
import '../systems/temporary_platforms.dart';
import '../art/game_assets.dart';
import '../camera/camera_controller.dart';

class TemporaryPlatformView extends Component {
  TemporaryPlatformView(this.assets, this.platforms, this.rig);
  final GameAssets assets;
  final TemporaryPlatforms platforms;
  final FollowCamera rig;
  late Sprite tile;
  @override
  Future<void> onLoad() async {
    tile = assets.tile(32);
  }

  @override
  void render(Canvas canvas) {
    final paint = GameAssets.pixelPaint();
    for (final state in platforms.states) {
      final s = state.spec;
      if (!state.active ||
          s.right < rig.left ||
          s.x > rig.left + 640 ||
          s.bottom < rig.top ||
          s.y > rig.top + 360) {
        continue;
      }
      paint.color = Color.fromRGBO(
        255,
        255,
        255,
        state.armed ? .55 + .4 * (1 - state.age / s.breakAfter) : 1,
      );
      for (var x = s.x; x < s.right; x += 32) {
        tile.render(
          canvas,
          position: Vector2(x, s.y),
          size: Vector2(32, s.height),
          overridePaint: paint,
        );
      }
      final crack = Paint()
        ..color = (state.armed
            ? const Color(0xffe4c28a)
            : const Color(0xff91bcc6))
        ..isAntiAlias = false;
      canvas.drawLine(Offset(s.x, s.y + 2), Offset(s.right, s.y + 2), crack);
      for (var x = s.x + 20; x < s.right; x += 32) {
        canvas.drawLine(
          Offset(x, s.y + 7),
          Offset(x - 6, s.y + s.height - 4),
          crack,
        );
      }
    }
  }
}
