import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../game/levels/stage_registry.dart';
import 'models.dart';

const lume = Color(0xff84d9e8);
const ink = Color(0xff080e19);
const panel = Color(0xee111d2b);
const stone = Color(0xff34495d);

extension StagePresentation on StageEntry {
  int get version => id == 'stage_01' ? 2 : 1;
  String get preview => switch (id) {
    'stage_02' => 'assets/images/parallax/stage_02/02_suspended_galleries.png',
    'stage_03' => 'assets/images/parallax/stage_03/02_echo_tower.png',
    _ => 'assets/images/parallax/stage_01/03_mid_architecture.png',
  };
  String get description => switch (id) {
    'stage_02' =>
      'Atravesse pontes frágeis e descubra os saberes que passam de mão em mão.',
    'stage_03' =>
      'Suba entre as vozes do Vale e reúna as histórias que ninguém guarda sozinho.',
    _ =>
      'Siga o Lume pelas ruínas e descubra como um objeto pode guardar parte de uma vida.',
  };
  String get category => switch (id) {
    'stage_02' => 'Patrimônio cultural',
    'stage_03' => 'Pertencimento e preservação',
    _ => 'Memória e identidade',
  };
  String get difficulty => switch (order) {
    1 => 'Fácil',
    2 => 'Médio',
    _ => 'Desafiador',
  };
  String get objective => switch (id) {
    'stage_02' => 'Recupere o Eco da Ruptura e alcance o farol das Galerias.',
    'stage_03' =>
      'Recupere os Ecos da Memória e do Último Eco; alcance o farol no alto.',
    _ => 'Recupere o Coração do Lume e alcance o farol final.',
  };
}

class EchoBackdrop extends StatefulWidget {
  const EchoBackdrop({
    required this.child,
    this.reduceEffects = false,
    super.key,
  });
  final Widget child;
  final bool reduceEffects;
  @override
  State<EchoBackdrop> createState() => _EchoBackdropState();
}

class _EchoBackdropState extends State<EchoBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  )..repeat();
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ColoredBox(
          color: ink,
          child: AnimatedBuilder(
            animation: _motion,
            builder: (context, _) => LayoutBuilder(
              builder: (context, size) => Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/parallax/stage_01/01_sky_mist.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                  ),
                  Transform.translate(
                    offset: Offset(
                      widget.reduceEffects
                          ? 0
                          : math.sin(_motion.value * math.pi * 2) * 16,
                      0,
                    ),
                    child: Transform.scale(
                      scale: 1.08,
                      child: Image.asset(
                        'assets/images/parallax/stage_01/03_mid_architecture.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  const ColoredBox(color: Color(0xcf080e19)),
                ],
              ),
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class EchoShell extends StatelessWidget {
  const EchoShell({
    required this.title,
    required this.child,
    this.back = '/menu',
    this.reduceEffects = false,
    super.key,
  });
  final String title;
  final String? back;
  final Widget child;
  final bool reduceEffects;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: EchoBackdrop(
      reduceEffects: reduceEffects,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (back != null)
                    IconButton(
                      onPressed: () => context.go(back!),
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: lume,
                      ),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 600)
                    const Text(
                      'E C H O E S',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Color(0xff91a6b2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EchoPanel extends StatelessWidget {
  const EchoPanel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: panel,
      border: Border.all(color: stone),
    ),
    child: child,
  );
}

class EchoButton extends StatelessWidget {
  const EchoButton(
    this.label, {
    required this.onPressed,
    this.icon = Icons.chevron_right,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        foregroundColor: lume,
        backgroundColor: panel,
        shape: const RoundedRectangleBorder(),
        side: const BorderSide(color: stone),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    ),
  );
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({required this.label, required this.value, super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: EchoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 28, color: lume)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xffb0c3ca))),
        ],
      ),
    ),
  );
}

class StageCard extends StatelessWidget {
  const StageCard({
    required this.stage,
    required this.status,
    required this.onPressed,
    this.best,
    super.key,
  });
  final StageEntry stage;
  final String status;
  final int? best;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: EchoPanel(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: Image.asset(
              stage.preview,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAPÍTULO ${stage.order.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: lume,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(stage.title, style: const TextStyle(fontSize: 23)),
                const SizedBox(height: 10),
                Text(stage.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 14),
                Text('${stage.difficulty} · ${stage.category}'),
                const SizedBox(height: 8),
                Text(
                  '$status · 7 Ecos · 100 pontos de primeira conclusão',
                  style: const TextStyle(color: lume, fontSize: 12),
                ),
                if (best != null)
                  Text(
                    'Melhor: ${formatTime(best!)} · informado pelo cliente',
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 8),
                EchoButton('Detalhes da missão', onPressed: onPressed),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({required this.data, super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final unlocked = data['unlocked_at'] != null;
    return SizedBox(
      width: 300,
      child: EchoPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              unlocked ? Icons.auto_awesome : Icons.lock_outline,
              color: unlocked ? lume : stone,
            ),
            const SizedBox(height: 10),
            Text(data['title'] as String, style: const TextStyle(fontSize: 19)),
            const SizedBox(height: 8),
            Text(data['description'] as String),
            const SizedBox(height: 12),
            Text(
              unlocked
                  ? 'Obtida em ${DateTime.parse(data['unlocked_at'] as String).toLocal().toString().split(' ').first}'
                  : 'Ainda não descoberta',
              style: const TextStyle(color: lume, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardEntry extends StatelessWidget {
  const LeaderboardEntry({
    required this.row,
    required this.formatted,
    required this.isMe,
    super.key,
  });
  final RankingRow row;
  final String formatted;
  final bool isMe;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: EchoPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '#${row.position}',
              style: TextStyle(
                fontSize: 20,
                color: row.position <= 3 ? const Color(0xffd6c58a) : lume,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${row.nickname}${isMe ? ' · você' : ''}',
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(formatted, style: const TextStyle(color: lume)),
        ],
      ),
    ),
  );
}

String stageStatus(String? value) => switch (value) {
  'completed' => 'Concluída',
  'in_progress' => 'Em andamento',
  'available' => 'Disponível',
  _ => 'Bloqueada',
};
