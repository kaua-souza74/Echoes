class PlayerIdentity {
  const PlayerIdentity(this.id, this.email);
  final String id, email;
}

class GameSettings {
  const GameSettings({
    this.dialogueSpeed = 1,
    this.showTimer = true,
    this.reduceEffects = false,
    this.textScale = 1,
  });
  final double dialogueSpeed, textScale;
  final bool showTimer, reduceEffects;
  factory GameSettings.fromJson(Map<String, dynamic> data) => GameSettings(
    dialogueSpeed: (data['dialogue_speed'] as num? ?? 1).toDouble(),
    textScale: (data['text_scale'] as num? ?? 1).toDouble(),
    showTimer: data['show_timer'] as bool? ?? true,
    reduceEffects: data['reduce_visual_effects'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'dialogue_speed': dialogueSpeed,
    'show_timer': showTimer,
    'reduce_visual_effects': reduceEffects,
    'text_scale': textScale,
  };
  GameSettings copyWith({
    double? dialogueSpeed,
    double? textScale,
    bool? showTimer,
    bool? reduceEffects,
  }) => GameSettings(
    dialogueSpeed: dialogueSpeed ?? this.dialogueSpeed,
    textScale: textScale ?? this.textScale,
    showTimer: showTimer ?? this.showTimer,
    reduceEffects: reduceEffects ?? this.reduceEffects,
  );
}

class PlayerSnapshot {
  const PlayerSnapshot({
    this.nickname = 'Errante',
    this.points = 0,
    this.completedRuns = 0,
    this.stages = const {},
    this.echoes = const {},
    this.memories = const {},
    this.dialogues = const {},
    this.learningChecks = const {},
    this.achievements = const [],
    this.bests = const [],
    this.settings = const GameSettings(),
  });
  final String nickname;
  final int points, completedRuns;
  final Map<String, String> stages;
  final Set<String> echoes, memories, dialogues, learningChecks;
  final List<Map<String, dynamic>> achievements, bests;
  final GameSettings settings;
  bool unlocked(String id) => stages.containsKey(id);
  bool completed(String id) => stages[id] == 'completed';
  factory PlayerSnapshot.fromJson(Map<String, dynamic> data) {
    Set<String> ids(String key) =>
        Set<String>.from(data[key] as List? ?? const []);
    return PlayerSnapshot(
      nickname: data['nickname'] as String? ?? 'Errante',
      points: (data['points'] as num? ?? 0).toInt(),
      completedRuns: (data['completed_runs'] as num? ?? 0).toInt(),
      stages: Map<String, String>.from(data['stages'] as Map? ?? const {}),
      echoes: ids('echoes'),
      memories: ids('memories'),
      dialogues: ids('dialogues'),
      learningChecks: ids('learning_checks'),
      achievements: (data['achievements'] as List? ?? const [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
      bests: (data['bests'] as List? ?? const [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
      settings: GameSettings.fromJson(
        Map<String, dynamic>.from(data['settings'] as Map? ?? const {}),
      ),
    );
  }
}

class RankingRow {
  const RankingRow(this.position, this.playerId, this.nickname, this.value);
  final int position, value;
  final String playerId, nickname;
  factory RankingRow.fromJson(Map<String, dynamic> json) => RankingRow(
    (json['position'] as num).toInt(),
    json['player_id'] as String,
    json['nickname'] as String,
    (json['result'] as num).toInt(),
  );
}

String formatTime(int milliseconds) {
  final ms = milliseconds < 0 ? 0 : milliseconds;
  return '${(ms ~/ 60000).toString().padLeft(2, '0')}:'
      '${(ms ~/ 1000 % 60).toString().padLeft(2, '0')}.'
      '${(ms ~/ 10 % 100).toString().padLeft(2, '0')}';
}
