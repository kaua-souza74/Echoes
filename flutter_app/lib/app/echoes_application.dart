import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../game/echoes_game.dart';
import '../game/levels/stage_registry.dart';
import '../game/screens/game_screen.dart';
import '../game/systems/run_record.dart';
import '../narrative/memory_catalog.dart';
import '../narrative/memories_screen.dart';
import 'app_controller.dart';
import 'screens.dart';
import 'supabase_backend.dart';
import 'widgets.dart';

String? authRedirect({
  required bool booting,
  required bool authenticated,
  required String location,
  bool startupFailed = false,
  bool passwordRecovery = false,
}) {
  if (booting || startupFailed) return location == '/splash' ? null : '/splash';
  final access = location == '/login' || location == '/register';
  if (!authenticated) return access ? null : '/login';
  if (passwordRecovery) {
    return location == '/reset-password' ? null : '/reset-password';
  }
  if (access || location == '/splash' || location == '/') return '/menu';
  return null;
}

class EchoesApplication extends StatefulWidget {
  const EchoesApplication({required this.controller, super.key});
  final AppController controller;
  @override
  State<EchoesApplication> createState() => _EchoesApplicationState();
}

class _EchoesApplicationState extends State<EchoesApplication> {
  String? _lastUser;
  late final Future<MemoryCatalog> _catalog = MemoryCatalog.load();
  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: widget.controller,
    redirect: (context, state) => authRedirect(
      booting: widget.controller.booting,
      authenticated: widget.controller.identity != null,
      location: state.uri.path,
      startupFailed: widget.controller.startupError != null,
      passwordRecovery: widget.controller.backend.passwordRecovery,
    ),
    errorBuilder: (context, state) => EchoShell(
      title: 'Caminho não encontrado',
      child: Center(
        child: EchoButton(
          'Voltar ao Vale',
          onPressed: () => context.go('/menu'),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(
        path: '/splash',
        builder: (_, _) => SplashScreen(widget.controller),
      ),
      GoRoute(path: '/login', builder: (_, _) => AuthScreen(widget.controller)),
      GoRoute(
        path: '/register',
        builder: (_, _) => AuthScreen(widget.controller, register: true),
      ),
      GoRoute(path: '/menu', builder: (_, _) => MenuScreen(widget.controller)),
      GoRoute(
        path: '/stages',
        builder: (_, _) => StagesScreen(widget.controller),
      ),
      GoRoute(
        path: '/speedrun',
        builder: (_, _) => StagesScreen(widget.controller, speedrun: true),
      ),
      GoRoute(
        path: '/stages/:id',
        builder: (_, state) {
          final stage = StageRegistry.stages
              .where((s) => s.id == state.pathParameters['id'])
              .firstOrNull;
          return stage == null
              ? const UnknownStageScreen()
              : MissionScreen(
                  widget.controller,
                  stage,
                  speedrun: state.uri.queryParameters['mode'] == 'speedrun',
                );
        },
      ),
      GoRoute(
        path: '/play/:stageId',
        builder: (_, state) {
          final stage = StageRegistry.stages
              .where((s) => s.id == state.pathParameters['stageId'])
              .firstOrNull;
          return stage == null
              ? const UnknownStageScreen()
              : PlayRoute(
                  key: ValueKey(
                    '${widget.controller.identity?.id}:${state.uri}',
                  ),
                  controller: widget.controller,
                  stage: stage,
                  speedrun: state.uri.queryParameters['mode'] == 'speedrun',
                );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => ProfileScreen(widget.controller),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => PasswordScreen(widget.controller),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => SettingsScreen(
          widget.controller,
          key: ValueKey('settings:${widget.controller.identity?.id}'),
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, _) => AchievementsScreen(widget.controller),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, _) => RankingScreen(
          widget.controller,
          key: ValueKey('ranking:${widget.controller.identity?.id}'),
        ),
      ),
      GoRoute(
        path: '/memories',
        builder: (_, _) => FutureBuilder<MemoryCatalog>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const EchoShell(
                title: 'Memórias do Reino',
                child: Center(
                  child: Text('Não foi possível abrir o arquivo de memórias.'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return MemoriesScreen(
              catalog: snapshot.data!,
              unlockedCollectibleIds: widget.controller.player.echoes,
              completedLearningCheckIds:
                  widget.controller.player.learningChecks,
              onLearningAnswer: widget.controller.answerCheck,
              onClose: () => context.go('/menu'),
            );
          },
        ),
      ),
    ],
  );
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sessionChanged);
    unawaited(widget.controller.initialize());
  }

  void _sessionChanged() {
    final user = widget.controller.identity?.id;
    if (_lastUser != null && user != null && _lastUser != user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _router.go('/menu');
      });
    }
    _lastUser = user;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => MaterialApp.router(
      title: 'ECHOES · O Vale das Vozes',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lume,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          filled: true,
          fillColor: Color(0xaa080e19),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            widget.controller.player.settings.textScale,
          ),
        ),
        child: child!,
      ),
    ),
  );
}

