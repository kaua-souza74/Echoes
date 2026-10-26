import 'dart:math' as math;
import '../config/movement_config.dart';

class AbilityController {
  AbilityController(this.config);
  final MovementConfig config;
  double coyote = 0, jumpBuffer = 0, dashTime = 0, wallLock = 0;
  bool dashAvailable = true;
  int dashDirection = 1;
  bool get dashing => dashTime > 0;

  void tick(double dt, {required bool grounded}) {
    coyote = grounded ? config.coyoteTime : math.max(0, coyote - dt);
    jumpBuffer = math.max(0, jumpBuffer - dt);
    dashTime = math.max(0, dashTime - dt);
    wallLock = math.max(0, wallLock - dt);
    if (grounded && !dashing) {
      dashAvailable = true;
    }
  }

  bool startDash(int direction) {
    if (!dashAvailable || dashing) {
      return false;
    }
    dashAvailable = false;
    dashDirection = direction;
    dashTime = config.dashDuration;
    jumpBuffer = coyote = 0;
    return true;
  }

  void reset() {
    coyote = jumpBuffer = dashTime = wallLock = 0;
    dashAvailable = true;
  }
}
