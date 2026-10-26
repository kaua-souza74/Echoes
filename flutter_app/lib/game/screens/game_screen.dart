import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../echoes_game.dart';
import '../hud/hud_state.dart';
import '../hud/touch_controls.dart';
import '../../dialogue/dialogue_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.game,
    this.onChooseStage,
    this.onNextStage,
    super.key,
  });
  final VoidCallback? onChooseStage, onNextStage;
  final EchoesGame? game;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final EchoesGame game;
  final focus = FocusNode(debugLabel: 'Echoes gameplay');
  @override
  void initState() {
    super.initState();
    game = widget.game ?? EchoesGame();
    WidgetsBinding.instance.addObserver(this);
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
    game.shutdown();
    focus.dispose();
    super.dispose();
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
                            : TouchControls(input: game.input),
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
                                : 'A/D ou ← → · Espaço: pulo · Shift: dash · R: retornar',
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
        ],
      ),
    ),
  );

  Widget _pauseCard(HudState state) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xd9080e19),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xff111d2b),
                border: Border.all(color: const Color(0xff34495d)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.completed ? Icons.auto_awesome : Icons.pause,
                    color: const Color(0xff84d9e8),
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
                        ? 'A luz conhece este caminho.\n${state.echoes}/${state.totalEchoes} Ecos · Farol aceso\n${game.stageId == 'stage_03' ? 'Fim do primeiro arco · O nome ainda aguarda.' : 'O próximo capítulo aguarda.'}'
                        : 'A/D ou setas: mover\nEspaço: pulo variável · Shift: dash\nEmpurre a parede para deslizar e pule para sair.\nR: voltar ao checkpoint',
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
                        game.restart();
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
                        game.restart();
                        focus.requestFocus();
                      },
                      child: const Text('Reiniciar trecho'),
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
  );
}
