import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

class EchoTutorialScreen extends StatefulWidget {
  const EchoTutorialScreen({
    required this.guide,
    required this.reduceEffects,
    required this.onFinish,
    super.key,
  });

  final bool guide;
  final bool reduceEffects;
  final VoidCallback onFinish;

  @override
  State<EchoTutorialScreen> createState() => _EchoTutorialScreenState();
}

class _EchoTutorialScreenState extends State<EchoTutorialScreen> {
  int _index = 0;

  List<_TutorialBeat> get _beats => widget.guide ? _guideBeats : _storyBeats;

  void _next() {
    if (_index >= _beats.length - 1) {
      widget.onFinish();
      return;
    }
    setState(() => _index++);
  }

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.guide) {
      return _StoryCinematic(
        reduceEffects: widget.reduceEffects,
        onFinish: widget.onFinish,
      );
    }
    final beat = _beats[_index];
    return EchoShell(
      title: widget.guide ? 'Guia de primeiros passos' : 'O primeiro eco',
      back: null,
      reduceEffects: widget.reduceEffects,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final introLabel = Text(
            widget.guide
                ? 'UM MAPA PARA OS PRIMEIROS PASSOS'
                : 'UMA BREVE HISTÓRIA DO VALE',
            style: const TextStyle(
              color: lume,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          );
          final skipButton = TextButton.icon(
            onPressed: widget.onFinish,
            icon: const Icon(Icons.fast_forward, size: 18),
            label: Text(widget.guide ? 'Pular guia' : 'Pular tutorial'),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      introLabel,
                      Align(
                        alignment: Alignment.centerRight,
                        child: skipButton,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: introLabel),
                      skipButton,
                    ],
                  ),
                const SizedBox(height: 14),
                if (compact) ...[
                  SizedBox(
                    height: 180,
                    child: LumeParticleNarrator(
                      motif: beat.motif,
                      reduceEffects: widget.reduceEffects,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NarrationCard(beat: beat, index: _index),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 310,
                        height: 270,
                        child: LumeParticleNarrator(
                          motif: beat.motif,
                          reduceEffects: widget.reduceEffects,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _NarrationCard(beat: beat, index: _index),
                      ),
                    ],
                  ),
                const SizedBox(height: 22),
                _StepProgress(index: _index, count: _beats.length),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: _index == 0 ? null : _previous,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Anterior'),
                    ),
                    EchoButton(
                      _index == _beats.length - 1
                          ? (widget.guide ? 'Voltar ao menu' : 'Entrar no Vale')
                          : 'Continuar',
                      onPressed: _next,
                      icon: _index == _beats.length - 1
                          ? Icons.explore_outlined
                          : Icons.arrow_forward,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoryCinematic extends StatefulWidget {
  const _StoryCinematic({required this.reduceEffects, required this.onFinish});

  final bool reduceEffects;
  final VoidCallback onFinish;

  @override
  State<_StoryCinematic> createState() => _StoryCinematicState();
}

class _StoryCinematicState extends State<_StoryCinematic> {
  static const _tickRate = Duration(milliseconds: 32);
  static const _titleDelay = 360;
  static const _titleLetterMs = 34;
  static const _messageGap = 220;
  static const _messageLetterMs = 30;
  static const _finalHold = 1450;

  late final ValueNotifier<_StoryFrame> _frame;
  late final ValueNotifier<double> _reaction;
  late Timer _timer;
  DateTime _beatStarted = DateTime.now();
  DateTime _lastGlyphAt = DateTime.now();
  int _beatIndex = 0;
  int _typedCount = 0;
  double _glyphStrength = .45;

  _TutorialBeat get _beat => _storyBeats[_beatIndex];

  @override
  void initState() {
    super.initState();
    _frame = ValueNotifier(const _StoryFrame('', '', 0));
    _reaction = ValueNotifier(0);
    _beatStarted = DateTime.now();
    _timer = Timer.periodic(_tickRate, (_) => _tick());
    _tick();
  }

  int get _beatDurationMs =>
      _titleDelay +
      _beat.title.length * _titleLetterMs +
      _messageGap +
      _beat.message.length * _messageLetterMs +
      _finalHold;

  void _tick() {
    if (!mounted) return;
    final elapsed = DateTime.now().difference(_beatStarted).inMilliseconds;
    if (elapsed >= _beatDurationMs) {
      if (_beatIndex == _storyBeats.length - 1) {
        _timer.cancel();
        widget.onFinish();
        return;
      }
      setState(() {
        _beatIndex++;
        _beatStarted = DateTime.now();
        _typedCount = 0;
      });
      _frame.value = _StoryFrame('', '', _beatIndex);
      _lastGlyphAt = DateTime.now();
      return;
    }

    final titleCount = ((elapsed - _titleDelay) / _titleLetterMs)
        .floor()
        .clamp(0, _beat.title.length)
        .toInt();
    final messageStart =
        _titleDelay + _beat.title.length * _titleLetterMs + _messageGap;
    final messageCount = ((elapsed - messageStart) / _messageLetterMs)
        .floor()
        .clamp(0, _beat.message.length)
        .toInt();
    final next = _StoryFrame(
      _beat.title.substring(0, titleCount),
      _beat.message.substring(0, messageCount),
      _beatIndex,
    );
    if (next.title != _frame.value.title ||
        next.message != _frame.value.message) {
      final typed = next.title + next.message;
      if (typed.length > _typedCount) {
        final lastGlyph = typed.substring(typed.length - 1);
        _typedCount = typed.length;
        _lastGlyphAt = DateTime.now();
        _glyphStrength = switch (lastGlyph) {
          '.' || '!' || '?' || ',' || ':' || ';' => .9,
          'a' ||
          'e' ||
          'i' ||
          'o' ||
          'u' ||
          'A' ||
          'E' ||
          'I' ||
          'O' ||
          'U' => .68,
          ' ' => .26,
          _ => .43,
        };
      }
      _frame.value = next;
    }

    final decay =
        (1 - DateTime.now().difference(_lastGlyphAt).inMilliseconds / 210)
            .clamp(0.0, 1.0);
    final strength = widget.reduceEffects ? .24 : _glyphStrength;
    _reaction.value = .035 + strength * decay;
  }

  @override
  void dispose() {
    _timer.cancel();
    _frame.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    body: Stack(
      fit: StackFit.expand,
      children: [
        EchoBackdrop(
          reduceEffects: widget.reduceEffects,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: lume, size: 17),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'ECHOES  ·  O DESPERTAR',
                          style: TextStyle(
                            color: lume,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onFinish,
                        icon: const Icon(Icons.fast_forward, size: 17),
                        label: const Text('Pular tutorial'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 740),
                        child: LumeParticleNarrator(
                          key: const ValueKey('story-lume'),
                          motif: _beat.motif,
                          reaction: _reaction,
                          reduceEffects: widget.reduceEffects,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<_StoryFrame>(
                    valueListenable: _frame,
                    builder: (context, frame, _) => ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: _CinematicNarrationCard(frame: frame),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _MemoryFilmOverlay(reduceEffects: widget.reduceEffects),
          ),
        ),
      ],
    ),
  );
}

class _StoryFrame {
  const _StoryFrame(this.title, this.message, this.beatIndex);

  final String title;
  final String message;
  final int beatIndex;
}

class _MemoryFilmOverlay extends StatefulWidget {
  const _MemoryFilmOverlay({required this.reduceEffects});
  final bool reduceEffects;

  @override
  State<_MemoryFilmOverlay> createState() => _MemoryFilmOverlayState();
}

class _MemoryFilmOverlayState extends State<_MemoryFilmOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _film = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceEffects) _film.repeat();
  }

  @override
  void didUpdateWidget(covariant _MemoryFilmOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceEffects != widget.reduceEffects) {
      if (widget.reduceEffects) {
        _film.stop();
      } else {
        _film.repeat();
      }
    }
  }

  @override
  void dispose() {
    _film.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _film,
    builder: (context, _) => CustomPaint(
      painter: _FilmDamagePainter(
        frame: widget.reduceEffects ? 0 : (_film.value * 12).floor(),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _FilmDamagePainter extends CustomPainter {
  const _FilmDamagePainter({required this.frame});
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          radius: .9,
          colors: [Color(0x00000000), Color(0x2507080b)],
          stops: [0.42, 1],
        ).createShader(bounds),
    );

    final random = math.Random(9407 + frame * 83);
    final scratch = Paint()
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = random.nextDouble() * size.width;
      final start = random.nextDouble() * size.height * .45;
      final length = size.height * (.18 + random.nextDouble() * .58);
      scratch.color = const Color(0xffd6d1bd).withAlpha(7 + random.nextInt(12));
      canvas.drawLine(Offset(x, start), Offset(x, start + length), scratch);
    }

    final dust = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 24; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final side = random.nextDouble() < .8 ? 1.0 : 2.0;
      dust.color = const Color(0xffe8dfc7).withAlpha(8 + random.nextInt(14));
      canvas.drawRect(Rect.fromLTWH(x, y, side, side), dust);
    }

    final exposure = Paint()
      ..color = const Color(0xffe1d6bd).withAlpha(frame % 3 == 0 ? 5 : 2);
    canvas.drawRect(bounds, exposure);
    final edge = Paint()..color = const Color(0xff05070b).withAlpha(18);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), edge);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 1, size.width, 1), edge);
  }

  @override
  bool shouldRepaint(covariant _FilmDamagePainter oldDelegate) =>
      oldDelegate.frame != frame;
}

