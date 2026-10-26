import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/screens/game_screen.dart';
import 'package:echoes/game/screens/world_flow_screen.dart';

void main() {
  testWidgets(
    'chapter callbacks replace worlds, retain local results and release old input',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(theme: ThemeData.dark(), home: const WorldFlowScreen()),
        );
        await tester
            .widget<GameScreen>(find.byType(GameScreen))
            .game!
            .loaded
            .timeout(const Duration(seconds: 20));
      });
      await tester.pump();
      var screen = tester.widget<GameScreen>(find.byType(GameScreen));
      final first = screen.game!;
      first.dialogue.dismissImmediately();
      first.update(1 / 120);
      first.dialogue.dismissImmediately();
      first.clock.resume();
      final firstX = first.body.x;
      await tester.runAsync(() async {
        screen.onNextStage!();
        await tester.pump();
      });
      screen = tester.widget<GameScreen>(find.byType(GameScreen));
      final second = screen.game!;
      await tester.runAsync(
        () => second.loaded.timeout(const Duration(seconds: 20)),
      );
      await tester.pump();
      expect(first.released, isTrue);
      expect(second.stageId, 'stage_02');
      expect(second.art.level.id, 'stage_02');
      expect(second.session, same(first.session));
      expect(second.session.results.length, 1);
      expect(second.session.results.single.stageId, 'stage_01');
      first.update(.1);
      expect(first.body.x, firstX);
      expect(second.fragments.length, 7);
      expect(second.beacons.length, 6);
      second.dialogue.dismissImmediately();
      second.update(1 / 120);
      second.dialogue.dismissImmediately();
      second.setPaused(true);
      await tester.pump();
      await tester.tap(find.text('Selecionar capítulo'));
      await tester.pump();
      expect(second.released, isTrue);
      expect(find.text('ECHOES · Capítulos'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('03 · Torre do Eco'));
        await tester.pump();
      });
      final third = tester.widget<GameScreen>(find.byType(GameScreen)).game!;
      await tester.runAsync(
        () => third.loaded.timeout(const Duration(seconds: 20)),
      );
      await tester.pump();
      expect(third.art.level.id, 'stage_03');
      expect(third.body.y, 5376);
      expect(third.fragments.length, 7);
      expect(third.platforms.states.length, 4);
      expect(third.progress.echoes, isEmpty);
      expect(third.beacons.length, 6);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(third.released, isTrue);
    },
  );
}
