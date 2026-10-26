import 'dart:math' as math;
import '../config/movement_config.dart';
import '../input/game_input.dart';
import '../levels/level_data.dart';
import 'ability_controller.dart';
import 'player_state.dart';

/// Kinematic solver: sweep each axis against explicit rectangles. Art and
/// decorative pixels are never consulted for collision.
class MovementController {
  MovementController({this.config = const MovementConfig()})
    : abilities = AbilityController(config);
  final MovementConfig config;
  final AbilityController abilities;
  bool jumped = false, landed = false, dashed = false;

  void step(PlayerState body, InputFrame input, List<Solid> solids, double dt) {
    jumped = landed = dashed = false;
    final wasGrounded = body.grounded;
    abilities.tick(dt, grounded: wasGrounded);
    if (input.jumpPressed) {
      abilities.jumpBuffer = config.jumpBufferTime;
    }
    if (input.axis != 0 && abilities.wallLock == 0) {
      body.facing = input.axis.sign.toInt();
    }
    if (input.dashPressed && abilities.startDash(body.facing)) {
      dashed = true;
    }

    if (abilities.dashing) {
      body.vx = abilities.dashDirection * config.dashSpeed;
      body.vy = 0;
    } else {
      if (abilities.wallLock == 0) {
        final target = input.axis * config.maxSpeed;
        final rate = input.axis == 0
            ? config.deceleration
            : config.acceleration;
        body.vx = _approach(body.vx, target, rate * dt);
      }
      if (abilities.jumpBuffer > 0) {
        if (wasGrounded || abilities.coyote > 0) {
          body.vy = -config.jumpSpeed;
          _consumeJump(body);
        } else if (body.wallDirection != 0) {
          body.vx = -body.wallDirection * config.wallJumpX;
          body.vy = -config.wallJumpY;
          body.facing = -body.wallDirection;
          abilities.wallLock = config.wallJumpLock;
          _consumeJump(body);
        }
      }
      if ((input.jumpReleased || (!input.jumpHeld && jumped)) && body.vy < 0) {
        body.vy *= config.jumpCut;
      }
      body.vy = math.min(body.vy + config.gravity * dt, config.maxFallSpeed);
    }

    final wasDashing = abilities.dashing;
    _moveX(body, solids, body.vx * dt);
    _contacts(body, solids);
    // Clamp before integration, so actual descent (not just stored velocity)
    // obeys the wall-slide speed on the first contact tick as well.
    if (!wasDashing &&
        body.vy > 0 &&
        body.wallDirection != 0 &&
        input.axis.sign.toInt() == body.wallDirection) {
      body.vy = math.min(body.vy, config.wallSlideSpeed);
    }
    body.grounded = false;
    _moveY(body, solids, body.vy * dt);
    _contacts(body, solids);
    body.wallSliding =
        !abilities.dashing &&
        !body.grounded &&
        body.vy > 0 &&
        body.wallDirection != 0 &&
        input.axis.sign.toInt() == body.wallDirection;
    if (body.wallSliding) {
      body.vy = math.min(body.vy, config.wallSlideSpeed);
    }
    landed = !wasGrounded && body.grounded;
    if (body.grounded && !wasDashing) {
      abilities.dashAvailable = true;
    }
  }

  void _consumeJump(PlayerState body) {
    jumped = true;
    body.grounded = false;
    abilities.jumpBuffer = abilities.coyote = 0;
  }

  void _moveX(PlayerState b, List<Solid> solids, double dx) {
    var allowed = dx;
    for (final s in solids) {
      if (b.y <= s.y + 0.001 || b.top >= s.bottom - 0.001) {
        continue;
      }
      if (dx > 0 && b.right <= s.x + 0.001 && b.right + allowed >= s.x) {
        allowed = math.min(allowed, s.x - b.right);
      } else if (dx < 0 &&
          b.left >= s.right - 0.001 &&
          b.left + allowed <= s.right) {
        allowed = math.max(allowed, s.right - b.left);
      }
    }
    b.x += allowed;
    if ((allowed - dx).abs() > 0.00001) {
      b.vx = 0;
      abilities.dashTime = 0;
    }
  }

  void _moveY(PlayerState b, List<Solid> solids, double dy) {
    var allowed = dy;
    var hitFloor = false;
    for (final s in solids) {
      if (b.right <= s.x + 0.001 || b.left >= s.right - 0.001) {
        continue;
      }
      if (dy >= 0 && b.y <= s.y + 0.001 && b.y + allowed >= s.y) {
        allowed = math.min(allowed, s.y - b.y);
        hitFloor = true;
      } else if (dy < 0 &&
          b.top >= s.bottom - 0.001 &&
          b.top + allowed <= s.bottom) {
        allowed = math.max(allowed, s.bottom - b.top);
      }
    }
    b.y += allowed;
    if (hitFloor) {
      b.grounded = true;
    }
    if ((allowed - dy).abs() > 0.00001 || hitFloor) {
      b.vy = 0;
    }
  }

  void _contacts(PlayerState b, List<Solid> solids) {
    b.wallDirection = 0;
    for (final s in solids) {
      if (b.y <= s.y + 0.1 || b.top >= s.bottom - 0.1) {
        continue;
      }
      if ((b.right - s.x).abs() < 0.1) {
        b.wallDirection = 1;
      }
      if ((b.left - s.right).abs() < 0.1) {
        b.wallDirection = -1;
      }
    }
  }

  PlayerPose pose(PlayerState b) => abilities.dashing
      ? PlayerPose.dash
      : b.wallSliding
      ? PlayerPose.wallSlide
      : !b.grounded
      ? (b.vy < 0 ? PlayerPose.jump : PlayerPose.fall)
      : b.vx.abs() > 5
      ? PlayerPose.run
      : PlayerPose.idle;

  static double _approach(double value, double target, double delta) =>
      value < target
      ? math.min(value + delta, target)
      : math.max(value - delta, target);
}
