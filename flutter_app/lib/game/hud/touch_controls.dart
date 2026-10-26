import 'package:flutter/material.dart';
import '../input/game_input.dart';

class TouchControls extends StatelessWidget {
  const TouchControls({required this.input, super.key});
  final GameInput input;
  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              HoldButton(
                label: 'Esquerda',
                icon: Icons.chevron_left,
                onChanged: (v) => input.setTouch(InputAction.left, v),
              ),
              const SizedBox(width: 10),
              HoldButton(
                label: 'Direita',
                icon: Icons.chevron_right,
                onChanged: (v) => input.setTouch(InputAction.right, v),
              ),
            ],
          ),
          Row(
            children: [
              HoldButton(
                label: 'Dash',
                icon: Icons.bolt,
                onChanged: (v) => input.setTouch(InputAction.dash, v),
              ),
              const SizedBox(width: 10),
              HoldButton(
                label: 'Pular',
                icon: Icons.keyboard_arrow_up,
                onChanged: (v) => input.setTouch(InputAction.jump, v),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class HoldButton extends StatefulWidget {
  const HoldButton({
    required this.label,
    required this.icon,
    required this.onChanged,
    super.key,
  });
  final String label;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  final Set<int> pointers = {};
  void change(int pointer, bool down) {
    final before = pointers.isNotEmpty;
    setState(() {
      if (down) {
        pointers.add(pointer);
      } else {
        pointers.remove(pointer);
      }
    });
    if (before != pointers.isNotEmpty) {
      widget.onChanged(pointers.isNotEmpty);
    }
  }

  @override
  void dispose() {
    if (pointers.isNotEmpty) {
      widget.onChanged(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: true,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => change(e.pointer, true),
      onPointerUp: (e) => change(e.pointer, false),
      onPointerCancel: (e) => change(e.pointer, false),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Color(pointers.isEmpty ? 0x66111d2b : 0xbb365b6b),
          border: Border.all(color: const Color(0x6684d9e8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: const Color(0xffb0e6eb), size: 28),
            Text(
              widget.label,
              style: const TextStyle(fontSize: 9, color: Color(0xffb0c3ca)),
            ),
          ],
        ),
      ),
    ),
  );
}
