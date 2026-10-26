import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/echoes_game.dart';
import 'package:echoes/game/screens/game_screen.dart';
import 'package:echoes/game/input/game_input.dart';
import 'package:echoes/game/levels/level_data.dart';

void main() {
  for (final id in ['stage_02', 'stage_03']) {
    testWidgets(
      '$id real physics traversal and review captures',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = EchoesGame(stageId: id);
        final key = GlobalKey();
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              home: RepaintBoundary(
                key: key,
                child: GameScreen(game: game),
              ),
            ),
          );
          await game.loaded.timeout(const Duration(seconds: 30));
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
        final data =
            jsonDecode(
                  (await tester.runAsync(
                    () => rootBundle.loadString('assets/levels/$id.json'),
                  ))!,
                )
                as Map<String, dynamic>;
        final route = data['route'] as List;
        final surfaces = [
          ...game.art.level.solids,
          ...game.art.level.temporaryPlatforms,
        ];
        Solid surface(String name) => surfaces.firstWhere((s) => s.id == name);
        Future<void> capture(String label) async {
          await tester.runAsync(() => game.ready());
          game.resumeEngine();
          await tester.pump(const Duration(milliseconds: 16));
          game.pauseEngine();
          await tester.pump();
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '../docs/screenshots/${id}_$label.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        var index = 1;
        var flight = 0.0;
        var dashed = false;
        var direction = 1;
        var jumping = false;
        var narrativeShot = false,
            midShot = false,
            complexShot = false,
            exitShot = false;
        final trace = <String>[];
        game.update(1 / 120);
        for (var i = 0; i < 30; i++) {
          game.update(1 / 120);
        }
        await capture('start');
        for (
          var frame = 0;
          frame < 80000 && !game.progress.completed;
          frame++
        ) {
          final b = game.body;
          if (game.dialogue.active) {
            if (index > route.length ~/ 2 && !narrativeShot) {
              for (var i = 0; i < 36; i++) {
                game.update(1 / 120);
              }
              await capture('narrative');
              narrativeShot = true;
            }
            game.dialogue.skip();
            game.input.clear();
            game.update(1 / 120);
            continue;
          }
          if (index >= route.length) {
            if (!exitShot) {
              await capture('exit_area');
              exitShot = true;
            }
            final goal = game.beacons.firstWhere((b) => b.isGoal);
            direction = (goal.x - b.x).sign.toInt();
            game.input.setKeyboard({
              if (direction > 0) InputAction.right,
              if (direction < 0) InputAction.left,
            });
            game.update(1 / 120);
            continue;
          }
          final node = route[index] as Map;
          var jump = false, dash = false;
          var axis = 0;
          if (node['kind'] == 'shaft') {
            final top = (node['top'] as num).toDouble();
            final exit = surface(node['exit_surface']);
            if (b.grounded &&
                (b.y - exit.y).abs() < 1 &&
                b.x > exit.x &&
                b.x < exit.right) {
              index++;
              jumping = false;
              continue;
            }
            if (b.y <= top - 2) {
              direction = node['direction'];
              jump = true;
            } else if (b.wallDirection != 0) {
              if (jumping) {
                jump = false;
                jumping = false;
                axis = b.wallDirection;
              } else {
                direction = -b.wallDirection;
                jump = true;
                jumping = true;
              }
            } else {
              jump = true;
              jumping = true;
            }
            if (axis == 0) axis = direction;
            if (!complexShot && b.y < top + 320) {
              await capture('complex');
              complexShot = true;
            }
          } else {
            final target = surface(node['surface']);
            final tx =
                (node['x'] as num?)?.toDouble() ?? target.x + target.width / 2;
            if (b.grounded &&
                (b.y - target.y).abs() < 1 &&
                (b.x - tx).abs() < 28) {
              trace.add(
                'arrived $index ${node['surface']} at ${b.x.round()},${b.y.round()}',
              );
              index++;
              flight = 0;
              dashed = false;
              jumping = false;
              game.input.clear();
              game.update(1 / 120);
              continue;
            }
            direction = (tx - b.x).sign.toInt();
            axis = direction;
            if ((tx - b.x).abs() < 10) axis = 0;
            if (b.grounded) {
              flight = 0;
              dashed = false;
              final supports = game.platforms.collisionSolids
                  .where(
                    (s) =>
                        (b.y - s.y).abs() < 1 &&
                        b.right > s.x &&
                        b.left < s.right,
                  )
                  .toList();
              if (supports.isNotEmpty) {
                final support = supports.first;
                final edge = direction > 0 ? support.right : support.x;
                if ((b.x - edge).abs() < 28 && (b.y - target.y).abs() > 1 ||
                    (b.x - edge).abs() < 28 &&
                        (target.x >= support.right ||
                            target.right <= support.x)) {
                  jump = true;
                }
              }
            } else {
              flight += 1 / 120;
              jump = true;
              final supportIndex = index - 1;
              final previous = route[supportIndex] as Map;
              final from = previous['kind'] == 'landing'
                  ? surface(previous['surface'])
                  : surface(previous['exit_surface']);
              final gap = direction > 0
                  ? target.x - from.right
                  : from.x - target.right;
              dash =
                  !dashed &&
                  flight >= .25 &&
                  ((target.y < from.y && gap >= 70) || gap > 120);
              if (dash) dashed = true;
            }
          }
          game.input.setKeyboard({
            if (axis > 0) InputAction.right,
            if (axis < 0) InputAction.left,
            if (jump) InputAction.jump,
            if (dash) InputAction.dash,
          });
          game.update(1 / 120);
          if (frame % 240 == 0) await tester.runAsync(() => game.ready());
          if (frame % 6000 == 0) {
            debugPrint("$id frame=$frame route=$index x=${b.x} y=${b.y}");
          }
          if (!midShot && index > route.length ~/ 2) {
            await capture('middle');
            midShot = true;
          }
          if (game.movement.jumped || game.movement.landed || dash) {
            trace.add(
              "node=$index x=${b.x.round()} y=${b.y.round()} jump=${game.movement.jumped} dash=$dash",
            );
          }
          if (game.progress.deaths > 0) break;
        }
        await capture('final');
        expect(
          game.progress.deaths,
          0,
          reason:
              '$id route $index x=${game.body.x} y=${game.body.y}\n${trace.join('\n')}',
        );
        expect(
          game.progress.completed,
          isTrue,
          reason:
              '$id route $index x=${game.body.x} y=${game.body.y} vx=${game.body.vx} vy=${game.body.vy} wall=${game.body.wallDirection}\n${trace.join('\n')}',
        );
        expect(game.session.results.single.completed, isTrue);
        expect(
          game.progress.echoes,
          containsAll(game.art.level.requiredEchoes),
        );
        expect(
          game.dialogue.viewed
              .where((s) => s.startsWith(id == 'stage_02' ? 'g_' : 't_'))
              .length,
          5,
        );
        game.restart();
        expect(game.progress.echoes, isEmpty);
        expect(
          game.platforms.states.every((s) => s.active && !s.armed),
          isTrue,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        expect(game.released, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
