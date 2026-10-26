/// All values are logical pixels and seconds. Physics runs at 120 Hz.
class MovementConfig {
  const MovementConfig({
    this.maxSpeed = 210,
    this.acceleration = 1600,
    this.deceleration = 2000,
    this.gravity = 1100,
    this.maxFallSpeed = 640,
    this.jumpSpeed = 440,
    this.jumpCut = 0.45,
    this.coyoteTime = 0.10,
    this.jumpBufferTime = 0.12,
    this.wallSlideSpeed = 65,
    this.wallJumpX = 250,
    this.wallJumpY = 410,
    this.wallJumpLock = 0.15,
    this.dashSpeed = 560,
    this.dashDuration = 0.17,
  });

  final double maxSpeed, acceleration, deceleration, gravity, maxFallSpeed;
  final double jumpSpeed, jumpCut, coyoteTime, jumpBufferTime;
  final double wallSlideSpeed, wallJumpX, wallJumpY, wallJumpLock;
  final double dashSpeed, dashDuration;

  static const fixedStep = 1 / 120;
  static const bodyWidth = 14.0;
  static const bodyHeight = 32.0;
}
