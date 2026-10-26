import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'art/game_assets.dart';
import 'camera/camera_controller.dart';
import 'camera/parallax_backdrop.dart';
import 'components/checkpoint.dart';
import 'components/echo_fragment.dart';
import 'config/movement_config.dart';
import 'effects/one_shot_effect.dart';
import 'hud/hud_state.dart';
import 'input/game_input.dart';
import 'levels/ruins_level.dart';
import 'player/errante.dart';
import 'player/movement_controller.dart';
import 'player/player_state.dart';
import 'systems/level_progress.dart';
import 'systems/temporary_platforms.dart';
import 'systems/run_record.dart';
import 'components/temporary_platform_view.dart';
import '../dialogue/dialogue_controller.dart';

class EchoesGame extends FlameGame with KeyboardEvents {
  EchoesGame({
    this.slice = false,
    this.stageId = 'stage_01',
    PlaySession? session,
    AttemptClock? clock,
  }) : session = session ?? PlaySession(),
       clock = clock ?? AttemptClock(),
       super(
         camera: CameraComponent.withFixedResolution(width: 640, height: 360),
       );
  final bool slice;
  final String stageId;
  final PlaySession session;
  final AttemptClock clock;
  late int attemptId;
  bool released = false, _recorded = false;
  late TemporaryPlatforms platforms;
  late ParallaxBackdrop backdrop;
  void recordRun() {
    clock.pause();
    if (_recorded || !clock.hasStarted || !readyToPlay) return;
    session.viewedMemories.addAll(dialogue.viewed);
    session.record(
      RunRecord(
        attemptId: attemptId,
        stageId: stageId,
        stageVersion: art.level.version,
        durationMs: clock.durationMs,
        deaths: progress.deaths,
        collectibles: progress.echoes,
        completed: progress.completed,
      ),
    );
    _recorded = true;
  }

  void shutdown() {
    recordRun();
    released = true;
    input.clear();
    pauseEngine();
  }

  final dialogue = DialogueController();
  final Map<String, EchoFragment> fragments = {};
  final input = GameInput();
  final body = PlayerState();
  final movement = MovementController();
  final progress = LevelProgress();
  final hud = ValueNotifier(const HudState());
  late GameAssets art;
  late FollowCamera rig;
  late Errante player;
  late EchoFragment echo;
  final List<CheckpointBeacon> beacons = [];
  bool readyToPlay = false, manuallyPaused = false;
  double _accumulator = 0, _dustTime = 0, _trailTime = 0, _messageTime = 4;
  String _message = 'Colete o Eco e encontre o farol adiante.';

  @override
  Color backgroundColor() => const Color(0xff080e19);

  @override
  Future<void> onLoad() async {
    art = GameAssets(images);
    await art.load(slice: slice, stageId: stageId);
    attemptId = session.allocateAttempt();
    platforms = TemporaryPlatforms(
      art.level.solids,
      art.level.temporaryPlatforms,
    );
    progress.reset(spawnX: art.level.spawnX, spawnY: art.level.spawnY);
    body.respawn(art.level.spawnX, art.level.spawnY);
    dialogue.load(
      await rootBundle.loadString('assets/narrative/dialogues.json'),
    );
    dialogue.viewed.addAll(session.viewedMemories);
    rig = FollowCamera(
      lookAhead: art.level.lookAhead,
      followRate: art.level.followRate,
      worldWidth: art.level.width,
      worldHeight: art.level.height,
    );
    rig.follow(body.x, body.y, body.facing, 0, snap: true);
    backdrop = ParallaxBackdrop(art, rig);
    await camera.backdrop.add(backdrop);
    await world.add(RuinsLevel(art, rig));
    await world.add(TemporaryPlatformView(art, platforms, rig));
    player = Errante(art);
    await world.add(player);
    for (final prop in art.level.props) {
      if (prop.type == 'echo') {
        final fragment = EchoFragment(art, x: prop.x, y: prop.y);
        if (fragments.isEmpty) echo = fragment;
        fragments[prop.id.isEmpty ? 'echo_01' : prop.id] = fragment;
        await world.add(fragment);
      } else {
        final goal = prop.type == 'checkpoint_final';
        final beacon = CheckpointBeacon(
          art,
          x: prop.x,
          y: prop.y,
          label: prop.label.isNotEmpty
              ? prop.label
              : (goal ? 'Farol do Lume' : 'Primeira Centelha'),
          order: slice ? (goal ? 2 : 0) : prop.order,
          isGoal: goal,
        );
        beacons.add(beacon);
        await world.add(beacon);
      }
    }
    if (slice) {
      final mid = CheckpointBeacon(
        art,
        x: 544,
        y: 320,
        label: 'Galeria',
        order: 1,
      );
      beacons.add(mid);
      await world.add(mid);
    }
    readyToPlay = true;
    _syncVisuals();
  }

