import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/levels/level_data.dart';
import 'package:echoes/game/player/movement_controller.dart';
import 'package:echoes/game/player/player_state.dart';
import 'package:echoes/game/input/game_input.dart';

void main() {
  test(
    'optional gallery paths and tower balconies reconnect through real solver',
    () {
      final paths = {
        'stage_02': [
          ['g3', 'gb0', 'gb1', 'gb2', 'gb3', 'g6'],
          ['g19', 'gb4', 'gb5', 'gb6', 'g20'],
        ],
        'stage_03': [
          ['lower_lancet_right', 'tb0', 'lower_lancet_right', 't5'],
          ['broken_stair_right', 'tb1', 'broken_stair_right', 't20'],
          ['t25', 'tb2', 't25'],
        ],
      };
      for (final entry in paths.entries) {
        final level = LevelData.fromStageJson(
          File('assets/levels/${entry.key}.json').readAsStringSync(),
        );
        final solids = [...level.solids, ...level.temporaryPlatforms];
        for (final path in entry.value) {
          for (var edge = 0; edge < path.length - 1; edge++) {
            final from = solids.firstWhere((s) => s.id == path[edge]),
                target = solids.firstWhere((s) => s.id == path[edge + 1]);
            final direction =
                (target.x + target.width / 2 - (from.x + from.width / 2)).sign
                    .toInt();
            final body =
                PlayerState(
                    x: direction > 0 ? from.right - 24 : from.x + 24,
                    y: from.y,
                  )
                  ..grounded = true
                  ..vx = direction * 210;
            final movement = MovementController(), input = GameInput();
            final gap = direction > 0
                ? target.x - from.right
                : from.x - target.right;
            var landed = false;
            for (var tick = 0; tick < 600; tick++) {
              final delta = target.x + target.width / 2 - body.x;
              final axis = delta.abs() < 10 ? 0 : delta.sign.toInt();
              input.setKeyboard({
                if (axis > 0) InputAction.right,
                if (axis < 0) InputAction.left,
                if (target.y <= from.y || gap > 64) InputAction.jump,
                if (tick == 30 &&
                    ((target.y < from.y && gap >= 70) || gap > 120))
                  InputAction.dash,
              });
              movement.step(body, input.consume(), solids, 1 / 120);
              if (tick > 0 &&
                  body.grounded &&
                  (body.y - target.y).abs() < .1 &&
                  body.right > target.x &&
                  body.left < target.right) {
                landed = true;
                break;
              }
            }
            expect(
              landed,
              isTrue,
              reason:
                  '${entry.key} ${from.id}->${target.id}: stopped ${body.x},${body.y}',
            );
          }
        }
      }
    },
  );
}
