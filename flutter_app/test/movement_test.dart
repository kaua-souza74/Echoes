import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/config/movement_config.dart';
import 'package:echoes/game/input/game_input.dart';
import 'package:echoes/game/levels/level_data.dart';
import 'package:echoes/game/player/movement_controller.dart';
import 'package:echoes/game/player/player_state.dart';

const dt = MovementConfig.fixedStep;
const floor = [Solid(0, 200, 600, 32)];
void tick(
  MovementController c,
  PlayerState b, {
  InputFrame input = const InputFrame(),
  List<Solid> solids = floor,
  int steps = 1,
}) {
  for (var i = 0; i < steps; i++) {
    c.step(b, input, solids, dt);
  }
}

void main() {
  test('accelerates to speed limit and decelerates without reversing', () {
    final c = MovementController(), b = PlayerState(x: 50, y: 200);
    tick(c, b, input: const InputFrame(axis: 1), steps: 50);
    expect(b.vx, 210);
    expect(b.grounded, isTrue);
    tick(c, b, steps: 30);
    expect(b.vx, 0);
  });
  test('released jump is lower than held jump', () {
    double height(bool hold) {
      final c = MovementController(), b = PlayerState(x: 100, y: 200);
      tick(c, b);
      tick(c, b, input: const InputFrame(jumpPressed: true, jumpHeld: true));
      var top = b.y;
      for (var i = 0; i < 120; i++) {
        tick(
          c,
          b,
          input: InputFrame(
            jumpHeld: hold || i < 7,
            jumpReleased: !hold && i == 7,
          ),
        );
        if (b.y < top) {
          top = b.y;
        }
      }
      return 200 - top;
    }

    expect(height(true), greaterThan(80));
    expect(height(false), lessThan(height(true) - 20));
  });
  test('coyote jump works shortly after leaving a ledge but expires', () {
    PlayerState leaveAndJump(int delay) {
      final c = MovementController(), b = PlayerState(x: 30, y: 200);
      tick(c, b, solids: const [Solid(0, 200, 80, 32)]);
      b.x = 100;
      tick(c, b, solids: const [], steps: delay);
      tick(
        c,
        b,
        solids: const [],
        input: const InputFrame(jumpPressed: true, jumpHeld: true),
      );
      return b;
    }

    expect(leaveAndJump(6).vy, lessThan(0));
    expect(leaveAndJump(18).vy, greaterThan(0));
  });
  test('jump buffer survives until landing and fires only once', () {
    final c = MovementController(), b = PlayerState(x: 100, y: 190)..vy = 100;
    tick(c, b, input: const InputFrame(jumpPressed: true, jumpHeld: true));
    var jumps = 0;
    for (var i = 0; i < 18; i++) {
      tick(c, b, input: const InputFrame(jumpHeld: true));
      if (c.jumped) {
        jumps++;
      }
    }
    expect(jumps, 1);
    expect(b.vy, lessThan(0));
  });
  test('dash cannot recharge in air and returns on landing', () {
    final c = MovementController(), b = PlayerState(x: 100, y: 50);
    tick(
      c,
      b,
      solids: const [],
      input: const InputFrame(axis: 1, dashPressed: true),
    );
    expect(c.dashed, isTrue);
    expect(c.abilities.dashAvailable, isFalse);
    tick(c, b, solids: const [], steps: 25);
    tick(c, b, solids: const [], input: const InputFrame(dashPressed: true));
    expect(c.dashed, isFalse);
    b.x = 100;
    b.y = 190;
    b.vy = 100;
    tick(c, b, steps: 40);
    expect(b.grounded, isTrue);
    expect(c.abilities.dashAvailable, isTrue);
  });
  test('wall slide caps falling speed and wall jump points away', () {
    final c = MovementController(), b = PlayerState(x: 93, y: 150)..vy = 200;
    const wall = [Solid(100, 0, 32, 600)];
    tick(c, b, solids: wall, input: const InputFrame(axis: 1));
    expect(b.wallSliding, isTrue);
    expect(b.vy, lessThanOrEqualTo(65));
    expect(b.y - 150, lessThanOrEqualTo(65 * dt + 0.00001));
    tick(
      c,
      b,
      solids: wall,
      input: const InputFrame(axis: 1, jumpPressed: true, jumpHeld: true),
    );
    expect(c.jumped, isTrue);
    expect(b.vx, lessThan(0));
    expect(b.vy, lessThan(0));
    expect(b.facing, -1);
  });
  test('axis sweeps prevent side and floor tunnelling at high speed', () {
    final c = MovementController(), b = PlayerState(x: 30, y: 100);
    c.abilities.startDash(1);
    c.step(b, const InputFrame(), const [Solid(80, 0, 32, 200)], .10);
    expect(b.right, 80);
    expect(b.vx, 0);
    b.respawn(100, 50);
    b.vy = 2000;
    c.step(b, const InputFrame(), const [Solid(0, 100, 300, 32)], .20);
    expect(b.y, 100);
    expect(b.grounded, isTrue);
  });
  test('ceiling contact stops upward movement', () {
    final c = MovementController(), b = PlayerState(x: 100, y: 268)..vy = -500;
    c.step(b, const InputFrame(jumpHeld: true), const [
      Solid(0, 200, 300, 16),
    ], .1);
    expect(b.top, 216);
    expect(b.vy, 0);
  });
}