  @override
  void update(double dt) {
    if (released || !readyToPlay || manuallyPaused) {
      return;
    }
    final elapsed = dt.clamp(0.0, .1);
    if (dialogue.active) {
      clock.pause();
      dialogue.tick(elapsed);
      session.viewedMemories.addAll(dialogue.viewed);
      input.clear();
      _accumulator = 0;
      super.update(elapsed);
      return;
    }
    if (progress.completed) {
      super.update(elapsed);
      return;
    }
    clock.resume();
    _accumulator += elapsed;
    while (_accumulator >= MovementConfig.fixedStep) {
      _simulate(MovementConfig.fixedStep);
      _accumulator -= MovementConfig.fixedStep;
      if (progress.completed || dialogue.active) {
        _accumulator = 0;
        break;
      }
    }
    _syncVisuals();
    super.update(elapsed);
  }

  void _simulate(double dt) {
    movement.step(body, input.consume(), platforms.collisionSolids, dt);
    platforms.tick(body, dt);
    for (final event in art.level.ambientEvents) {
      if (body.x >= event.x &&
          body.x <= event.x + event.width &&
          body.y >= event.y &&
          body.y <= event.y + event.height) {
        backdrop.trigger(event.id);
      }
    }
    body.x = body.x.clamp(7.0, art.level.width - 7);
    _messageTime = math.max(0, _messageTime - dt);
    _dustTime -= dt;
    _trailTime -= dt;
    if (movement.jumped ||
        movement.landed ||
        (body.grounded && body.vx.abs() > 70 && _dustTime <= 0)) {
      world.add(OneShotEffect(art, 'dust', x: body.x, y: body.y - 6));
      _dustTime = .16;
    }
    if (movement.abilities.dashing && _trailTime <= 0) {
      world.add(
        OneShotEffect(
          art,
          'trail',
          x: body.x - body.facing * 24,
          y: body.y - 19,
          facing: body.facing,
        ),
      );
      _trailTime = .04;
    }
    for (final beacon in beacons) {
      if ((body.x - beacon.x).abs() > 25 || (body.y - beacon.y).abs() > 24) {
        continue;
      }
      if (beacon.isGoal) {
        final ending = art.level.finalSequence;
        if (ending.isNotEmpty &&
            art.level.requiredEchoes.every(progress.echoes.contains) &&
            !dialogue.viewed.contains(ending)) {
          if (dialogue.start(ending)) {
            body.vx = body.vy = 0;
            clock.pause();
            input.clear();
          }
          continue;
        }
        if (progress.finish(requiredEchoes: art.level.requiredEchoes)) {
          recordRun();
          input.clear();
          _say('A luz conhece este caminho.');
        } else if (!progress.completed && _messageTime <= 0) {
          _say('Há um Eco essencial aguardando nesta região.');
        }
      } else if (body.grounded &&
          progress.activateCheckpoint(
            beacon.label,
            beacon.order,
            beacon.x,
            beacon.y,
          )) {
        _say('Checkpoint aceso · ${beacon.label}');
        world.add(OneShotEffect(art, 'collect', x: beacon.x, y: beacon.y - 32));
      }
    }
    for (final entry in fragments.entries) {
      final fragment = entry.value;
      if (fragment.isVisible &&
          (body.x - fragment.x).abs() < 22 &&
          (body.y - 16 - fragment.y).abs() < 28) {
        if (progress.collect(entry.key)) {
          fragment.isVisible = false;
          world.add(
            OneShotEffect(art, 'collect', x: fragment.x, y: fragment.y),
          );
          _say('Eco encontrado · A pedra guarda o que a voz esqueceu.');
        }
      }
    }
    for (final trigger in art.level.narrativeTriggers) {
      if (body.grounded &&
          (body.x - trigger.x).abs() < trigger.radius &&
          (body.y - trigger.y).abs() < trigger.verticalRadius &&
          dialogue.start(trigger.sequence)) {
        body.vx = body.vy = 0;
        clock.pause();
        input.clear();
        break;
      }
    }
    if (body.y > art.level.height + 64 ||
        body.y > progress.spawnY + art.level.checkpointFallLimit) {
      respawn();
    }
    rig.follow(body.x, body.y, body.facing, dt);
  }

