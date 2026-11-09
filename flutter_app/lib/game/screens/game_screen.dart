import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../echoes_game.dart';
import '../hud/hud_state.dart';
import '../hud/touch_controls.dart';
import '../hud/pixel_world_transition.dart';
import '../../dialogue/dialogue_overlay.dart';
import '../../app/models.dart' show formatTime;

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.game,
    this.onChooseStage,
    this.onNextStage,
    this.onRestart,
    this.onExitToMenu,
    this.showTimer = false,
    super.key,
  });
  final VoidCallback? onChooseStage, onNextStage, onExitToMenu;
  final VoidCallback? onRestart;
  final bool showTimer;
  final EchoesGame? game;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final EchoesGame game;
  final focus = FocusNode(debugLabel: 'Echoes gameplay');
  bool _showEntrance = true, _entrancePlaying = false, _exitingToMenu = false;

  bool get _isMobileNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Color get _stageAccent => switch (game.stageId) {
    'stage_02' => const Color(0xffd6a15d),
    'stage_03' => const Color(0xff83bd82),
    _ => const Color(0xff84d9e8),
  };

  Duration get _transitionDuration => game.reduceEffects
      ? const Duration(milliseconds: 360)
      : const Duration(milliseconds: 920);

  @override
  void initState() {
    super.initState();
    game = widget.game ?? EchoesGame();
    focus.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
    if (_isMobileNative) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    }
    unawaited(_revealAfterLoad());
  }

  Future<void> _revealAfterLoad() async {
    try {
      await game.loaded;
    } catch (_) {
      // Let GameWidget's error surface appear through the same entry curtain.
    }
    // `loaded` means the Flame tree is ready, but it does not guarantee that
    // its first frame has reached the canvas. Keep the pixel curtain closed
    // for two rendered Flutter frames so the reveal uncovers the live world.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (game.readyToPlay) {
      game.setPaused(true, invalidateSpeedrun: false);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _entrancePlaying = true);
  }

  void _finishEntrance() {
    if (!mounted || !_showEntrance) return;
    setState(() => _showEntrance = false);
    if (game.readyToPlay) game.setPaused(false);
    focus.requestFocus();
  }

  void _exitToMenu() {
    if (_exitingToMenu || widget.onExitToMenu == null) return;
    game.setPaused(true);
    setState(() => _exitingToMenu = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/narrative/memory_portrait.png'),
      context,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    focus.removeListener(_focusChanged);
    game.shutdown();
    focus.dispose();
    if (_isMobileNative) {
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    super.dispose();
  }

  void _focusChanged() {
    if (!focus.hasFocus && game.clock.hasStarted) {
      game.setPaused(true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      game.setPaused(true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<EchoesGame>(
              game: game,
              focusNode: focus,
              loadingBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, error) => Center(
                child: SelectableText('Falha ao carregar ECHOES:\n$error'),
              ),
            ),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<HudState>(
              valueListenable: game.hud,
              builder: (context, state, _) => Stack(
                children: [
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'E C H O E S',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xffd7f4ee),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '${game.stageId.substring(6)} / ${state.section.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.7,
                                      color: Color(0xff84d9e8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '◇ ${state.echoes}/${state.totalEchoes}',
                                    style: const TextStyle(
                                      color: Color(0xff84d9e8),
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.bolt,
                                    size: 18,
                                    color: state.dashReady
                                        ? const Color(0xff84d9e8)
                                        : const Color(0xff526b7c),
                                  ),
                                  Text(
                                    state.dashReady ? ' Pronto' : ' No ar',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  IconButton(
                                    tooltip: 'Pausar (Esc / P)',
                                    onPressed: () =>
                                        game.setPaused(!state.paused),
                                    icon: const Icon(Icons.pause, size: 20),
                                  ),
                                ],
                              ),
                              Text(
                                '${state.checkpoint} · ${state.deaths} quedas',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xffb0c3ca),
                                ),
                              ),
                              if (widget.showTimer || game.speedrun)
                                Text(
                                  '${formatTime(state.durationMs)}${game.speedrun && !game.speedrunEligible ? ' · tentativa invalidada' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xff84d9e8),
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!state.paused && !state.completed) ...[
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: game.dialogue,
                        builder: (context, _) => game.dialogue.active
                            ? const SizedBox.shrink()
                            : TouchControls.shouldShowFor(context)
                            ? TouchControls(
                                input: game.input,
                                accent: _stageAccent,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, .75),
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 160),
                          child: Text(
                            state.message.isNotEmpty
                                ? state.message
                                : (TouchControls.shouldShowFor(context)
                                      ? 'Polegar esquerdo: mover · direito: pular, dash e bater'
                                      : 'A/D ou ← → · Espaço: pular · Shift: dash · F: bater · R: checkpoint'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xffb0c3ca),
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.paused || state.completed) _pauseCard(state),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: game.dialogue,
              builder: (context, _) => game.dialogue.active
                  ? DialogueOverlay(controller: game.dialogue)
                  : const SizedBox.shrink(),
            ),
          ),
          if (_showEntrance)
            Positioned.fill(
              child: PixelWorldTransition(
                key: const ValueKey('enter-world'),
                mode: PixelWorldTransitionMode.revealWorld,
                color: _stageAccent,
                duration: _transitionDuration,
                playing: _entrancePlaying,
                onCompleted: _finishEntrance,
              ),
            ),
          if (_exitingToMenu)
            Positioned.fill(
              child: PixelWorldTransition(
                key: const ValueKey('leave-world'),
                mode: PixelWorldTransitionMode.coverWorld,
                color: _stageAccent,
                duration: _transitionDuration,
                playing: true,
                onCompleted: widget.onExitToMenu,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _pauseCard(HudState state) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xc9080e19),
      child: SafeArea(
        child: Align(
          alignment:
              MediaQuery.sizeOf(context).width >
                  MediaQuery.sizeOf(context).height
              ? Alignment.centerLeft
              : Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                decoration: BoxDecoration(
                  color: const Color(0xf2111d2b),
                  border: Border(
                    left: BorderSide(color: _stageAccent, width: 3),
                    top: const BorderSide(color: Color(0xff34495d)),
                    right: const BorderSide(color: Color(0xff34495d)),
                    bottom: const BorderSide(color: Color(0xff34495d)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _stageAccent.withAlpha(28),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      state.completed ? Icons.auto_awesome : Icons.pause,
                      color: _stageAccent,
                      size: 30,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.completed ? game.art.level.title : 'Pausa',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.completed
                          ? (game.speedrun
                                ? '${formatTime(game.clock.durationMs)} · ${state.deaths} quedas\n${game.speedrunEligible ? 'Tempo enviado como não verificado. Aguarde a confirmação de salvamento.' : 'Tentativa invalidada por pausa ou perda de foco. Reinicie para registrar um recorde.'}'
                                : 'A luz conhece este caminho.\n${state.echoes}/${state.totalEchoes} Ecos · Farol aceso\n${game.stageId == 'stage_03' ? 'Fim do primeiro arco · O nome ainda aguarda.' : 'O próximo capítulo aguarda.'}')
                          : (TouchControls.shouldShowFor(context)
                                ? 'Polegar esquerdo: mover\nPular, dash e bater: botões à direita\nBATER quebra as estruturas marcadas.'
                                : 'A/D ou setas: mover\nEspaço: pulo variável · Shift: dash · F: bater\nBATER quebra estruturas marcadas.\nR: voltar ao checkpoint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.6,
                        color: Color(0xffb0c3ca),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () {
                        if (state.completed) {
                          if (widget.onRestart != null) {
                            widget.onRestart!();
                          } else {
                            game.restart();
                          }
                        } else {
                          game.setPaused(false);
                        }
                        focus.requestFocus();
                      },
                      child: Text(
                        state.completed ? 'Jogar novamente' : 'Continuar',
                      ),
                    ),
                    if (state.completed && widget.onNextStage != null)
                      TextButton(
                        onPressed: widget.onNextStage,
                        child: const Text('Próximo capítulo'),
                      ),
                    if (widget.onChooseStage != null)
                      TextButton(
                        onPressed: widget.onChooseStage,
                        child: const Text('Selecionar capítulo'),
                      ),
                    if (!state.completed)
                      TextButton(
                        onPressed: () {
                          if (widget.onRestart != null) {
                            widget.onRestart!();
                          } else {
                            game.restart();
                          }
                          focus.requestFocus();
                        },
                        child: const Text('Reiniciar trecho'),
                      ),
                    if (widget.onExitToMenu != null)
                      TextButton.icon(
                        onPressed: _exitToMenu,
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Voltar ao menu'),
                      ),
                    for (final id in game.dialogue.viewed)
                      TextButton(
                        onPressed: () {
                          game.replayMemory(id);
                          focus.requestFocus();
                        },
                        child: Text(
                          'Rever memória · ${game.dialogue.sequences[id]!.speaker}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
