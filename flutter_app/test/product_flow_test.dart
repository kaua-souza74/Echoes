import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:echoes/app/app_controller.dart';
import 'package:echoes/app/echoes_application.dart';
import 'package:echoes/narrative/memory_catalog.dart';
import 'package:echoes/narrative/memories_screen.dart';
import 'package:echoes/game/screens/game_screen.dart';
import 'support/fake_backend.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('product routes fit a narrow viewport with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final backend = FakeBackend();
    backend.accounts['A']!['settings'] = {
      'text_scale': 1.6,
      'dialogue_speed': 1.0,
    };
    await backend.login('a@example.test', 'test-pass');
    final app = AppController(backend);
    await tester.pumpWidget(EchoesApplication(controller: app));
    await frames(tester);
    final router = GoRouter.of(tester.element(find.text('Bem-vindo, Voz A.')));
    for (final route in [
      '/stages',
      '/stages/stage_01',
      '/profile',
      '/settings',
      '/leaderboard',
      '/achievements',
      '/memories',
    ]) {
      router.go(route);
      await frames(tester);
      expect(tester.takeException(), isNull, reason: route);
    }
    await app.logout();
    await frames(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
  testWidgets(
    'speedrun gameplay emits stable Echo IDs and invalidates paused attempts',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = FakeBackend();
      await backend.login('a@example.test', 'test-pass');
      final app = AppController(backend);
      await tester.pumpWidget(EchoesApplication(controller: app));
      await frames(tester);
      final router = GoRouter.of(
        tester.element(find.text('Bem-vindo, Voz A.')),
      );
      late GameScreen screen;
      await tester.runAsync(() async {
        router.go('/play/stage_01?mode=speedrun');
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        screen = tester.widget<GameScreen>(find.byType(GameScreen));
        await screen.game!.loaded.timeout(const Duration(seconds: 30));
      });
      final game = screen.game!;
      await tester.pump();
      await tester.runAsync(() => game.ready());
      game.pauseEngine();
      game.update(.01);
      expect(game.dialogue.active, false);
      final echo = game.fragments['echo_01']!;
      game.body.x = echo.x;
      game.body.y = echo.y + 16;
      game.update(.01);
      await frames(tester);
      expect(backend.writes, contains('A:echo:echo_01'));
      game.setPaused(true);
      expect(game.speedrunEligible, false);
      game.shutdown();
      await frames(tester);
      expect(game.session.results.single.eligible, false);
      expect(
        backend.writes.any(
          (w) => w.startsWith('A:run:') && w.endsWith(':false'),
        ),
        true,
      );
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
  testWidgets(
    'auth gates product routes; login reaches missions, profile and logout',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = FakeBackend();
      final app = AppController(backend);
      await tester.pumpWidget(EchoesApplication(controller: app));
      await frames(tester);
      final router = GoRouter.of(tester.element(find.text('Voltar ao Vale')));
      router.go('/profile');
      await frames(tester);
      expect(find.text('Voltar ao Vale'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'a@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'test-pass');
      await tester.tap(find.text('Entrar'));
      await frames(tester);
      expect(find.text('Bem-vindo, Voz A.'), findsOneWidget);
      router.go('/stages/stage_03');
      await frames(tester);
      expect(
        find.text('Conclua o capítulo anterior para abrir este caminho.'),
        findsOneWidget,
      );
      router.go('/profile');
      await frames(tester);
      expect(find.text('a@example.test'), findsOneWidget);
      await app.logout();
      await frames(tester);
      expect(find.text('Voltar ao Vale'), findsOneWidget);
      expect(find.text('a@example.test'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
  testWidgets(
    'archive keeps locked text private and confirms educational persistence',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const firstMemory = MemoryEntry(
        id: 'memory_echo_01',
        collectibleId: 'echo_01',
        stageId: 'stage_01',
        title: 'O pote azul',
        narrative: 'A praça das lanternas guardou esta lembrança.',
        characterOrEvent: 'Moradores',
        concept: 'Memória coletiva',
        explanation: 'As pessoas preservam histórias em conjunto.',
        illustrationAsset: 'assets/images/narrative/memory_portrait.png',
      );
      const lockedMemory = MemoryEntry(
        id: 'memory_locked',
        collectibleId: 'echo_02',
        stageId: 'stage_01',
        title: 'A praça das lanternas',
        narrative: 'Uma história que ainda não foi encontrada.',
        characterOrEvent: 'Vozes do Vale',
        concept: 'Preservação',
        explanation: 'Encontrar todas as vozes mantém o acervo vivo.',
        illustrationAsset: 'assets/images/narrative/memory_portrait.png',
      );
      const memoryCatalog = MemoryCatalog(
        entries: [firstMemory, lockedMemory],
        learningChecks: [
          MemoryLearningCheck(
            id: 'check_stage_01',
            stageId: 'stage_01',
            prompt: 'Como preservar a memória do lugar?',
            options: [
              'Ouvir e compartilhar as histórias',
              'Apagar os registros',
            ],
            correctIndex: 0,
            feedbackCorrect: 'Lembrança compreendida.',
            feedbackIncorrect: 'Ouça as pessoas da comunidade.',
            memoryIds: ['memory_echo_01'],
          ),
        ],
      );
      final submitted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MemoriesScreen(
            catalog: memoryCatalog,
            unlockedCollectibleIds: const {'echo_01'},
            completedLearningCheckIds: const {},
            onLearningAnswer: (id, answer) async {
              submitted.add('$id:$answer');
            },
          ),
        ),
      );
      await tester.tap(find.text('O pote azul'));
      await frames(tester);
      expect(find.text(memoryCatalog.entries.first.narrative), findsOneWidget);
      expect(find.text('A praça das lanternas'), findsNothing);
      await tester.ensureVisible(find.text('Aplicar esta lembrança'));
      await tester.tap(find.text('Aplicar esta lembrança'));
      await frames(tester);
      await tester.tap(
        find.text(memoryCatalog.learningChecks.first.options.first),
      );
      await tester.pump();
      await tester.tap(find.text('Responder'));
      await frames(tester);
      expect(submitted, ['check_stage_01:0']);
      expect(
        find.text(memoryCatalog.learningChecks.first.feedbackCorrect),
        findsOneWidget,
      );
      await tester.tap(find.text('Continuar'));
      await frames(tester);
      expect(find.text('Lembrança compreendida.'), findsOneWidget);
    },
  );
}
