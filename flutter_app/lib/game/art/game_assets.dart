import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../levels/level_data.dart';
import '../levels/stage_registry.dart';

class StripSpec {
  const StripSpec(this.path, this.frames, this.width, this.height, this.fps);
  final String path;
  final int frames;
  final double width, height, fps;
}

class GameAssets {
  GameAssets(this.images);
  final Images images;
  late LevelData level;
  int tileColumns = 8;
  static const strips = <String, StripSpec>{
    'crawler': StripSpec(
      'background_creatures/worlds/crawler.png',
      4,
      80,
      40,
      3,
    ),
    'spirit': StripSpec('background_creatures/worlds/spirit.png', 4, 64, 80, 3),
    'colossus': StripSpec(
      'background_creatures/worlds/colossus.png',
      4,
      320,
      144,
      2,
    ),
    'idle': StripSpec('player/errante_idle.png', 6, 48, 48, 7),
    'run': StripSpec('player/errante_run.png', 8, 48, 48, 12),
    'jump': StripSpec('player/errante_jump.png', 2, 48, 48, 10),
    'fall': StripSpec('player/errante_fall.png', 2, 48, 48, 8),
    'dash': StripSpec('player/errante_dash.png', 4, 48, 48, 16),
    'wall_slide': StripSpec('player/errante_wall_slide.png', 2, 48, 48, 8),
    'checkpoint': StripSpec('props/checkpoint_lume.png', 4, 48, 64, 6),
    'echo': StripSpec('props/echo_fragment.png', 4, 32, 32, 8),
    'trail': StripSpec('effects/dash_trail.png', 5, 64, 32, 18),
    'dust': StripSpec('effects/dust_puff.png', 4, 32, 24, 12),
    'glow': StripSpec('effects/lume_glow.png', 4, 64, 64, 6),
    'collect': StripSpec('effects/echo_collect.png', 5, 64, 64, 18),
    'listener': StripSpec(
      'background_creatures/stage_01/the_listener.png',
      4,
      80,
      64,
      2.5,
    ),
    'moth': StripSpec(
      'background_creatures/stage_01/veil_moth.png',
      4,
      64,
      48,
      4,
    ),
  };

  Future<void> load({bool slice = false, String stageId = 'stage_01'}) async {
    level = slice
        ? LevelData.fromArtJson(
            await rootBundle.loadString(
              'assets/images/levels/stage_01_awakening_layout.json',
            ),
          )
        : LevelData.fromStageJson(
            await rootBundle.loadString(StageRegistry.get(stageId).asset),
          );
    final atlas =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/${level.tileAsset.replaceAll('.png', '.json')}',
              ),
            )
            as Map<String, dynamic>;
    tileColumns = atlas['columns'] as int;
    await images.loadAll([
      ...strips.values.map((s) => s.path),
      ...level.layers.map((l) => l.asset),
      level.tileAsset,
      'props/carved_column.png',
    ]);
  }

  SpriteAnimation animation(String name, {bool loop = true}) {
    final spec = strips[name]!;
    return SpriteAnimation.fromFrameData(
      image(spec.path),
      SpriteAnimationData.sequenced(
        amount: spec.frames,
        stepTime: 1 / spec.fps,
        textureSize: Vector2(spec.width, spec.height),
        loop: loop,
      ),
    );
  }

  ui.Image image(String path) => images.fromCache(path);
  Sprite tile(int id) => Sprite(
    image(level.tileAsset),
    srcPosition: Vector2((id % tileColumns) * 32.0, (id ~/ tileColumns) * 32.0),
    srcSize: Vector2.all(32),
  );

  static ui.Paint pixelPaint([double opacity = 1]) => ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false
    ..color = ui.Color.fromRGBO(255, 255, 255, opacity);
}
