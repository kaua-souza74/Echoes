import 'dart:convert';

class Solid {
  const Solid(this.x, this.y, this.width, this.height, {this.id = ''});
  final double x, y, width, height;
  final String id;
  double get right => x + width;
  double get bottom => y + height;
}

class TemporaryPlatformSpec extends Solid {
  const TemporaryPlatformSpec(
    super.x,
    super.y,
    super.width,
    super.height, {
    required super.id,
    this.breakAfter = 1.1,
    this.recoverAfter = 3,
  });
  final double breakAfter, recoverAfter;
}

class AmbientActor {
  const AmbientActor(this.sprite, this.x, this.y, this.factor, this.opacity);
  final String sprite;
  final double x, y, factor, opacity;
}

class AmbientEvent {
  const AmbientEvent(
    this.id,
    this.kind,
    this.sprite,
    this.x,
    this.y,
    this.width,
    this.height,
    this.duration,
  );
  final String id, kind, sprite;
  final double x, y, width, height, duration;
}

class LevelProp {
  const LevelProp(
    this.type,
    this.x,
    this.y, {
    this.id = '',
    this.label = '',
    this.order = 0,
  });
  final String type;

  /// Checkpoints use foot coordinates. Echoes use their centre.
  final double x, y;
  final String id, label;
  final int order;
}

class LevelSection {
  const LevelSection(
    this.name,
    this.start,
    this.end, {
    this.top = double.negativeInfinity,
    this.bottom = double.infinity,
  });
  final String name;
  final double start, end;
  final double top, bottom;
  bool contains(double x, double y) =>
      x >= start && x < end && y >= top && y < bottom;
}

class NarrativeTrigger {
  const NarrativeTrigger(
    this.id,
    this.x,
    this.y,
    this.radius,
    this.sequence, {
    this.verticalRadius = 60,
  });
  final String id, sequence;
  final double x, y, radius;
  final double verticalRadius;
}

class LayerData {
  const LayerData(this.asset, this.factor, {this.factorY = 0});
  final String asset;
  final double factor;
  final double factorY;
}

class LevelData {
  const LevelData({
    required this.width,
    required this.height,
    required this.solids,
    required this.props,
    required this.layers,
    this.spawnX = 64,
    this.spawnY = 384,
    this.requiredEchoes = const ['echo_01'],
    this.sections = const [],
    this.narrativeTriggers = const [],
    this.id = 'stage_01',
    this.title = 'O Despertar',
    this.version = 1,
    this.tileAsset = 'tilesets/stage_01_ruins_tiles.png',
    this.temporaryPlatforms = const [],
    this.ambientEvents = const [],
    this.ambientActors = const [
      AmbientActor('listener', 318, 163, .17, .68),
      AmbientActor('moth', 115, 105, .10, .80),
      AmbientActor('moth', 520, 137, .10, .76),
    ],
    this.finalSequence = '',
    this.checkpointFallLimit = double.infinity,
    this.lookAhead = 48,
    this.followRate = 7,
  });
  final double width, height;
  final List<Solid> solids;
  final List<LevelProp> props;
  final List<LayerData> layers;
  final double spawnX, spawnY;
  final List<String> requiredEchoes;
  final List<LevelSection> sections;
  final List<NarrativeTrigger> narrativeTriggers;
  final String id, title, tileAsset, finalSequence;
  final int version;
  final List<TemporaryPlatformSpec> temporaryPlatforms;
  final List<AmbientActor> ambientActors;
  final List<AmbientEvent> ambientEvents;
  final double checkpointFallLimit, lookAhead, followRate;

