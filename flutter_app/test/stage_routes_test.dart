import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/levels/level_data.dart';
import 'package:echoes/game/player/movement_controller.dart';
import 'package:echoes/game/player/player_state.dart';
import 'package:echoes/game/input/game_input.dart';

void main() {
  test('all five optional routes reconnect using the actual movement solver', () {
    final level = LevelData.fromStageJson(
      File('assets/levels/stage_01.json').readAsStringSync(),
    );
    // Surface IDs in the authored main/branch lists; every detour has an exit.
    final routes = [
      [3, 34, 39, 40, 41, 6],
      [8, 35, 42, 43, 44, 11],
      [15, 36, 45, 46, 47, 18],
      [22, 37, 48, 49, 50, 25],
      [27, 38, 51, 52, 53, 30],
    ];
    for (final route in routes) {
      for (var edge = 0; edge < route.length - 1; edge++) {
        final from = level.solids[route[edge]],
            target = level.solids[route[edge + 1]];
        final body = PlayerState(x: from.right - 24, y: from.y)
          ..grounded = true
          ..vx = 210;
        final movement = MovementController();
        final input = GameInput();
        final gap = target.x - from.right;
        final needsDash = (target.y < from.y && gap >= 70) || gap > 120;
        var landed = false;
        for (var tick = 0; tick < 600; tick++) {
          final dash = needsDash && tick == 30;
          input.setKeyboard({
            if (body.x < target.x + target.width / 2 - 12) InputAction.right,
            InputAction.jump,
            if (dash) InputAction.dash,
          });
          movement.step(body, input.consume(), level.solids, 1 / 120);
          if (body.grounded &&
              (body.y - target.y).abs() < .1 &&
              body.right > target.x &&
              body.left < target.right) {
            landed = true;
            break;
          }
          if (body.y > level.height + 64) break;
        }
        expect(
          landed,
          isTrue,
          reason:
              'Detour ${route.first}: surface ${route[edge]} -> ${route[edge + 1]} stopped at ${body.x}, ${body.y}',
        );
      }
    }
    for (final echo in level.props.where((p) => p.type == 'echo')) {
      expect(
        level.solids.any(
          (s) =>
              echo.x >= s.x &&
              echo.x <= s.right &&
              (s.y - echo.y) >= 0 &&
              (s.y - echo.y) <= 32,
        ),
        isTrue,
        reason:
            '${echo.id} must sit within collection range of a reachable surface',
      );
    }
  });
}
