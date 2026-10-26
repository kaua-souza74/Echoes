import '../levels/level_data.dart';
import '../player/player_state.dart';

class TemporaryPlatformState {
  TemporaryPlatformState(this.spec);
  final TemporaryPlatformSpec spec;
  bool armed = false;
  double age = 0, cooldown = 0;
  bool get active => cooldown <= 0;
  void reset() {
    armed = false;
    age = cooldown = 0;
  }
}

class TemporaryPlatforms {
  TemporaryPlatforms(this.staticSolids, List<TemporaryPlatformSpec> specs)
    : states = specs.map(TemporaryPlatformState.new).toList() {
    _rebuild();
  }
  final List<Solid> staticSolids;
  final List<TemporaryPlatformState> states;
  late List<Solid> collisionSolids;
  void _rebuild() {
    collisionSolids = [
      ...staticSolids,
      ...states.where((s) => s.active).map((s) => s.spec),
    ];
  }

  void tick(PlayerState body, double dt) {
    var changed = false;
    for (final state in states) {
      final s = state.spec;
      if (!state.active) {
        final overlaps =
            body.right > s.x &&
            body.left < s.right &&
            body.y > s.y &&
            body.top < s.bottom;
        state.cooldown -= dt;
        if (state.cooldown <= 0) {
          if (overlaps) {
            state.cooldown = .05;
          } else {
            state.reset();
            changed = true;
          }
        }
      } else {
        if (body.grounded &&
            (body.y - s.y).abs() < .5 &&
            body.right > s.x &&
            body.left < s.right) {
          state.armed = true;
        }
        if (state.armed) {
          state.age += dt;
          if (state.age >= s.breakAfter) {
            state.cooldown = s.recoverAfter;
            state.armed = false;
            state.age = 0;
            changed = true;
          }
        }
      }
    }
    if (changed) _rebuild();
  }

  void reset() {
    for (final s in states) {
      s.reset();
    }
    _rebuild();
  }
}