class PlayRoute extends StatefulWidget {
  const PlayRoute({
    required this.controller,
    required this.stage,
    required this.speedrun,
    super.key,
  });
  final AppController controller;
  final StageEntry stage;
  final bool speedrun;
  @override
  State<PlayRoute> createState() => _PlayRouteState();
}

class _PlayRouteState extends State<PlayRoute> {
  late final String? _ownerId = widget.controller.identity?.id;
  EchoesGame? _game;
  PlaySession? _session;
  String? _error;
  String _runId = '';
  int _generation = 0;
  final Set<int> _recorded = {};
  Set<String> _seen = {};
  Set<String> _awards = {};
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_accountChanged);
    unawaited(_begin());
  }

  void _accountChanged() {
    if (!mounted) return;
    final unlocked = widget.controller.player.achievements
        .where((a) => a['unlocked_at'] != null)
        .map((a) => a['id'] as String)
        .toSet();
    final added = unlocked.difference(_awards);
    _awards = unlocked;
    if (added.isNotEmpty) {
      final names = widget.controller.player.achievements
          .where((a) => added.contains(a['id']))
          .map((a) => a['title'])
          .join(' · ');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('◇ Conquista: $names')));
        }
      });
    }
    setState(() {});
  }

  Future<void> _begin() async {
    _game?.shutdown();
    _session?.removeListener(_recordRun);
    _game?.dialogue.removeListener(_dialogueChanged);
    _recorded.clear();
    _error = null;
    _game = null;
    _generation++;
    if (mounted) setState(() {});
    final generation = _generation;
    final runId = const Uuid().v4();
    try {
      await widget.controller.startStage(
        runId,
        widget.stage.id,
        widget.stage.version,
        widget.speedrun ? 'speedrun' : 'story',
      );
      if (!mounted || generation != _generation) return;
      _runId = runId;
      final p = widget.controller.player;
      _seen = Set.of(p.dialogues);
      _awards = p.achievements
          .where((a) => a['unlocked_at'] != null)
          .map((a) => a['id'] as String)
          .toSet();
      final session = PlaySession();
      session.viewedMemories.addAll(p.dialogues);
      session.discoveredCollectibles.addAll(p.echoes);
      _session = session;
      session.addListener(_recordRun);
      _game = EchoesGame(
        stageId: widget.stage.id,
        session: session,
        speedrun: widget.speedrun,
        reduceEffects: p.settings.reduceEffects,
        onEchoCollected: (id) {
          if (widget.controller.identity?.id == _ownerId) {
            widget.controller.collectEcho(runId, id);
          }
        },
      );
      _game!.dialogue.charactersPerSecond = 32 * p.settings.dialogueSpeed;
      _game!.dialogue.addListener(_dialogueChanged);
      setState(() {});
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = friendlyError(error));
      }
    }
  }

  void _recordRun() {
    for (final run in _session?.results ?? <RunRecord>[]) {
      if (_recorded.add(run.attemptId)) {
        final runId = _runId, uid = _ownerId;
        scheduleMicrotask(() {
          if (widget.controller.identity?.id == uid) {
            widget.controller.submitRun(runId, run);
          }
        });
      }
    }
  }

  void _dialogueChanged() {
    if (widget.controller.identity?.id != _ownerId) return;
    final now = _game!.dialogue.viewed;
    final added = now.difference(_seen);
    if (added.isNotEmpty) {
      _seen.addAll(added);
      widget.controller.markDialogues(added);
    }
  }

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_accountChanged);
    _game?.shutdown();
    _session?.removeListener(_recordRun);
    _game?.dialogue.removeListener(_dialogueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return EchoShell(
        title: widget.stage.title,
        back: '/stages',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              EchoButton('Tentar novamente', onPressed: _begin),
            ],
          ),
        ),
      );
    }
    final game = _game;
    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final next = widget.stage.nextId;
    return Stack(
      children: [
        GameScreen(
          key: ValueKey(_generation),
          game: game,
          showTimer: widget.controller.player.settings.showTimer,
          onChooseStage: () =>
              context.go(widget.speedrun ? '/speedrun' : '/stages'),
          onRestart: _begin,
          onNextStage: next != null && widget.controller.player.unlocked(next)
              ? () => context.go('/stages/$next')
              : null,
        ),
        Positioned(
          top: 74,
          left: 12,
          right: 12,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: const Color(0xc0080e19),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.controller.syncStatus,
                        style: const TextStyle(color: lume, fontSize: 11),
                      ),
                      if (widget.controller.pendingCount > 0)
                        TextButton(
                          onPressed: widget.controller.retryPending,
                          child: const Text('Tentar salvar'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
