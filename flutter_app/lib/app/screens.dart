import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../game/levels/stage_registry.dart';
import 'app_controller.dart';
import 'models.dart';
import 'supabase_backend.dart';
import 'widgets.dart';

class UnknownStageScreen extends StatelessWidget {
  const UnknownStageScreen({super.key});
  @override
  Widget build(BuildContext context) => EchoShell(
    title: 'Capítulo não encontrado',
    back: '/stages',
    child: Center(
      child: EchoButton(
        'Escolher um capítulo',
        onPressed: () => context.go('/stages'),
      ),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) => EchoShell(
    title: '',
    back: null,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ECHOES',
            style: TextStyle(
              fontSize: 48,
              letterSpacing: 12,
              color: lume,
              fontWeight: FontWeight.w200,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Toda voz deixa uma luz.'),
          const SizedBox(height: 28),
          if (controller.booting) ...[
            const LinearProgressIndicator(color: lume),
            const SizedBox(height: 12),
            const Text('Conectando ao Vale…'),
          ] else ...[
            Text(
              controller.startupError ?? 'Não foi possível abrir o Vale.',
              textAlign: TextAlign.center,
            ),
            EchoButton('Tentar novamente', onPressed: controller.initialize),
          ],
        ],
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen(this.controller, {this.register = false, super.key});
  final AppController controller;
  final bool register;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _nickname = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validEmail(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Informe um e-mail válido.';
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (widget.register) {
        final logged = await widget.controller.register(
          _nickname.text.trim(),
          _email.text.trim(),
          _password.text,
        );
        if (!mounted) return;
        if (!logged) {
          setState(
            () => _message =
                'Confira seu e-mail e confirme o cadastro antes de entrar.',
          );
          return;
        }
      } else {
        await widget.controller.login(_email.text.trim(), _password.text);
      }
      if (mounted) context.go('/intro');
    } catch (error) {
      if (mounted) setState(() => _message = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recover() async {
    final invalid = _validEmail(_email.text);
    if (invalid != null) {
      setState(() => _message = invalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.backend.resetPassword(_email.text.trim());
      if (mounted) {
        setState(
          () => _message =
              'Se o endereço estiver cadastrado, você receberá as instruções de recuperação.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => EchoShell(
    title: widget.register ? 'Uma nova voz' : 'Voltar ao Vale',
    back: null,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: EchoPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'E C H O E S',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      color: lume,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.register
                        ? 'Seu caminho e suas descobertas pertencem à sua conta.'
                        : 'Entre para reencontrar suas memórias.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  if (widget.register) ...[
                    TextFormField(
                      controller: _nickname,
                      enabled: !_busy,
                      autofillHints: const [AutofillHints.nickname],
                      decoration: const InputDecoration(labelText: 'Apelido'),
                      validator: (v) =>
                          (v?.trim().length ?? 0) < 2 ||
                              (v?.trim().length ?? 0) > 24
                          ? 'Use de 2 a 24 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: _validEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    autofillHints: [
                      widget.register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (v) => widget.register
                        ? ((v?.length ?? 0) < 8
                              ? 'Use pelo menos 8 caracteres.'
                              : null)
                        : ((v?.isEmpty ?? true) ? 'Informe sua senha.' : null),
                    onFieldSubmitted: (_) {
                      if (!_busy) _submit();
                    },
                  ),
                  if (widget.register) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (v) => v == _password.text
                          ? null
                          : 'As senhas precisam ser iguais.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: lume),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_busy) const LinearProgressIndicator(),
                  EchoButton(
                    widget.register ? 'Criar conta' : 'Entrar',
                    onPressed: _busy ? null : _submit,
                    icon: Icons.login,
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.go(
                            widget.register ? '/login' : '/register',
                          ),
                    child: Text(
                      widget.register
                          ? 'Já tenho uma conta'
                          : 'Criar minha conta',
                    ),
                  ),
                  if (!widget.register)
                    TextButton(
                      onPressed: _busy ? null : _recover,
                      child: const Text('Esqueci minha senha'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen(this.controller, {super.key});
  final AppController controller;
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.updatePassword(_password.text);
      if (mounted) context.go('/menu');
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => EchoShell(
    title: 'Recuperar seu caminho',
    back: null,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: EchoPanel(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Escolha uma nova senha para sua conta.'),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (v) => (v?.length ?? 0) < 8
                      ? 'Use pelo menos 8 caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                  ),
                  validator: (v) => v == _password.text
                      ? null
                      : 'As senhas precisam ser iguais.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!),
                  ),
                if (_saving) const LinearProgressIndicator(),
                EchoButton(
                  'Salvar nova senha',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SyncNotice extends StatelessWidget {
  const SyncNotice(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (controller.loading) const LinearProgressIndicator(minHeight: 2),
      if (controller.errorMessage != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: lume),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.pendingCount > 0) {
                    controller.retryPending();
                  } else {
                    controller.refresh();
                  }
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      if (controller.pendingCount > 0)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${controller.syncStatus} · ${controller.pendingCount} operação(ões). Mantenha a sessão aberta para tentar novamente.',
          ),
        ),
    ],
  );
}

class MenuScreen extends StatelessWidget {
  const MenuScreen(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final p = controller.player;
    final available = StageRegistry.stages
        .where((s) => p.unlocked(s.id))
        .toList();
    final continuing =
        available.where((s) => !p.completed(s.id)).firstOrNull ??
        available.lastOrNull;
    return EchoShell(
      title: 'O Vale das Vozes',
      back: null,
      reduceEffects: p.settings.reduceEffects,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final sideWidth = constraints.maxWidth >= 1000 ? 420.0 : 360.0;
          return Stack(
            children: [
              if (wide)
                Positioned.fill(
                  left: sideWidth,
                  child: _FeaturedStage(
                    stage: continuing,
                    onOpen: () => context.go(
                      continuing == null
                          ? '/stages'
                          : '/stages/${continuing.id}',
                    ),
                  ),
                ),
              Align(
                alignment: wide ? Alignment.centerLeft : Alignment.topCenter,
                child: SizedBox(
                  width: wide ? sideWidth : constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Container(
                    decoration: wide
                        ? BoxDecoration(
                            color: ink.withAlpha(226),
                            border: const Border(
                              right: BorderSide(color: stone),
                            ),
                          )
                        : null,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SyncNotice(controller),
                          const SizedBox(height: 10),
                          Text(
                            'Bem-vindo ao Vale.',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sua jornada começa onde as memórias ainda brilham.',
                          ),
                          const SizedBox(height: 24),
                          const _MenuSectionLabel('SEU PROGRESSO'),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ProgressCard(
                                label: 'Pontos',
                                value: '${p.points}',
                              ),
                              ProgressCard(
                                label: 'Ecos',
                                value: '${p.echoes.length} / 21',
                              ),
                              ProgressCard(
                                label: 'Capítulos',
                                value:
                                    '${p.stages.values.where((v) => v == 'completed').length} / 3',
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const _MenuSectionLabel('JOGAR'),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: lume,
                                foregroundColor: ink,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                                shape: const RoundedRectangleBorder(),
                              ),
                              onPressed: () => context.go(
                                continuing == null
                                    ? '/stages'
                                    : '/stages/${continuing.id}',
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    continuing == null
                                        ? 'Escolher capítulo'
                                        : 'Continuar jornada',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (continuing != null)
                                    Text(
                                      'Capítulo ${continuing.order}: ${continuing.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: lume,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: stone),
                                shape: const RoundedRectangleBorder(),
                              ),
                              onPressed: () => context.go('/stages'),
                              icon: const Icon(Icons.map_outlined),
                              label: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Jogar · escolher capítulo'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _MenuSectionLabel('EXPLORAR'),
                          _MenuActionGrid(
                            width: wide ? sideWidth : constraints.maxWidth,
                            actions: [
                              _MenuAction(
                                'Speedrun',
                                Icons.timer_outlined,
                                () => context.go('/speedrun'),
                              ),
                              _MenuAction(
                                'Memórias',
                                Icons.auto_stories,
                                () => context.go('/memories'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const _MenuSectionLabel('PROGRESSO'),
                          _MenuActionGrid(
                            width: wide ? sideWidth : constraints.maxWidth,
                            actions: [
                              _MenuAction(
                                'Classificação',
                                Icons.leaderboard_outlined,
                                () => context.go('/leaderboard'),
                              ),
                              _MenuAction(
                                'Conquistas',
                                Icons.auto_awesome,
                                () => context.go('/achievements'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const _MenuSectionLabel('CONTA E AJUDA'),
                          _MenuActionGrid(
                            width: wide ? sideWidth : constraints.maxWidth,
                            actions: [
                              _MenuAction(
                                'Guia de primeiros passos',
                                Icons.help_outline,
                                () => context.go('/guide'),
                              ),
                              _MenuAction(
                                'Perfil',
                                Icons.person_outline,
                                () => context.go('/profile'),
                              ),
                              _MenuAction(
                                'Configurações',
                                Icons.settings_outlined,
                                () => context.go('/settings'),
                              ),
                              _MenuAction(
                                'Sair da conta',
                                Icons.logout,
                                () async {
                                  try {
                                    await controller.logout();
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(friendlyError(error)),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xff9eafb9),
        fontSize: 10,
        letterSpacing: 1.7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MenuAction {
  const _MenuAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _MenuActionGrid extends StatelessWidget {
  const _MenuActionGrid({required this.width, required this.actions});
  final double width;
  final List<_MenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final itemWidth = ((width - 48 - 10) / 2).clamp(132.0, 220.0).toDouble();
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final action in actions)
          SizedBox(
            width: itemWidth,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffd2dde4),
                backgroundColor: const Color(0x99111d2b),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 56),
                side: const BorderSide(color: Color(0xff34495d)),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: action.onPressed,
              icon: Icon(action.icon, size: 17, color: lume),
              label: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedStage extends StatefulWidget {
  const _FeaturedStage({required this.stage, required this.onOpen});
  final StageEntry? stage;
  final VoidCallback onOpen;

  @override
  State<_FeaturedStage> createState() => _FeaturedStageState();
}

class _FeaturedStageState extends State<_FeaturedStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final art = switch (stage?.id) {
      'stage_02' => 'assets/images/parallax/stage_02/stage_02_visual_study.png',
      'stage_03' => 'assets/images/parallax/stage_03/stage_03_visual_study.png',
      _ =>
        stage?.preview ??
            'assets/images/parallax/stage_01/03_mid_architecture.png',
    };
    final accent = switch (stage?.id) {
      'stage_02' => const Color(0xffd6a15d),
      'stage_03' => const Color(0xff83bd82),
      _ => lume,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 20, 16),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.015 + _motion.value * .035,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  child: Image.asset(
                    art,
                    key: ValueKey(art),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55080e19),
                      Color(0x22080e19),
                      Color(0xe6080e19),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 20,
                child: Text(
                  'A JORNADA CONTINUA',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stage?.category ?? 'Memória e identidade',
                      style: TextStyle(color: accent, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage?.title ?? 'O Despertar',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage?.description ??
                          'Siga o Lume pelas ruínas e descubra como um objeto pode guardar parte de uma vida.',
                      style: const TextStyle(
                        color: Color(0xffd1d9d8),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    EchoButton(
                      stage == null ? 'Ver capítulos' : 'Entrar no capítulo',
                      onPressed: widget.onOpen,
                      icon: Icons.play_arrow_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StagesScreen extends StatelessWidget {
  const StagesScreen(this.controller, {this.speedrun = false, super.key});
  final AppController controller;
  final bool speedrun;
  @override
  Widget build(BuildContext context) => EchoShell(
    title: speedrun ? 'Speedrun · caminhos do Lume' : 'Capítulos do Vale',
    reduceEffects: controller.player.settings.reduceEffects,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SyncNotice(controller),
          if (speedrun)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'O relógio começa ao ganhar controle. Pausar ou perder o foco invalida o recorde. Diálogos automáticos são omitidos. Tempos enviados pelo cliente são não verificados.',
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final stage in StageRegistry.stages)
                StageCard(
                  stage: stage,
                  status: stageStatus(controller.player.stages[stage.id]),
                  best: _best(controller.player, stage.id),
                  onPressed: () => context.go(
                    '/stages/${stage.id}${speedrun ? '?mode=speedrun' : ''}',
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

int? _best(PlayerSnapshot p, String stageId) => p.bests
    .where(
      (v) =>
          v['stage_id'] == stageId &&
          v['stage_version'] == StageRegistry.get(stageId).version,
    )
    .map((v) => (v['duration_ms'] as num).toInt())
    .firstOrNull;

class MissionScreen extends StatelessWidget {
  const MissionScreen(
    this.controller,
    this.stage, {
    this.speedrun = false,
    super.key,
  });
  final AppController controller;
  final StageEntry stage;
  final bool speedrun;
  @override
  Widget build(BuildContext context) {
    final enabled = controller.player.unlocked(stage.id);
    return EchoShell(
      title: stage.title,
      back: speedrun ? '/speedrun' : '/stages',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: EchoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.asset(
                  stage.preview,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                stage.objective,
                style: const TextStyle(fontSize: 24, color: lume),
              ),
              const SizedBox(height: 14),
              Text(stage.description),
              const SizedBox(height: 18),
              Text(
                'Dificuldade: ${stage.difficulty}\nCategoria: ${stage.category}\nEstado: ${stageStatus(controller.player.stages[stage.id])}\nRecompensa: 100 pontos na primeira conclusão + 10 por Eco único\nExploração: 7 Ecos · versão ${stage.version}\nModo: ${speedrun ? 'Speedrun' : 'História'}',
                style: const TextStyle(height: 1.8),
              ),
              const SizedBox(height: 18),
              const Text(
                'A/D ou setas: mover · Espaço: pulo variável · Shift: dash\nEmpurre a parede para deslizar e pule para sair. R retorna ao checkpoint.\nExplore com calma; as memórias descobertas ficam no arquivo da sua conta.',
                style: TextStyle(height: 1.7),
              ),
              if (!enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Conclua o capítulo anterior para abrir este caminho.',
                    style: TextStyle(color: lume),
                  ),
                ),
              SyncNotice(controller),
              EchoButton(
                'Iniciar ${speedrun ? 'speedrun' : 'missão'}',
                onPressed: enabled
                    ? () => context.go(
                        '/play/${stage.id}?mode=${speedrun ? 'speedrun' : 'story'}',
                      )
                    : null,
                icon: Icons.play_arrow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final p = controller.player;
    return EchoShell(
      title: 'Sua voz no Vale',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SyncNotice(controller),
            Text(p.nickname, style: const TextStyle(fontSize: 32, color: lume)),
            Text(controller.identity?.email ?? ''),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ProgressCard(label: 'Pontuação', value: '${p.points}'),
                ProgressCard(
                  label: 'Fases concluídas',
                  value:
                      '${p.stages.values.where((v) => v == 'completed').length}',
                ),
                ProgressCard(label: 'Ecos', value: '${p.echoes.length}'),
                ProgressCard(label: 'Memórias', value: '${p.memories.length}'),
                ProgressCard(
                  label: 'Conquistas',
                  value:
                      '${p.achievements.where((a) => a['unlocked_at'] != null).length}',
                ),
                ProgressCard(
                  label: 'Tentativas concluídas',
                  value: '${p.completedRuns}',
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Recordes pessoais · não verificados',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            if (p.bests.isEmpty)
              const Text(
                'Seu primeiro tempo aparecerá aqui após um speedrun elegível.',
              ),
            for (final b in p.bests)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${StageRegistry.get(b['stage_id'] as String).title} · ${formatTime((b['duration_ms'] as num).toInt())} · ${b['deaths']} mortes · versão ${b['stage_version']}',
                ),
              ),
            EchoButton(
              'Sair da conta',
              onPressed: () async {
                try {
                  await controller.logout();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyError(error))),
                    );
                  }
                }
              },
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context) => EchoShell(
    title: 'Constelação de conquistas',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SyncNotice(controller),
          if (controller.player.achievements.isEmpty)
            const Text(
              'As conquistas aparecerão quando o arquivo do Vale estiver disponível.',
            ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: controller.player.achievements
                .map((data) => AchievementBadge(data: data))
                .toList(),
          ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(this.controller, {super.key});
  final AppController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _draft = widget.controller.player.settings;
  bool _dirty = false;
  AppController get controller => widget.controller;
  void change(GameSettings value) => setState(() {
    _draft = value;
    _dirty = true;
  });
  @override
  Widget build(BuildContext context) {
    final s = _draft;
    final enabled = controller.pendingCount == 0;
    return EchoShell(
      title: 'Configurações',
      reduceEffects: s.reduceEffects,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: EchoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SyncNotice(controller),
              SwitchListTile(
                title: const Text('Mostrar cronômetro na história'),
                value: s.showTimer,
                onChanged: enabled
                    ? (v) => change(s.copyWith(showTimer: v))
                    : null,
              ),
              SwitchListTile(
                title: const Text('Reduzir efeitos visuais'),
                subtitle: const Text(
                  'Reduz névoa, partículas, rastros e movimento do menu.',
                ),
                value: s.reduceEffects,
                onChanged: enabled
                    ? (v) => change(s.copyWith(reduceEffects: v))
                    : null,
              ),
              Text(
                'Velocidade dos diálogos · ${s.dialogueSpeed.toStringAsFixed(1)}×',
              ),
              Slider(
                value: s.dialogueSpeed,
                min: .5,
                max: 2,
                divisions: 6,
                label: s.dialogueSpeed.toStringAsFixed(1),
                onChanged: enabled
                    ? (v) => change(s.copyWith(dialogueSpeed: v))
                    : null,
              ),
              Text('Escala de texto · ${s.textScale.toStringAsFixed(1)}×'),
              Slider(
                value: s.textScale,
                min: .8,
                max: 1.6,
                divisions: 8,
                label: s.textScale.toStringAsFixed(1),
                onChanged: enabled
                    ? (v) => change(s.copyWith(textScale: v))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                'O Lume preserva as vozes do Vale.',
                textScaler: TextScaler.linear(s.textScale),
              ),
              const SizedBox(height: 12),
              EchoButton(
                'Salvar preferências',
                onPressed: _dirty && enabled
                    ? () {
                        controller.saveSettings(_draft);
                        setState(() => _dirty = false);
                      }
                    : null,
                icon: Icons.save_outlined,
              ),
              Text(
                _dirty
                    ? 'Alterações ainda não salvas'
                    : 'Preferências da sua conta · ${controller.syncStatus}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen(this.controller, {super.key});
  final AppController controller;
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _kind = 'points', _stage = 'stage_01';
  late Future<List<RankingRow>> _rows;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _rows = widget.controller.backend
        .leaderboard(_kind, _stage)
        .timeout(const Duration(seconds: 12));
  }

  @override
  Widget build(BuildContext context) => EchoShell(
    title: 'Vozes na classificação',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tab in const {
                'points': 'Pontos',
                'speedrun': 'Speedrun por fase',
                'combined': 'Tempo combinado',
                'echoes': 'Ecos',
              }.entries)
                ChoiceChip(
                  label: Text(tab.value),
                  selected: _kind == tab.key,
                  onSelected: (_) => setState(() {
                    _kind = tab.key;
                    _reload();
                  }),
                ),
            ],
          ),
          if (_kind == 'speedrun')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _stage,
                items: StageRegistry.stages
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.title)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _stage = v;
                      _reload();
                    });
                  }
                },
              ),
            ),
          const SizedBox(height: 14),
          if (_kind == 'speedrun' || _kind == 'combined')
            const Text(
              'Tempos informados pelo cliente · não verificados competitivamente. Apenas versões atuais e tentativas elegíveis. Pausa ou perda de foco invalidam a tentativa.',
            ),
          const SizedBox(height: 14),
          FutureBuilder<List<RankingRow>>(
            future: _rows,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EchoPanel(
                  child: Column(
                    children: [
                      Text(friendlyError(snapshot.error!)),
                      EchoButton(
                        'Tentar novamente',
                        onPressed: () => setState(_reload),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const EchoPanel(
                  child: Text(
                    'Ainda não há resultados elegíveis nesta classificação.',
                  ),
                );
              }
              final me = snapshot.data!
                  .where((r) => r.playerId == widget.controller.identity?.id)
                  .firstOrNull;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      me == null
                          ? 'Você ainda não tem resultado elegível.'
                          : 'Sua posição: #${me.position}',
                      style: const TextStyle(color: lume),
                    ),
                  ),
                  for (final row in snapshot.data!)
                    LeaderboardEntry(
                      row: row,
                      formatted: _kind == 'speedrun' || _kind == 'combined'
                          ? formatTime(row.value)
                          : '${row.value} ${_kind == 'echoes' ? 'Ecos' : 'pontos'}',
                      isMe: row.playerId == widget.controller.identity?.id,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
