import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/app/app_controller.dart';
import 'package:echoes/app/echoes_application.dart';
import 'package:echoes/app/models.dart';
import 'package:echoes/app/supabase_config.dart';
import 'package:echoes/game/systems/run_record.dart';
import 'support/fake_backend.dart';

Future<void> drain() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'register requires confirmation; login failure, restoration, expiry and logout',
    () async {
      final backend = FakeBackend();
      final app = AppController(backend);
      await app.initialize();
      expect(app.identity, isNull);
      expect(
        await app.register('Nova voz', 'new@example.test', 'test-pass'),
        false,
      );
      expect(app.identity, isNull);
      await expectLater(app.login('a@example.test', 'bad'), throwsException);
      await app.login('a@example.test', 'test-pass');
      await drain();
      expect(app.player.points, 120);
      backend.expire();
      await drain();
      expect(app.identity, isNull);
      expect(app.player.points, 0);
      await app.login('b@example.test', 'test-pass');
      await app.logout();
      expect(app.player.echoes, isEmpty);
      app.dispose();
      final restored = FakeBackend()
        ..identity = const PlayerIdentity('A', 'a@example.test');
      final second = AppController(restored);
      await second.initialize();
      expect(second.player.nickname, 'Voz A');
      second.dispose();
    },
  );
  test('a late response from A never publishes private data into B', () async {
    final backend = FakeBackend()
      ..identity = const PlayerIdentity('A', 'a@example.test');
    final app = AppController(backend);
    await app.initialize();
    final late = Completer<PlayerSnapshot>();
    backend.delayedLoad = late;
    final first = app.refresh();
    await app.logout();
    await app.login('b@example.test', 'test-pass');
    await drain();
    late.complete(const PlayerSnapshot(nickname: 'PRIVATE A', points: 999));
    await first;
    expect(app.identity!.id, 'B');
    expect(app.player.nickname, 'Voz B');
    expect(app.player.points, 0);
    app.dispose();
  });
  test(
    'pending writes retry idempotently and are cleared on account switch',
    () async {
      final backend = FakeBackend()
        ..identity = const PlayerIdentity('A', 'a@example.test');
      final app = AppController(backend);
      await app.initialize();
      backend.failWrites = true;
      app.collectEcho('run-A', 'echo_secret');
      await drain();
      expect(app.pendingCount, 1);
      expect(app.syncStatus, contains('Erro'));
      backend.failWrites = false;
      await app.retryPending();
      expect(app.pendingCount, 0);
      expect(backend.writes, ['A:echo:echo_secret']);
      backend.failWrites = true;
      app.collectEcho('run-A', 'echo_depths');
      await drain();
      await app.logout();
      backend.failWrites = false;
      await app.login('b@example.test', 'test-pass');
      await app.retryPending();
      expect(app.pendingCount, 0);
      expect(backend.writes.where((w) => w.startsWith('B:echo')), isEmpty);
      app.dispose();
    },
  );
  test(
    'settings and educational responses reload from the same account only',
    () async {
      final backend = FakeBackend()
        ..identity = const PlayerIdentity('A', 'a@example.test');
      final app = AppController(backend);
      await app.initialize();
      app.saveSettings(
        const GameSettings(
          dialogueSpeed: 1.5,
          showTimer: false,
          reduceEffects: true,
          textScale: 1.2,
        ),
      );
      await drain();
      expect(app.player.settings.dialogueSpeed, 1.5);
      expect(app.player.settings.showTimer, false);
      await app.answerCheck('check_stage_01', 0);
      expect(app.player.learningChecks, contains('check_stage_01'));
      await app.logout();
      await app.login('b@example.test', 'test-pass');
      await drain();
      expect(app.player.settings.dialogueSpeed, 1);
      expect(app.player.learningChecks, isEmpty);
      await app.logout();
      await app.login('a@example.test', 'test-pass');
      await drain();
      expect(app.player.settings.reduceEffects, true);
      expect(app.player.learningChecks, contains('check_stage_01'));
      app.dispose();
    },
  );
  test(
    'ineligible speedrun submits as incomplete and cannot be a record',
    () async {
      final backend = FakeBackend()
        ..identity = const PlayerIdentity('A', 'a@example.test');
      final app = AppController(backend);
      await app.initialize();
      app.submitRun(
        'paused-run',
        RunRecord(
          attemptId: 1,
          stageId: 'stage_01',
          stageVersion: 2,
          durationMs: 60000,
          deaths: 0,
          collectibles: {'echo_heart'},
          completed: true,
          mode: 'speedrun',
          eligible: false,
        ),
      );
      await drain();
      expect(backend.writes, ['A:run:paused-run:false']);
      app.dispose();
    },
  );
  test('protected redirects have no auth or splash loop', () {
    for (final path in [
      '/menu',
      '/profile',
      '/play/stage_01',
      '/settings',
      '/memories',
    ]) {
      expect(
        authRedirect(booting: false, authenticated: false, location: path),
        '/login',
      );
      expect(
        authRedirect(booting: false, authenticated: true, location: path),
        isNull,
      );
    }
    expect(
      authRedirect(booting: false, authenticated: false, location: '/login'),
      isNull,
    );
    expect(
      authRedirect(booting: false, authenticated: true, location: '/login'),
      '/intro',
    );
    expect(
      authRedirect(booting: true, authenticated: false, location: '/splash'),
      isNull,
    );
  });
  test(
    'public config rejects admin keys, malformed URLs and project mismatch',
    () {
      String key(Map data) =>
          'e30.${base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '')}.sig';
      const SupabaseConfig(
        'https://project.supabase.co',
        'sb_publishable_example',
      ).validate();
      SupabaseConfig(
        'https://project.supabase.co',
        key({'role': 'anon', 'ref': 'project'}),
      ).validate();
      expect(
        () => SupabaseConfig(
          'https://project.supabase.co',
          key({'role': 'service_role', 'ref': 'project'}),
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => SupabaseConfig(
          'https://project.supabase.co',
          key({'role': 'anon', 'ref': 'other'}),
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => const SupabaseConfig('not-a-url', 'sb_publishable_x').validate(),
        throwsFormatException,
      );
      expect(formatTime(61239), '01:01.23');
    },
  );
}
