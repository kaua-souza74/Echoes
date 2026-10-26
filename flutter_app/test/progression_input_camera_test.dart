import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/game/camera/camera_controller.dart';
import 'package:echoes/game/input/game_input.dart';
import 'package:echoes/game/levels/level_data.dart';
import 'package:echoes/game/systems/level_progress.dart';

void main() {
  test('collection and finish are idempotent; checkpoint never regresses', () {
    final p = LevelProgress();
    expect(p.finish(), isFalse);
    expect(p.activateCheckpoint('Galeria', 1, 544, 320), isTrue);
    expect(p.activateCheckpoint('Inicio', 0, 120, 384), isFalse);
    expect(p.collect('echo_01'), isTrue);
    expect(p.collect('echo_01'), isFalse);
    expect(p.finish(), isTrue);
    expect(p.finish(), isFalse);
    expect(p.spawnX, 544);
    expect(p.echoes.length, 1);
    p.reset();
    expect(p.echoes, isEmpty);
    expect(p.completed, isFalse);
    expect(p.spawnX, 64);
  });
  test('input retains edges until physics consumes them and merges touch', () {
    final i = GameInput();
    i.setKeyboard({InputAction.right, InputAction.jump});
    i.setTouch(InputAction.jump, true);
    expect(i.consume().jumpPressed, isTrue);
    i.setKeyboard({InputAction.right});
    final held = i.consume();
    expect(held.jumpHeld, isTrue);
    expect(held.jumpReleased, isFalse);
    i.setTouch(InputAction.jump, false);
    expect(i.consume().jumpReleased, isTrue);
    expect(i.consume().jumpReleased, isFalse);
    i.clear();
    expect(i.consume().axis, 0);
  });
  test('camera remains within world at both ends and approaches smoothly', () {
    final c = FollowCamera(worldWidth: 1280, worldHeight: 512);
    c.follow(-100, 900, 1, 0, snap: true);
    expect(c.left, 0);
    expect(c.top, 152);
    c.follow(1300, 0, 1, .016);
    expect(c.x, greaterThan(320));
    expect(c.x, lessThan(960));
    c.follow(1300, 0, 1, 0, snap: true);
    expect(c.left, 640);
    expect(c.top, 0);
  });
  test('the actual art layout yields four explicit solid platforms', () {
    final l = LevelData.fromArtJson(
      File(
        'assets/images/levels/stage_01_awakening_layout.json',
      ).readAsStringSync(),
    );
    expect(l.width, 1280);
    expect(l.height, 512);
    expect(l.solids.length, 4);
    expect(l.solids[1].x, 448);
    expect(l.solids[1].y, 320);
    expect(l.layers.map((l) => l.factor).toList(), [
      .035,
      .14,
      .34,
      .58,
      .79,
      .18,
    ]);
  });
}
