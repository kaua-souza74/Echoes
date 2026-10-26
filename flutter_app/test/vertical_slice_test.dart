import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/echoes_game.dart';
import 'package:echoes/game/input/game_input.dart';
import 'package:echoes/game/player/player_state.dart';
import 'package:echoes/game/config/movement_config.dart';
import 'package:echoes/game/screens/game_screen.dart';

void main() {
  testWidgets('bundled assets load; real simulation traverses the entire slice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = EchoesGame(slice: true);
    final boundaryKey = GlobalKey();
    // Start GameWidget and real asset I/O outside the simulated test clock.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: RepaintBoundary(
            key: boundaryKey,
            child: GameScreen(game: game),
          ),
        ),
      );
      await game.loaded.timeout(const Duration(seconds: 20));
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.runAsync(
      () => game.ready().timeout(const Duration(seconds: 10)),
    );
    game.pauseEngine();
    for (var i = 0; i < 5; i++) {
      game.update(MovementConfig.fixedStep);
    }
    expect(game.readyToPlay, isTrue);
    expect(game.player.animations[PlayerPose.run]!.frames.length, 8);
    expect(game.player.animations[PlayerPose.dash]!.frames.length, 4);
    expect(game.body.grounded, isTrue);
    expect(game.player.isMounted, isTrue);
    expect(game.camera.viewfinder.position.x, game.rig.x.roundToDouble());
    expect(game.camera.viewfinder.position.y, game.rig.y.roundToDouble());

    Future<void> capture(String name) async {
      // Let RenderGame invalidate its own repaint boundary before capture.
      // Manual simulation while the loop is paused does not schedule paint.
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../docs/screenshots/$name.png');
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('test_start');
    // Keep the same virtual world in a narrow window, with deliberate bars.
    tester.view.physicalSize = const Size(480, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(game.camera.viewport.virtualSize.x, 640);
    await capture('test_narrow_window');
    tester.view.physicalSize = const Size(1280, 720);
    await tester.pump();
    var leg = 0;
    var dashed = false;
    for (var frame = 0; frame < 1600 && !game.progress.completed; frame++) {
      final b = game.body;
      var jump = false;
      if (leg == 0 && b.x >= 316 && b.grounded) {
        jump = true;
        leg = 1;
      } else if (leg == 1 && b.x >= 606 && b.grounded) {
        jump = true;
        leg = 2;
      } else if (leg == 2 && b.x >= 838 && b.grounded) {
        jump = true;
        leg = 3;
      }
      final dash = leg == 3 && !dashed && b.x >= 890 && !b.grounded;
      if (dash) {
        dashed = true;
      }
      game.input.setKeyboard({
        InputAction.right,
        if (jump || !b.grounded) InputAction.jump,
        if (dash) InputAction.dash,
      });
      game.update(MovementConfig.fixedStep);
      if (frame % 120 == 0) {
        await tester.runAsync(() => game.ready());
      }
    }
    await tester.runAsync(() => game.ready());
    expect(
      game.progress.deaths,
      0,
      reason:
          'The authored route must be reachable with the configured jump and dash.',
    );
    expect(game.progress.checkpoint, 'Galeria');
    expect(game.progress.echoes, contains('echo_01'));
    expect(
      game.progress.completed,
      isTrue,
      reason: 'The final beacon must finish the slice after collection.',
    );
    await capture('test_finish');
    game.restart();
    expect(game.echo.isVisible, isTrue);
    expect(game.progress.echoes, isEmpty);
    // Walking into the first gap must return to the activated initial beacon.
    for (var frame = 0; frame < 800 && game.progress.deaths == 0; frame++) {
      game.input.setKeyboard({InputAction.right});
      game.update(MovementConfig.fixedStep);
    }
    expect(game.progress.deaths, 1);
    expect(game.progress.checkpoint, 'Primeira Centelha');
    expect(game.body.x, game.progress.spawnX);
    expect(game.body.y, game.progress.spawnY);
    game.setPaused(true);
    final x = game.body.x;
    game.update(.1);
    expect(game.body.x, x);
    await tester.pump();
    expect(find.text('Pausa'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(game.manuallyPaused, isFalse);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Direita')),
    );
    for (var i = 0; i < 10; i++) {
      game.update(MovementConfig.fixedStep);
    }
    expect(game.body.vx, greaterThan(0));
    await gesture.cancel();
    expect(game.input.consume().axis, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    expect(game.manuallyPaused, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    expect(game.manuallyPaused, isFalse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    for (var i = 0; i < 10; i++) {
      game.update(MovementConfig.fixedStep);
    }
    expect(game.body.vx, greaterThan(0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
