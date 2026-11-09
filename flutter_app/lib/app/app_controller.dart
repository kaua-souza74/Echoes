import 'dart:async';
import 'package:flutter/foundation.dart';
import '../game/systems/run_record.dart';
import 'backend.dart';
import 'models.dart';
import 'supabase_backend.dart' show friendlyError, isSessionError;

class AppController extends ChangeNotifier {
  static const _requestTimeout = Duration(seconds: 12);

  AppController(this.backend) {
    _auth = backend.authChanges.listen(
      (user) {
        if (!_disposed && !booting && user?.id != identity?.id) {
          unawaited(_switchUser(user));
        } else if (!_disposed && !booting) {
          notifyListeners();
        }
      },
      onError: (Object error) {
        if (!_disposed) {
          if (isSessionError(error)) {
            unawaited(logout().catchError((Object _) {}));
            return;
          }
          errorMessage = friendlyError(error);
          notifyListeners();
        }
      },
    );
  }
  final EchoesBackend backend;
  late final StreamSubscription<PlayerIdentity?> _auth;
  PlayerIdentity? identity;
  PlayerSnapshot player = const PlayerSnapshot();
  bool booting = true, loading = false, _disposed = false, _flushing = false;
  String? startupError, errorMessage;
  String syncStatus = 'Salvo';
  int _epoch = 0;
  final Map<String, Future<void> Function()> _pending = {};
  int get pendingCount => _pending.length;

  Future<void> initialize() async {
    booting = true;
    startupError = null;
    notifyListeners();
    try {
      final user = await backend.restoreSession().timeout(_requestTimeout);
      await _switchUser(user);
    } catch (error) {
      startupError = friendlyError(error);
    }
    if (_disposed) return;
    booting = false;
    notifyListeners();
  }

  Future<void> _switchUser(PlayerIdentity? user) async {
    _epoch++;
    identity = user;
    player = const PlayerSnapshot();
    _pending.clear();
    _flushing = false;
    syncStatus = 'Salvo';
    errorMessage = null;
    loading = false;
    notifyListeners();
    if (user != null) await refresh();
  }

  Future<void> refresh() async {
    if (identity == null || _disposed) return;
    final epoch = _epoch;
    loading = true;
    notifyListeners();
    try {
      final result = await backend.loadPlayer().timeout(_requestTimeout);
      if (_disposed || epoch != _epoch) return;
      player = result;
      errorMessage = null;
    } catch (error) {
      if (!_disposed && epoch == _epoch) {
        if (isSessionError(error)) {
          try {
            await logout();
          } catch (_) {}
        } else {
          errorMessage = friendlyError(error);
        }
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> login(String email, String password) async {
    final user = await backend.login(email, password).timeout(_requestTimeout);
    if (identity?.id != user.id) await _switchUser(user);
  }

  Future<bool> register(String nickname, String email, String password) async {
    final user = await backend
        .register(nickname, email, password)
        .timeout(_requestTimeout);
    if (user != null && identity?.id != user.id) await _switchUser(user);
    return user != null;
  }

  Future<void> logout() async {
    await _switchUser(null);
    await backend.logout();
  }

  Future<void> updatePassword(String password) async {
    await backend.updatePassword(password);
    notifyListeners();
  }

  Future<void> startStage(
    String runId,
    String stageId,
    int version,
    String mode,
  ) async {
    final user = identity?.id;
    if (user == null || !player.unlocked(stageId)) {
      throw const BackendFailure('Este capítulo ainda não está disponível.');
    }
    if (backend.currentIdentity?.id != user) {
      await _switchUser(null);
      throw const BackendFailure('Sua sessão terminou. Entre novamente.');
    }
    try {
      await backend
          .startStage(runId, stageId, version, mode)
          .timeout(_requestTimeout);
    } catch (error) {
      if (isSessionError(error)) {
        try {
          await logout();
        } catch (_) {}
      }
      rethrow;
    }
    if (identity?.id != user) {
      throw const BackendFailure('Sua conta mudou. Abra a fase novamente.');
    }
  }

  void collectEcho(String runId, String id) =>
      _enqueue('echo:$id', () => backend.collectEcho(runId, id));
  void markDialogues(Set<String> ids) {
    if (ids.isNotEmpty) {
      _enqueue(
        'dialogues:${ids.toList()..sort()}',
        () => backend.markDialogues(ids),
      );
    }
  }

  void submitRun(String runId, RunRecord result) => _enqueue(
    'run:$runId',
    () => backend.submitRun({
      'p_run_id': runId,
      'p_stage_id': result.stageId,
      'p_version': result.stageVersion,
      'p_mode': result.mode,
      'p_duration_ms': result.durationMs < 1 ? 1 : result.durationMs,
      'p_deaths': result.deaths,
      'p_completed':
          result.completed && (result.mode != 'speedrun' || result.eligible),
      'p_collectibles': result.collectibles.toList(),
    }),
  );
  void saveSettings(GameSettings value) =>
      _enqueue('settings', () => backend.saveSettings(value));
  Future<void> answerCheck(String id, int answer) async {
    final epoch = _epoch;
    if (identity == null) {
      throw const BackendFailure('Entre novamente para salvar sua descoberta.');
    }
    await backend.answerCheck(id, answer);
    if (_epoch == epoch) await refresh();
  }

  void _enqueue(String key, Future<void> Function() operation) {
    if (identity == null || _disposed) return;
    _pending[key] = operation;
    syncStatus = 'Pendente';
    notifyListeners();
    unawaited(retryPending());
  }

  Future<void> retryPending() async {
    if (_flushing || identity == null || _disposed) return;
    final epoch = _epoch;
    final uid = identity!.id;
    _flushing = true;
    while (_pending.isNotEmpty && epoch == _epoch && !_disposed) {
      final key = _pending.keys.first;
      final operation = _pending[key]!;
      if (backend.currentIdentity?.id != uid) break;
      try {
        syncStatus = 'Salvando…';
        notifyListeners();
        await operation();
        if (epoch != _epoch || _disposed) return;
        if (identical(_pending[key], operation)) _pending.remove(key);
      } catch (error) {
        if (isSessionError(error)) {
          try {
            await logout();
          } catch (_) {}
          return;
        }
        if (epoch == _epoch && !_disposed) {
          syncStatus = 'Erro · tentar novamente';
          errorMessage = friendlyError(error);
        }
        break;
      }
    }
    if (epoch != _epoch || _disposed) return;
    _flushing = false;
    if (_pending.isEmpty) syncStatus = 'Salvo';
    notifyListeners();
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _pending.clear();
    _auth.cancel();
    backend.dispose();
    super.dispose();
  }
}
