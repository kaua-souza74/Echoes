import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../art/game_assets.dart';
import '../camera/camera_controller.dart';

class RuinsLevel extends Component {
  RuinsLevel(this.assets, this.rig) : super(priority: 0);
  final GameAssets assets;
  final FollowCamera rig;
  final List<(Sprite, Vector2, double, double)> _tiles = [];

  @override
  Future<void> onLoad() async {
    for (final block in assets.level.solids) {
      final columns = (block.width / 32).ceil(),
          rows = (block.height / 32).ceil();
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          final id = row == 0
              ? 8 + col % 8
              : row == rows - 1
              ? 16 + (col + row) % 8
              : (col % 4 == 0 ? 24 + (col % 8) : (col + row) % 8);
          _tiles.add((
            assets.tile(id),
            Vector2(block.x + col * 32, block.y + row * 32),
            math.min(32.0, block.width - col * 32),
            math.min(32.0, block.height - row * 32),
          ));
        }
      }
    }
    for (final block in assets.level.solids) {
      // A decorative column is explicitly non-solid and sits behind the player.
      if (block.width < 160) {
        continue;
      }
      await add(
        SpriteComponent(
          sprite: Sprite(assets.image('props/carved_column.png')),
          position: Vector2(block.right - 35, block.y),
          size: Vector2(64, 96),
          anchor: Anchor.bottomCenter,
          paint: GameAssets.pixelPaint(.42),
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = GameAssets.pixelPaint();
    for (final (sprite, pos, width, height) in _tiles) {
      if (pos.x + 32 < rig.left ||
          pos.x > rig.left + rig.viewWidth ||
          pos.y + 32 < rig.top ||
          pos.y > rig.top + rig.viewHeight) {
        continue;
      }
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(pos.x, pos.y, width, height));
      sprite.render(
        canvas,
        position: pos,
        size: Vector2.all(32),
        overridePaint: paint,
      );
      canvas.restore();
    }
  }
}
