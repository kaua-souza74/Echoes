import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';
import 'models.dart';

class SupabaseBackend implements EchoesBackend {
  SupabaseBackend(this.client);
  final SupabaseClient client;
  @override
  bool passwordRecovery = false;
  static const _redirect = String.fromEnvironment('SUPABASE_AUTH_REDIRECT_URL');
  PlayerIdentity _identity(User user) =>
      PlayerIdentity(user.id, user.email ?? '');
  @override
  PlayerIdentity? get currentIdentity =>
      client.auth.currentUser == null ||
          client.auth.currentSession?.isExpired == true
      ? null
      : _identity(client.auth.currentUser!);
  @override
  Stream<PlayerIdentity?> get authChanges =>
      client.auth.onAuthStateChange.map((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          passwordRecovery = true;
        }
        return state.session == null || state.session!.isExpired
            ? null
            : _identity(state.session!.user);
      });
  @override
  Future<PlayerIdentity?> restoreSession() async {
    if (client.auth.currentSession == null) return null;
    try {
      final user = (await client.auth.getUser()).user;
      return user == null ? null : _identity(user);
    } on AuthException catch (error) {
      if (error.statusCode == '401' || error.statusCode == '403') {
        await client.auth.signOut(scope: SignOutScope.local);
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<PlayerIdentity> login(String email, String password) async =>
      _identity(
        (await client.auth.signInWithPassword(
          email: email,
          password: password,
        )).user!,
      );
  @override
  Future<PlayerIdentity?> register(
    String nickname,
    String email,
    String password,
  ) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'nickname': nickname},
      emailRedirectTo: _redirect.isEmpty ? null : _redirect,
    );
    return response.session == null ? null : _identity(response.user!);
  }

  @override
  Future<void> logout() async {
    passwordRecovery = false;
    await client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  Future<void> resetPassword(String email) => client.auth.resetPasswordForEmail(
    email,
    redirectTo: _redirect.isEmpty ? null : _redirect,
  );
  @override
  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
    passwordRecovery = false;
  }

  @override
  Future<PlayerSnapshot> loadPlayer() async {
    await client.rpc('echoes_bootstrap');
    final data = await client.rpc('echoes_player_state');
    return PlayerSnapshot.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> startStage(
    String runId,
    String stageId,
    int version,
    String mode,
  ) async {
    await client.rpc(
      'echoes_start_stage',
      params: {
        'p_run_id': runId,
        'p_stage_id': stageId,
        'p_version': version,
        'p_mode': mode,
      },
    );
  }

  @override
  Future<void> collectEcho(String runId, String collectibleId) async {
    await client.rpc(
      'echoes_collect_echo',
      params: {'p_run_id': runId, 'p_collectible_id': collectibleId},
    );
  }

  @override
  Future<void> submitRun(Map<String, dynamic> payload) async {
    await client.rpc('echoes_record_stage_run', params: payload);
  }

  @override
  Future<void> markDialogues(Set<String> ids) async {
    await client.rpc(
      'echoes_record_dialogues',
      params: {'p_dialogues': ids.toList()},
    );
  }

  @override
  Future<void> answerCheck(String id, int answer) async {
    await client.rpc(
      'echoes_answer_learning_check',
      params: {'p_check_id': id, 'p_answer': answer},
    );
  }

  @override
  Future<void> saveSettings(GameSettings settings) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const BackendFailure('Sua sessão terminou. Entre novamente.');
    }
    await client.from('player_settings').upsert({
      'user_id': uid,
      ...settings.toJson(),
    });
  }

  @override
  Future<List<RankingRow>> leaderboard(String kind, String stageId) async {
    final data = await client.rpc(
      'echoes_leaderboard',
      params: {'p_kind': kind, 'p_stage_id': stageId},
    );
    return (data as List)
        .map((v) => RankingRow.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  @override
  void dispose() {}
}

bool isSessionError(Object error) =>
    (error is AuthException &&
        (error.statusCode == '401' || error.statusCode == '403')) ||
    (error is PostgrestException &&
        ['PGRST301', 'PGRST302', 'PGRST303'].contains(error.code));

String friendlyError(Object error) {
  if (isSessionError(error)) return 'Sua sessão terminou. Entre novamente.';
  if (error is BackendFailure) return error.message;
  if (error is TimeoutException) {
    return 'A conexão demorou mais que o esperado. Tente novamente.';
  }
  final diagnostic = error.toString().toLowerCase();
  if (diagnostic.contains('failed host lookup') ||
      diagnostic.contains('socketexception') ||
      diagnostic.contains('connection refused') ||
      diagnostic.contains('network is unreachable') ||
      diagnostic.contains('connection reset')) {
    return 'Não foi possível alcançar o Supabase. Confira a internet e se o projeto continua ativo.';
  }
  if (error is PostgrestException) {
    final code = error.code ?? 'sem código';
    final message = error.message.trim();
    if (code == 'PGRST202' || code == '42883') {
      return 'O Supabase não encontrou uma função necessária ($code). Confira se o SQL foi aplicado neste projeto e se a API atualizou o schema. $message';
    }
    if (code == '42P01' || code == '42703') {
      return 'O banco está sem uma tabela ou coluna esperada ($code). Confira a migration aplicada. $message';
    }
    if (code == '42501') {
      return 'O banco recusou esta operação ($code). Confira as permissões e políticas RLS da conta. $message';
    }
    return 'Falha no Supabase ($code): $message';
  }
  if (error is AuthException) {
    final text = error.message.toLowerCase();
    if (text.contains('invalid login')) return 'E-mail ou senha incorretos.';
    if (text.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (text.contains('already registered')) {
      return 'Este e-mail já foi cadastrado.';
    }
    if (text.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
    }
    return 'Falha no Supabase Auth${error.statusCode == null ? '' : ' (${error.statusCode})'}: ${error.message}';
  }
  return 'Não foi possível conectar. Seu progresso só será marcado como salvo após confirmação. Tente novamente. (${error.runtimeType})';
}
