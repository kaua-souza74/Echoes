import '../config/movement_config.dart';

enum PlayerPose { idle, run, jump, fall, dash, wallSlide }

class PlayerState {
  PlayerState({this.x = 64, this.y = 384});
  double x, y, vx = 0, vy = 0;
  bool grounded = false, wallSliding = false;
  int facing = 1, wallDirection = 0;
  double get left => x - MovementConfig.bodyWidth / 2;
  double get right => x + MovementConfig.bodyWidth / 2;
  double get top => y - MovementConfig.bodyHeight;

  void respawn(double px, double py) {
    x = px;
    y = py;
    vx = vy = 0;
    grounded = wallSliding = false;
    wallDirection = 0;
    facing = 1;
  }
}