class _CinematicNarrationCard extends StatelessWidget {
  const _CinematicNarrationCard({required this.frame});

  final _StoryFrame frame;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 15, 22, 18),
    decoration: BoxDecoration(
      color: const Color(0xf0101b29),
      border: Border.all(color: const Color(0xff425b6b)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: lume, size: 16),
            const SizedBox(width: 8),
            const Text(
              'LUME  ·  NARRADOR',
              style: TextStyle(
                color: lume,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff506576)),
              ),
              child: const Text(
                'SEM ÁUDIO',
                style: TextStyle(fontSize: 9, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .035),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(frame.beatIndex),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                frame.title.isEmpty ? ' ' : frame.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 5),
              Semantics(
                liveRegion: true,
                child: Text(
                  frame.message.isEmpty ? ' ' : frame.message,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: Color(0xffd2dde4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NarrationCard extends StatelessWidget {
  const _NarrationCard({required this.beat, required this.index});

  final _TutorialBeat beat;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: panel,
      border: Border.all(color: stone),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: lume, size: 17),
            const SizedBox(width: 8),
            const Text(
              'LUME · NARRADOR',
              style: TextStyle(
                color: lume,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff506576)),
              ),
              child: const Text(
                'SEM ÁUDIO',
                style: TextStyle(fontSize: 9, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(index),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                beat.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  beat.message,
                  style: const TextStyle(
                    height: 1.7,
                    fontSize: 16,
                    color: Color(0xffd2dde4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            color: i <= index ? lume : const Color(0xff263745),
          ),
        ),
        if (i < count - 1) const SizedBox(width: 6),
      ],
      const SizedBox(width: 12),
      Text(
        '${index + 1} / $count',
        style: const TextStyle(color: Color(0xff9eafb9), fontSize: 12),
      ),
    ],
  );
}

