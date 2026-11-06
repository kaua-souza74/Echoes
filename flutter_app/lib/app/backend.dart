import 'models.dart';

abstract class EchoesBackend {
  PlayerIdentity? get currentIdentity;
  Stream<PlayerIdentity?> get authChanges;
  bool get passwordRecovery;
  Future<PlayerIdentity?> restoreSession();
  Future<PlayerIdentity> login(String email, String password);

  /// Null means that email confirmation is required.
  Future<PlayerIdentity?> register(
    String nickname,
    String email,
    String password,
  );
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String password);
  Future<PlayerSnapshot> loadPlayer();
  Future<void> startStage(
    String runId,
    String stageId,
    int version,
    String mode,
  );
  Future<void> collectEcho(String runId, String collectibleId);
  Future<void> submitRun(Map<String, dynamic> payload);
  Future<void> markDialogues(Set<String> ids);
  Future<void> answerCheck(String id, int answer);
  Future<void> saveSettings(GameSettings settings);
  Future<List<RankingRow>> leaderboard(String kind, String stageId);
  void dispose();
}

class BackendFailure implements Exception {
  const BackendFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
