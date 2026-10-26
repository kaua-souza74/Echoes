import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/echoes_game.dart';
import 'package:echoes/game/input/game_input.dart';
import 'package:echoes/game/config/movement_config.dart';
import 'package:echoes/game/screens/game_screen.dart';
import 'package:echoes/dialogue/dialogue_overlay.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets(
    'expanded stage loads, dialogue blocks motion, route reaches its final beacon',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = EchoesGame();
      final boundaryKey = GlobalKey();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: RepaintBoundary(
              key: boundaryKey,
              child: GameScreen(game: game),
            ),
          ),
        );
        await game.loaded.timeout(const Duration(seconds: 20));
      });
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/narrative/memory_portrait.png'),
          tester.element(find.byType(GameScreen)),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => game.ready());
      game.pauseEngine();
      game.update(MovementConfig.fixedStep);
      expect(game.art.level.solids.length, 54);
      expect(game.art.level.sections.length, 5);
      expect(game.fragments.length, 7);
      expect(game.dialogue.active, isTrue);
      final x = game.body.x;
      game.input.setKeyboard({InputAction.right});
      game.update(.1);
      expect(game.body.x, x);
      game.update(.1);
      game.update(.1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      // Review the real widget composition, including the portrait outside the panel.
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../docs/screenshots/expanded_dialogue_test.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      tester.view.physicalSize = const Size(480, 800);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(SpeakerPortrait)).top,
        lessThan(tester.getRect(find.byType(DialoguePanel)).top),
      );
      tester.view.physicalSize = const Size(1280, 720);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(game.dialogue.visibleText, game.dialogue.fullText);
      game.update(.1);
      game.update(.1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(game.dialogue.lineIndex, 1);
      await tester.tap(find.widgetWithText(TextButton, 'Pular'));
      game.update(.1);
      game.update(.1);
      await tester.pump();
      expect(game.dialogue.active, isFalse);
      var airborneTime = 0.0;
      var dashNeeded = false;
      var dashed = false;
      var release = 0;
      var previousGrounded = true;
      var lastPosition = '';
      final trace = <String>[];
      for (var frame = 0; frame < 24000 && !game.progress.completed; frame++) {
        if (game.dialogue.active) {
          game.dialogue.skip();
        }
        final b = game.body;
        var jump = false, dash = false;
        if (b.grounded) {
          if (!previousGrounded) release = 1;
          airborneTime = 0;
          dashed = false;
          final supports = game.art.level.solids
              .where(
                (s) =>
                    (b.y - s.y).abs() < 2 && b.right > s.x && b.left < s.right,
              )
              .toList();
          if (supports.isNotEmpty) {
            final support = supports.first;
            final ahead =
                game.art.level.solids
                    .where((s) => s.x >= support.right && s.y >= support.y - 88)
                    .toList()
                  ..sort((a, b) => a.x.compareTo(b.x));
            if (ahead.isNotEmpty) {
              final gap = ahead.first.x - support.right;
              dashNeeded =
                  (ahead.first.y < support.y && gap >= 70) || gap > 120;
            }
            if (release == 0 && b.x >= support.right - 28) jump = true;
          }
          if (release > 0) release--;
        } else {
          airborneTime += MovementConfig.fixedStep;
          jump = true;
          dash = dashNeeded && !dashed && airborneTime >= .25;
          if (dash) dashed = true;
        }
        previousGrounded = b.grounded;
        lastPosition =
            '${b.x},${b.y}; vx=${b.vx}, vy=${b.vy}; jump=$jump dash=$dash';
        game.input.setKeyboard({
          InputAction.right,
          if (jump) InputAction.jump,
          if (dash) InputAction.dash,
        });
        game.update(MovementConfig.fixedStep);
        if (game.movement.jumped || game.movement.landed || dash) {
          trace.add(
            'x=${b.x.round()} y=${b.y.round()} jumped=${game.movement.jumped} land=${game.movement.landed} dash=$dash',
          );
        }
        if (frame % 240 == 0) await tester.runAsync(() => game.ready());
        if (game.progress.deaths > 0) break;
      }
      await tester.runAsync(() => game.ready());
      expect(
        game.progress.deaths,
        0,
        reason: 'Before respawn: $lastPosition\n${trace.join("\n")}',
      );
      expect(game.progress.echoes, contains('echo_heart'));
      expect(
        game.progress.completed,
        isTrue,
        reason: 'Traversal stopped at ${game.body.x}, ${game.body.y}',
      );
      expect(
        game.dialogue.viewed,
        containsAll(['awakening', 'bridge', 'heart', 'passage']),
      );
      game.replayMemory('heart');
      game.update(.1);
      expect(game.dialogue.visibleCharacters, greaterThan(0));
      game.dialogue.skip();
      game.update(.1);
      game.update(.1);
      expect(game.progress.completed, isTrue);
      game.restart();
      expect(game.fragments.values.every((e) => e.isVisible), isTrue);
      expect(game.progress.echoes, isEmpty);
      game.setPaused(true);
      game.replayMemory('heart');
      expect(game.manuallyPaused, isFalse);
      expect(game.dialogue.sequence!.id, 'heart');
      expect(game.body.vx, 0);
      game.dialogue.skip();
      game.update(.1);
      game.update(.1);
      expect(game.dialogue.active, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
