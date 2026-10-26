import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dialogue_controller.dart';

class DialogueOverlay extends StatefulWidget {
  const DialogueOverlay({required this.controller, super.key});
  final DialogueController controller;
  @override
  State<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<DialogueOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  Duration previous = Duration.zero;
  double phase = 0;
  @override
  void initState() {
    super.initState();
    ticker = createTicker((elapsed) {
      final dt = (elapsed - previous).inMicroseconds / 1000000;
      previous = elapsed;
      phase += dt;
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!c.active) return const SizedBox.shrink();
    return Opacity(
      opacity: c.opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: c.advance,
        child: ColoredBox(
          color: const Color(0x30060d19),
          child: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final small = constraints.maxWidth < 600;
                    return SizedBox(
                      height: small ? 300 : 250,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            top: 52,
                            child: DialoguePanel(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  small ? 20 : 190,
                                  small ? 74 : 24,
                                  24,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!small)
                                      Text(
                                        c.sequence!.speaker.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xff84d9e8),
                                          letterSpacing: 2,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (!small) const SizedBox(height: 12),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Semantics(
                                          label: c.fullText,
                                          child: Text(
                                            c.visibleText,
                                            style: TextStyle(
                                              fontSize: small ? 15 : 18,
                                              height: 1.55,
                                              color: const Color(0xffd4e4e4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DialogueControls(controller: c),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top: math.sin(phase * 1.6) * 5,
                            width: small ? 96 : 144,
                            height: small ? 120 : 180,
                            child: SpeakerPortrait(
                              speaking: c.typing,
                              phase: phase,
                            ),
                          ),
                          if (small)
                            Positioned(
                              left: 130,
                              right: 16,
                              top: 78,
                              child: Text(
                                c.sequence!.speaker.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xff84d9e8),
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DialoguePanel extends StatelessWidget {
  const DialoguePanel({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xf20b1929), Color(0xf208111e)],
      ),
      border: Border.all(color: const Color(0xff426575)),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 22)],
    ),
    child: child,
  );
}

class SpeakerPortrait extends StatelessWidget {
  const SpeakerPortrait({
    required this.speaking,
    required this.phase,
    super.key,
  });
  final bool speaking;
  final double phase;
  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1 + math.sin(phase * (speaking ? 7 : 2)) * (speaking ? .025 : .01),
    child: Opacity(
      opacity: .90 + math.sin(phase * 2) * .08,
      child: Image.asset(
        'assets/images/narrative/memory_portrait.png',
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      ),
    ),
  );
}

class DialogueControls extends StatelessWidget {
  const DialogueControls({required this.controller, super.key});
  final DialogueController controller;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '${controller.lineIndex + 1} / ${controller.sequence!.lines.length}',
        style: const TextStyle(fontSize: 11, color: Color(0xff6f919f)),
      ),
      const Spacer(),
      TextButton(onPressed: controller.skip, child: const Text('Pular')),
      TextButton(
        onPressed: controller.advance,
        child: Text(controller.typing ? 'Revelar' : 'Continuar ▸'),
      ),
    ],
  );
}
