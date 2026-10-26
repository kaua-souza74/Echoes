import 'dart:math' as math;

class FollowCamera {
  FollowCamera({
    required this.worldWidth,
    required this.worldHeight,
    this.viewWidth = 640,
    this.viewHeight = 360,
    this.lookAhead = 48,
    this.followRate = 7,
  });
  final double worldWidth, worldHeight, viewWidth, viewHeight;
  final double lookAhead, followRate;
  double x = 320, y = 320;
  double get left => x - viewWidth / 2;
  double get top => y - viewHeight / 2;

  void follow(
    double px,
    double py,
    int facing,
    double dt, {
    bool snap = false,
  }) {
    final tx = (px + facing * lookAhead).clamp(
      viewWidth / 2,
      math.max(viewWidth / 2, worldWidth - viewWidth / 2),
    );
    final ty = (py - 52).clamp(
      viewHeight / 2,
      math.max(viewHeight / 2, worldHeight - viewHeight / 2),
    );
    final amount = snap ? 1.0 : 1 - math.exp(-followRate * dt);
    x += (tx - x) * amount;
    y += (ty - y) * amount;
  }
}
