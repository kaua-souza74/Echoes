import 'package:flutter/material.dart';
import '../echoes_game.dart';
import '../levels/stage_registry.dart';
import '../systems/run_record.dart';
import 'game_screen.dart';
import '../../narrative/memory_catalog.dart';
import '../../narrative/memories_screen.dart';

class WorldFlowScreen extends StatefulWidget {
  const WorldFlowScreen({super.key});
  @override
  State<WorldFlowScreen> createState() => _WorldFlowScreenState();
}

class _WorldFlowScreenState extends State<WorldFlowScreen> {
  final session = PlaySession();
  String stageId = 'stage_01';
  bool choosing = false;
  bool viewingMemories = false;
  int generation = 0;
  late EchoesGame game = EchoesGame(stageId: stageId, session: session);
  late final Future<MemoryCatalog> memoryCatalog = MemoryCatalog.load();
  void open(String id) {
    setState(() {
      stageId = id;
      generation++;
      game = EchoesGame(stageId: id, session: session);
      choosing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!choosing) {
      final next = StageRegistry.get(stageId).nextId;
      return GameScreen(
        key: ValueKey(generation),
        game: game,
        onChooseStage: () {
          game.shutdown();
          setState(() => choosing = true);
        },
        onNextStage: next == null ? null : () => open(next),
      );
    }
    if (viewingMemories) {
      return FutureBuilder<MemoryCatalog>(
        future: memoryCatalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Não foi possível abrir as memórias: ${snapshot.error}',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return MemoriesScreen(
            catalog: snapshot.data!,
            unlockedCollectibleIds: Set.unmodifiable(
              session.discoveredCollectibles,
            ),
            completedLearningCheckIds: Set.unmodifiable(
              session.completedLearningChecks,
            ),
            onLearningCheckPassed: session.completedLearningChecks.add,
            onClose: () => setState(() => viewingMemories = false),
          );
        },
      );
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ECHOES · Capítulos', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 12),
              const Text('Seleção provisória · resultados desta sessão'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() => viewingMemories = true),
                icon: const Icon(Icons.auto_stories),
                label: const Text('Memórias do Reino'),
              ),
              for (final stage in StageRegistry.stages)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton(
                    onPressed: () => open(stage.id),
                    child: Text(
                      '${stage.order.toString().padLeft(2, '0')} · ${stage.title}',
                    ),
                  ),
                ),
              for (final result in session.results.reversed.take(6))
                Text(
                  '${StageRegistry.get(result.stageId).title} · ${result.completed ? "concluída" : "interrompida"} · '
                  '${(result.durationMs / 1000).toStringAsFixed(1)} s · ${result.deaths} quedas · ${result.collectibles.length} Ecos',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