  factory LevelData.fromStageJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    double number(dynamic v) => (v as num).toDouble();
    return LevelData(
      id: data['id'],
      title: data['title'],
      version: data['version'],
      tileAsset: data['tile_asset'] ?? 'tilesets/stage_01_ruins_tiles.png',
      finalSequence: data['final_sequence'] ?? '',
      checkpointFallLimit: number(
        data['checkpoint_fall_limit'] ?? double.infinity,
      ),
      lookAhead: number(data['camera']?['look_ahead'] ?? 48),
      followRate: number(data['camera']?['follow_rate'] ?? 7),
      width: number(data['width']),
      height: number(data['height']),
      spawnX: number(data['spawn'][0]),
      spawnY: number(data['spawn'][1]),
      requiredEchoes: List<String>.from(data['required_echoes']),
      solids: (data['solids'] as List)
          .map(
            (p) => p is List
                ? Solid(number(p[0]), number(p[1]), number(p[2]), number(p[3]))
                : Solid(
                    number(p['x']),
                    number(p['y']),
                    number(p['width']),
                    number(p['height']),
                    id: p['id'],
                  ),
          )
          .toList(),
      props: (data['props'] as List)
          .map(
            (p) => LevelProp(
              p['type'],
              number(p['x']),
              number(p['y']),
              id: p['id'],
              label: p['label'],
              order: p['order'] ?? 0,
            ),
          )
          .toList(),
      layers: (data['layers'] as List)
          .map(
            (p) => LayerData(
              p['asset'],
              number(p['parallax']),
              factorY: number(p['parallax_y'] ?? 0),
            ),
          )
          .toList(),
      sections: (data['sections'] as List)
          .map(
            (p) => LevelSection(
              p['name'],
              number(p['start']),
              number(p['end']),
              top: number(p['top'] ?? double.negativeInfinity),
              bottom: number(p['bottom'] ?? double.infinity),
            ),
          )
          .toList(),
      temporaryPlatforms: (data['temporary_platforms'] as List? ?? [])
          .map(
            (p) => TemporaryPlatformSpec(
              number(p['x']),
              number(p['y']),
              number(p['width']),
              number(p['height']),
              id: p['id'],
              breakAfter: number(p['break_after']),
              recoverAfter: number(p['recover_after']),
            ),
          )
          .toList(),
      ambientActors: data['ambient_actors'] == null
          ? const [
              AmbientActor('listener', 318, 163, .17, .68),
              AmbientActor('moth', 115, 105, .10, .80),
              AmbientActor('moth', 520, 137, .10, .76),
            ]
          : (data['ambient_actors'] as List)
                .map(
                  (p) => AmbientActor(
                    p['sprite'],
                    number(p['x']),
                    number(p['y']),
                    number(p['factor']),
                    number(p['opacity']),
                  ),
                )
                .toList(),
      ambientEvents: (data['ambient_events'] as List? ?? [])
          .map(
            (p) => AmbientEvent(
              p['id'],
              p['kind'],
              p['sprite'],
              number(p['x']),
              number(p['y']),
              number(p['width']),
              number(p['height']),
              number(p['duration']),
            ),
          )
          .toList(),
      narrativeTriggers: (data['narrative_triggers'] as List)
          .map(
            (p) => NarrativeTrigger(
              p['id'],
              number(p['x']),
              number(p['y']),
              number(p['radius']),
              p['sequence'],
              verticalRadius: number(p['vertical_radius'] ?? 60),
            ),
          )
          .toList(),
    );
  }

  factory LevelData.fromArtJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final tile = (json['tile_size'] as num).toDouble();
    final dims = json['canvas_tiles'] as List<dynamic>;
    return LevelData(
      width: (dims[0] as num) * tile,
      height: (dims[1] as num) * tile,
      solids: (json['platforms'] as List<dynamic>).map((dynamic data) {
        final p = data as List<dynamic>;
        return Solid(
          (p[0] as num) * tile,
          (p[1] as num) * tile,
          (p[2] as num) * tile,
          (p[3] as num) * tile,
        );
      }).toList(),
      props: (json['props'] as List<dynamic>).map((dynamic data) {
        final p = data as Map<String, dynamic>;
        final xy = p['tile_xy'] as List<dynamic>;
        final isEcho = p['type'] == 'echo';
        return LevelProp(
          p['type'] as String,
          (xy[0] as num) * tile + (isEcho ? 16 : 24),
          (xy[1] as num) * tile + (isEcho ? 16 : 64),
        );
      }).toList(),
      layers: (json['layers'] as List<dynamic>)
          .where((dynamic p) => p['name'] != 'world')
          .map(
            (dynamic p) => LayerData(
              p['asset'] as String,
              (p['parallax'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