class LumeParticleNarrator extends StatefulWidget {
  const LumeParticleNarrator({
    required this.motif,
    required this.reduceEffects,
    this.reaction,
    super.key,
  });

  final int motif;
  final bool reduceEffects;
  final ValueListenable<double>? reaction;

  @override
  State<LumeParticleNarrator> createState() => _LumeParticleNarratorState();
}

class _LumeParticleNarratorState extends State<LumeParticleNarrator>
    with TickerProviderStateMixin {
  static const _particleCount = 112;
  late final AnimationController _transition;
  late final AnimationController _ambient;
  late List<Offset> _from;
  late List<Offset> _to;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _to = _shapePoints(widget.motif);
    _from = _shapePoints(widget.motif + 1);
    if (widget.reduceEffects) {
      _transition.value = 1;
    } else {
      _ambient.repeat();
      _transition.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LumeParticleNarrator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motif != widget.motif) {
      _from = _to;
      _to = _shapePoints(widget.motif);
      if (widget.reduceEffects) {
        _transition.value = 1;
      } else {
        _transition.forward(from: 0);
      }
    }
    if (oldWidget.reduceEffects != widget.reduceEffects) {
      if (widget.reduceEffects) {
        _ambient.stop();
        _transition.value = 1;
      } else {
        _ambient.repeat();
        _transition.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    _ambient.dispose();
    super.dispose();
  }

  List<Offset> _shapePoints(int motif) {
    final random = math.Random(8201 + motif * 431);
    return List<Offset>.generate(_particleCount, (index) {
      final t = (index + .5) / _particleCount;
      final angle = index * 2.399963229728653;
      switch (motif % 5) {
        case 0:
          final radius = .06 + math.sqrt(t) * .43;
          return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        case 1:
          final y = -.56 + t * 1.1;
          final width = .035 + math.sin(t * math.pi) * .36;
          final x = (random.nextDouble() * 2 - 1) * width;
          return Offset(x + .09 * math.sin(t * math.pi * 2), y);
        case 2:
          final radius = .045 + t * .47;
          final a = angle + t * 3.1;
          return Offset(math.cos(a) * radius, math.sin(a) * radius * .72);
        case 3:
          final x = t * 1.18 - .59;
          return Offset(x, math.sin(x * math.pi * 1.55) * .31);
        default:
          if (index < _particleCount * .64) {
            final u = index / (_particleCount * .64);
            return Offset(
              (random.nextDouble() - .5) * (.11 + u * .11),
              -.54 + u * .9,
            );
          }
          final u = (index - _particleCount * .64) / (_particleCount * .36);
          final a = math.pi + u * math.pi;
          return Offset(.43 * math.cos(a), .13 + .2 * math.sin(a));
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      _transition,
      _ambient,
      if (widget.reaction != null) widget.reaction!,
    ]),
    builder: (context, _) => CustomPaint(
      painter: _LumeParticlePainter(
        from: _from,
        to: _to,
        transition: _transition.value,
        ambient: widget.reduceEffects ? 0 : _ambient.value,
        reaction: widget.reaction?.value ?? 0,
        reducedMotion: widget.reduceEffects,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _LumeParticlePainter extends CustomPainter {
  const _LumeParticlePainter({
    required this.from,
    required this.to,
    required this.transition,
    required this.ambient,
    required this.reaction,
    required this.reducedMotion,
  });

  final List<Offset> from, to;
  final double transition, ambient, reaction;
  final bool reducedMotion;

  Offset _place(Offset point, Size size) => Offset(
    size.width * (.5 + point.dx * .46),
    size.height * (.5 + point.dy * .46),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || to.isEmpty) return;
    final count = math.min(from.length, to.length);
    final centers = <Offset>[];
    final alphas = <double>[];
    final minSide = math.min(size.width, size.height);
    final dissolving = Curves.easeInCubic.transform(
      (transition / .48).clamp(0, 1).toDouble(),
    );
    final forming = Curves.easeOutCubic.transform(
      ((transition - .48) / .52).clamp(0, 1).toDouble(),
    );

    for (var i = 0; i < count; i++) {
      final theta = i * 2.399963229728653;
      final drift = Offset(
        math.cos(theta) * minSide * (.24 + (i % 7) * .025),
        math.sin(theta) * minSide * (.24 + (i % 5) * .03),
      );
      final source = _place(from[i], size);
      final target = _place(to[i], size);
      Offset center;
      double alpha;
      if (transition < .48) {
        center = Offset.lerp(source, source + drift, dissolving)!;
        alpha = 1 - dissolving;
      } else if (transition < 1) {
        center = Offset.lerp(source + drift, target, forming)!;
        alpha = forming;
      } else {
        center = target;
        alpha = 1;
      }
      final idle = reducedMotion
          ? Offset.zero
          : Offset(
              math.sin(ambient * math.pi * 2 + i * .7) * 2.2,
              math.cos(ambient * math.pi * 2 + i * .53) * 1.8,
            );
      final core = Offset(size.width * .5, size.height * .5);
      final radial = center - core;
      final energy = reaction.clamp(0.0, 1.0).toDouble();
      final response = radial.distance == 0
          ? Offset.zero
          : radial / radial.distance * (energy * (8 + (i % 7) * 2.6));
      centers.add(core + radial * (1 + energy * .32) + idle + response);
      alphas.add(alpha.clamp(0, 1).toDouble());
    }

    final threads = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (var i = 0; i < count - 3; i += 3) {
      final distance = (centers[i] - centers[i + 3]).distance;
      final opacity = math.min(alphas[i], alphas[i + 3]);
      if (distance < minSide * .15 && opacity > .2) {
        threads.color = lume.withAlpha((opacity * .22 * 255).round());
        canvas.drawLine(centers[i], centers[i + 3], threads);
      }
    }

    for (var i = 0; i < count; i++) {
      final alpha = alphas[i];
      if (alpha <= .015) continue;
      final color = Color.lerp(lume, const Color(0xffd3c4ff), (i % 11) / 15)!;
      final radius = 1.05 + (i % 4) * .34 + reaction * .55;
      final glow = Paint()
        ..color = color.withAlpha((alpha * (42 + reaction * 38)).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final pixel = Paint()..color = color.withAlpha((alpha * 230).round());
      canvas.drawCircle(centers[i], radius * 2.4, glow);
      canvas.drawCircle(centers[i], radius, pixel);
    }

    final core = Offset(size.width * .5, size.height * .5);
    final voiceWave = (1 - reaction.clamp(0.0, 1.0)).clamp(0.0, 1.0).toDouble();
    final waveOpacity =
        (math.sin(voiceWave * math.pi) * reaction.clamp(0.0, 1.0) * 62).round();
    if (waveOpacity > 0) {
      for (var ring = 0; ring < 2; ring++) {
        canvas.drawCircle(
          core,
          18 + voiceWave * minSide * .28 + ring * 13,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring == 0 ? 1.3 : .8
            ..color = lume.withAlpha((waveOpacity * (1 - ring * .34)).round())
            ..isAntiAlias = false,
        );
      }
    }
    final pulse =
        (reducedMotion ? 0.0 : math.sin(ambient * math.pi * 2) * 2.5) +
        reaction * 3.5;
    canvas.drawCircle(
      core,
      12 + pulse,
      Paint()
        ..color = lume.withAlpha(22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.drawCircle(
      core,
      2.5,
      Paint()..color = const Color(0xffe7ffff).withAlpha(190),
    );
  }

  @override
  bool shouldRepaint(covariant _LumeParticlePainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.transition != transition ||
      oldDelegate.ambient != ambient ||
      oldDelegate.reaction != reaction ||
      oldDelegate.reducedMotion != reducedMotion;
}

class _TutorialBeat {
  const _TutorialBeat(this.title, this.message, this.motif);

  final String title, message;
  final int motif;
}

const _storyBeats = [
  _TutorialBeat(
    'O Vale se calou',
    'As galerias já foram cheias de vozes. Depois do Silêncio, só restaram ruínas e memórias quase apagadas.',
    0,
  ),
  _TutorialBeat(
    'Uma centelha desperta',
    'O Lume se partiu. Suas partículas se juntam outra vez e mostram, sem som, o caminho que ainda pode ser lembrado.',
    1,
  ),
  _TutorialBeat(
    'As memórias ainda vivem',
    'Siga essa luz pelas ruínas, dunas e raízes. Cada Eco guarda uma lembrança capaz de devolver ao Vale parte de sua história.',
    2,
  ),
  _TutorialBeat(
    'Encontre o caminho de volta',
    'Reúna os fragmentos do Coração do Lume e alcance o farol de cada região. O caminho de volta começa com você.',
    3,
  ),
];

const _guideBeats = [
  _TutorialBeat(
    'Comece pelo menu',
    '“Continuar” leva à próxima missão disponível. “Jogar” mostra os capítulos. “Speedrun” abre o desafio cronometrado. O Guia de primeiros passos fica aqui sempre que você precisar.',
    3,
  ),
  _TutorialBeat(
    'Leia a missão',
    'Escolha um capítulo para ver o objetivo, a dificuldade e os Ecos conhecidos. Quando estiver pronto, toque em “Iniciar missão”. Capítulos futuros se abrem ao concluir o caminho anterior.',
    1,
  ),
  _TutorialBeat(
    'Explore no seu ritmo',
    'A/D ou setas movem você, Espaço pula, Shift usa o dash e F golpeia estruturas rachadas. No celular, toque em BATER. R retorna ao checkpoint. Ecos descobertos ficam no Arquivo de Memórias.',
    2,
  ),
  _TutorialBeat(
    'Volte quando quiser',
    'Perfil, Configurações, Conquistas e Classificação estão no menu. O progresso fica associado à sua conta. A narração deste guia é visual e não tem áudio.',
    4,
  ),
];
