enum InputAction { left, right, jump, dash }

class InputFrame {
  const InputFrame({
    this.axis = 0,
    this.jumpHeld = false,
    this.jumpPressed = false,
    this.jumpReleased = false,
    this.dashPressed = false,
  });
  final double axis;
  final bool jumpHeld, jumpPressed, jumpReleased, dashPressed;
}

/// Keyboard and touch are combined before detecting edges. Edges survive a
/// render frame with no physics tick and are consumed once by the fixed step.
class GameInput {
  final Set<InputAction> _keyboard = {}, _touch = {};
  bool _jumpPressed = false, _jumpReleased = false, _dashPressed = false;

  bool _held(InputAction action) =>
      _keyboard.contains(action) || _touch.contains(action);
  void setKeyboard(Set<InputAction> actions) => _change(() {
    _keyboard
      ..clear()
      ..addAll(actions);
  });
  void setTouch(InputAction action, bool down) => _change(() {
    if (down) {
      _touch.add(action);
    } else {
      _touch.remove(action);
    }
  });
  void _change(void Function() mutate) {
    final jumpBefore = _held(InputAction.jump);
    final dashBefore = _held(InputAction.dash);
    mutate();
    final jumpAfter = _held(InputAction.jump);
    _jumpPressed |= !jumpBefore && jumpAfter;
    _jumpReleased |= jumpBefore && !jumpAfter;
    _dashPressed |= !dashBefore && _held(InputAction.dash);
  }

  InputFrame consume() {
    final frame = InputFrame(
      axis:
          (_held(InputAction.right) ? 1.0 : 0) -
          (_held(InputAction.left) ? 1.0 : 0),
      jumpHeld: _held(InputAction.jump),
      jumpPressed: _jumpPressed,
      jumpReleased: _jumpReleased,
      dashPressed: _dashPressed,
    );
    _jumpPressed = _jumpReleased = _dashPressed = false;
    return frame;
  }

  void clear() {
    _keyboard.clear();
    _touch.clear();
    _jumpPressed = _jumpReleased = _dashPressed = false;
  }
}