  void _syncVisuals() {
    player.sync(body, movement.pose(body));
    // Viewfinder.position returns a derived vector; assign through its setter.
    camera.viewfinder.position = Vector2(
      rig.x.roundToDouble(),
      rig.y.roundToDouble(),
    );
    for (final b in beacons) {
      b.illuminate(
        b.isGoal
            ? art.level.requiredEchoes.every(progress.echoes.contains)
            : progress.checkpointOrder >= b.order,
      );
    }
    final state = HudState(
      echoes: progress.echoes.length,
      totalEchoes: fragments.length,
      section:
          art.level.sections
              .where((s) => s.contains(body.x, body.y))
              .firstOrNull
              ?.name ??
          art.level.title,
      deaths: progress.deaths,
      checkpoint: progress.checkpoint,
      dashReady: movement.abilities.dashAvailable,
      completed: progress.completed,
      paused: manuallyPaused,
      message: _messageTime > 0 ? _message : '',
    );
    if (state.signature != hud.value.signature) {
      hud.value = state;
    }
  }

  void _say(String message) {
    _message = message;
    _messageTime = 3.2;
  }

  void respawn() {
    if (!readyToPlay || progress.completed || dialogue.active) {
      return;
    }
    progress.deaths++;
    body.respawn(progress.spawnX, progress.spawnY);
    movement.abilities.reset();
    input.clear();
    rig.follow(body.x, body.y, body.facing, 0, snap: true);
    _say('O Lume guarda seu caminho.');
    _syncVisuals();
  }

  void restart() {
    if (!readyToPlay) {
      return;
    }
    recordRun();
    attemptId = session.allocateAttempt();
    _recorded = false;
    clock.reset();
    platforms.reset();
    backdrop.resetEvents();
    dialogue.dismissImmediately();
    progress.reset(spawnX: art.level.spawnX, spawnY: art.level.spawnY);
    body.respawn(art.level.spawnX, art.level.spawnY);
    movement.abilities.reset();
    input.clear();
    for (final fragment in fragments.values) {
      fragment.isVisible = true;
    }
    manuallyPaused = false;
    _accumulator = 0;
    for (final effect in world.children.whereType<OneShotEffect>().toList()) {
      effect.removeFromParent();
    }
    rig.follow(body.x, body.y, body.facing, 0, snap: true);
    _say('Colete o Eco e encontre o farol adiante.');
    _syncVisuals();
  }

  void setPaused(bool value) {
    if (!readyToPlay || progress.completed || dialogue.active) {
      return;
    }
    manuallyPaused = value;
    if (value) clock.pause();
    input.clear();
    _accumulator = 0;
    _syncVisuals();
  }

  void replayMemory(String id) {
    if (!readyToPlay || dialogue.active) return;
    manuallyPaused = false;
    _accumulator = 0;
    input.clear();
    body.vx = body.vy = 0;
    clock.pause();
    dialogue.start(id, replay: true);
    _syncVisuals();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (dialogue.active) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          dialogue.advance();
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) dialogue.skip();
      }
      input.clear();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.keyP)) {
      setPaused(!manuallyPaused);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      if (progress.completed) {
        restart();
      } else if (!manuallyPaused) {
        respawn();
      }
      return KeyEventResult.handled;
    }
    if (manuallyPaused || progress.completed) {
      return KeyEventResult.handled;
    }
    input.setKeyboard({
      if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
          keysPressed.contains(LogicalKeyboardKey.arrowLeft))
        InputAction.left,
      if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
          keysPressed.contains(LogicalKeyboardKey.arrowRight))
        InputAction.right,
      if (keysPressed.contains(LogicalKeyboardKey.space)) InputAction.jump,
      if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
          keysPressed.contains(LogicalKeyboardKey.shiftRight))
        InputAction.dash,
    });
    return KeyEventResult.handled;
  }
}
