import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/levels/level_data.dart';
import 'package:echoes/game/levels/stage_registry.dart';
import 'package:echoes/game/systems/run_record.dart';
import 'package:echoes/game/systems/temporary_platforms.dart';
import 'package:echoes/game/player/player_state.dart';

void main() {
  for (final stage in StageRegistry.stages) {
    test(
      '${stage.id} stable identifiers, geometry, narrative and asset references',
      () {
        final source = File(stage.asset).readAsStringSync();
        final raw = jsonDecode(source) as Map<String, dynamic>;
        final level = LevelData.fromStageJson(source);
        expect(level.id, stage.id);
        expect(level.version, greaterThan(0));
        final solids = [...level.solids, ...level.temporaryPlatforms];
        for (final s in solids) {
          expect(s.width, greaterThan(0));
          expect(s.height, greaterThan(0));
          expect(s.x, greaterThanOrEqualTo(0));
          expect(s.y, greaterThanOrEqualTo(0));
          expect(s.right, lessThanOrEqualTo(level.width));
          expect(s.bottom, lessThanOrEqualTo(level.height));
        }
        bool supported(double x, double y) => solids.any(
          (s) => x >= s.x + 7 && x <= s.right - 7 && (s.y - y).abs() < .1,
        );
        expect(supported(level.spawnX, level.spawnY), isTrue);
        final props = level.props;
        expect(props.map((p) => p.id).toSet().length, props.length);
        final echoes = props
            .where((p) => p.type == 'echo')
            .map((p) => p.id)
            .toSet();
        expect(echoes.length, inInclusiveRange(5, 8));
        expect(echoes, containsAll(level.requiredEchoes));
        final checkpoints = props.where((p) => p.type == 'checkpoint').toList();
        expect(checkpoints.length, inInclusiveRange(4, 6));
        for (final p in props.where((p) => p.type != 'echo')) {
          expect(supported(p.x, p.y), isTrue, reason: p.id);
        }
        expect(props.where((p) => p.type == 'checkpoint_final').length, 1);
        final stories =
            jsonDecode(
                  File('assets/narrative/dialogues.json').readAsStringSync(),
                )
                as Map;
        for (final trigger in level.narrativeTriggers) {
          expect(stories.containsKey(trigger.sequence), isTrue);
          expect(supported(trigger.x, trigger.y), isTrue);
        }
        if (level.finalSequence.isNotEmpty) {
          expect(stories.containsKey(level.finalSequence), isTrue);
        }
        for (final layer in level.layers) {
          expect(File('assets/images/${layer.asset}').existsSync(), isTrue);
          expect(layer.factor, inInclusiveRange(0, 1));
        }
        expect(File('assets/images/${level.tileAsset}').existsSync(), isTrue);
        if (stage.id != 'stage_01') {
          expect((raw['route'] as List).isNotEmpty, isTrue);
          expect(level.temporaryPlatforms.length, 4);
          expect(level.sections.length, 5);
        }
      },
    );
  }
  test('temporary platforms break, delay unsafe reappearance and reset', () {
    final platforms = TemporaryPlatforms([], [
      const TemporaryPlatformSpec(
        0,
        100,
        96,
        32,
        id: 'fragile',
        breakAfter: 1,
        recoverAfter: 2,
      ),
    ]);
    final body = PlayerState(x: 40, y: 100)..grounded = true;
    platforms.tick(body, .5);
    expect(platforms.states.single.armed, isTrue);
    expect(platforms.collisionSolids.length, 1);
    platforms.tick(body, .51);
    expect(platforms.collisionSolids, isEmpty);
    body.y = 120;
    body.grounded = false;
    platforms.tick(body, 2.1);
    expect(platforms.collisionSolids, isEmpty);
    body.x = 200;
    platforms.tick(body, .1);
    expect(platforms.collisionSolids.length, 1);
    body.x = 40;
    body.y = 100;
    body.grounded = true;
    platforms.tick(body, .6);
    platforms.reset();
    expect(platforms.states.single.age, 0);
    expect(platforms.states.single.armed, isFalse);
  });
  test(
    'attempt time excludes paused segments; immutable records are unique',
    () {
      var time = 0;
      final clock = AttemptClock(nowMicros: () => time);
      time = 500000;
      expect(clock.durationMs, 0);
      clock.resume();
      time += 1250000;
      expect(clock.durationMs, 1250);
      clock.pause();
      time += 2000000;
      expect(clock.durationMs, 1250);
      clock.resume();
      time += 750000;
      clock.pause();
      expect(clock.durationMs, 2000);
      final session = PlaySession();
      final echoes = {'one'};
      final record = RunRecord(
        attemptId: session.allocateAttempt(),
        stageId: 'stage_02',
        stageVersion: 1,
        durationMs: clock.durationMs,
        deaths: 2,
        collectibles: echoes,
        completed: true,
      );
      echoes.add('two');
      session.record(record);
      session.record(record);
      expect(session.results.length, 1);
      expect(record.collectibles, {'one'});
      expect(() => record.collectibles.add('x'), throwsUnsupportedError);
      clock.reset();
      expect(clock.durationMs, 0);
      expect(clock.hasStarted, isFalse);
    },
  );
}
