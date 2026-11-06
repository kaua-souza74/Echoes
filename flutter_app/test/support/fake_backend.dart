import 'dart:async';
import 'package:echoes/app/backend.dart';
import 'package:echoes/app/models.dart';

/// Test dependency only. Never wired to the production entrypoint.
class FakeBackend implements EchoesBackend {
  final accounts = <String, Map<String, dynamic>>{
    'A': {
      'nickname': 'Voz A',
      'points': 120,
      'stages': {'stage_01': 'completed', 'stage_02': 'available'},
      'echoes': ['echo_01', 'echo_heart'],
      'memories': ['memory_echo_01', 'memory_echo_heart'],
      'dialogues': ['awakening'],
      'settings': {'dialogue_speed': 1.0},
    },
    'B': {
      'nickname': 'Voz B',
      'points': 0,
      'stages': {'stage_01': 'available'},
      'echoes': <String>[],
      'memories': <String>[],
      'settings': {'dialogue_speed': 1.0},
    },
  };
  PlayerIdentity? identity;
  final changes = StreamController<PlayerIdentity?>.broadcast(sync: true);
  final writes = <String>[];
  bool failWrites = false, confirmationRequired = true;
  @override
  bool passwordRecovery = false;
  Completer<PlayerSnapshot>? delayedLoad;
  @override
  PlayerIdentity? get currentIdentity => identity;
  @override
  Stream<PlayerIdentity?> get authChanges => changes.stream;
  @override
  Future<PlayerIdentity?> restoreSession() async => identity;
  @override
  Future<PlayerIdentity> login(String email, String password) async {
    if (password != 'test-pass') {
      throw const BackendFailure('E-mail ou senha incorretos.');
    }
    identity = PlayerIdentity(email.startsWith('a') ? 'A' : 'B', email);
    changes.add(identity);
    return identity!;
  }

  @override
  Future<PlayerIdentity?> register(
    String nickname,
    String email,
    String password,
  ) async => confirmationRequired ? null : login(email, password);
  @override
  Future<void> logout() async {
    identity = null;
    changes.add(null);
  }

  void expire() {
    identity = null;
    changes.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> updatePassword(String password) async {
    passwordRecovery = false;
  }

  @override
  Future<PlayerSnapshot> loadPlayer() async {
    if (delayedLoad != null) {
      final pending = delayedLoad!;
      delayedLoad = null;
      return pending.future;
    }
    return PlayerSnapshot.fromJson(accounts[identity!.id]!);
  }

  void _write(String value) {
    if (failWrites) throw const BackendFailure('Sem conexão');
    writes.add('${identity!.id}:$value');
  }

  @override
  Future<void> startStage(
    String runId,
    String stageId,
    int version,
    String mode,
  ) async => _write('start:$runId');
  @override
  Future<void> collectEcho(String runId, String collectibleId) async =>
      _write('echo:$collectibleId');
  @override
  Future<void> submitRun(Map<String, dynamic> payload) async =>
      _write('run:${payload['p_run_id']}:${payload['p_completed']}');
  @override
  Future<void> markDialogues(Set<String> ids) async =>
      _write('dialogue:${ids.join(',')}');
  @override
  Future<void> answerCheck(String id, int answer) async {
    _write('check:$id:$answer');
    if (answer == 0) accounts[identity!.id]!['learning_checks'] = [id];
  }

  @override
  Future<void> saveSettings(GameSettings settings) async {
    _write('settings');
    accounts[identity!.id]!['settings'] = settings.toJson();
  }

  @override
  Future<List<RankingRow>> leaderboard(String kind, String stageId) async => [];
  @override
  void dispose() {
    changes.close();
  }
}
