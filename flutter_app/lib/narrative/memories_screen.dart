import 'package:flutter/material.dart';

import 'memory_catalog.dart';

const _ink = Color(0xff080e19);
const _panel = Color(0xff111d2b);
const _line = Color(0xff34495d);
const _lume = Color(0xff84d9e8);

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({
    required this.catalog,
    required this.unlockedCollectibleIds,
    required this.completedLearningCheckIds,
    this.onLearningCheckPassed,
    this.onLearningAnswer,
    this.onClose,
    super.key,
  });

  final MemoryCatalog catalog;
  final Set<String> unlockedCollectibleIds;
  final Set<String> completedLearningCheckIds;
  final ValueChanged<String>? onLearningCheckPassed;
  final Future<void> Function(String id, int answer)? onLearningAnswer;
  final VoidCallback? onClose;

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  String? _stageFilter;
  MemoryEntry? _selected;

  @override
  Widget build(BuildContext context) {
    final entries = widget.catalog.entries
        .where((entry) => _stageFilter == null || entry.stageId == _stageFilter)
        .toList(growable: false);
    final found = widget.unlockedCollectibleIds.length.clamp(
      0,
      widget.catalog.entries.length,
    );
    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _ink,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: widget.onClose ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Memórias do Reino'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories, color: _lume),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$found / ${widget.catalog.entries.length} fragmentos reunidos',
                            style: const TextStyle(color: _lume),
                          ),
                        ),
                        SizedBox(
                          width: bounds.maxWidth < 560 ? 145 : 220,
                          child: DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _stageFilter,
                            decoration: const InputDecoration(
                              labelText: 'Capítulo',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              DropdownMenuItem(
                                value: 'stage_01',
                                child: Text('O Despertar'),
                              ),
                              DropdownMenuItem(
                                value: 'stage_02',
                                child: Text('Galerias'),
                              ),
                              DropdownMenuItem(
                                value: 'stage_03',
                                child: Text('Torre do Eco'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _stageFilter = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: bounds.maxWidth < 680
                          ? _phoneLayout(entries)
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 340,
                                  child: _entryList(entries),
                                ),
                                const SizedBox(width: 18),
                                Expanded(child: _detail(_selected)),
                              ],
                            ),
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

  Widget _phoneLayout(List<MemoryEntry> entries) => _selected == null
      ? _entryList(entries)
      : Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Todos os fragmentos'),
              ),
            ),
            Expanded(child: _detail(_selected)),
          ],
        );

  Widget _entryList(List<MemoryEntry> entries) => ListView.builder(
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final unlocked = widget.unlockedCollectibleIds.contains(
        entry.collectibleId,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => setState(() => _selected = entry),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(
                color: _selected?.id == entry.id ? _lume : _line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  unlocked ? Icons.auto_awesome : Icons.blur_on,
                  color: unlocked ? _lume : const Color(0xff526b7c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    unlocked ? entry.title : 'Fragmento desconhecido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  unlocked ? 'REUNIDO' : '???',
                  style: const TextStyle(fontSize: 10, color: _lume),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _detail(MemoryEntry? entry) {
    if (entry == null) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _line),
        ),
        child: const Text('Escolha um fragmento para abrir sua lembrança.'),
      );
    }
    final unlocked = widget.unlockedCollectibleIds.contains(
      entry.collectibleId,
    );
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.all(22),
      child: unlocked
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: double.infinity,
                          child: Image.asset(
                            entry.illustrationAsset,
                            height: 120,
                            fit: BoxFit.fitHeight,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.title,
                    style: const TextStyle(fontSize: 24, color: _lume),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.characterOrEvent,
                    style: const TextStyle(color: Color(0xffb0c3ca)),
                  ),
                  const Divider(height: 28),
                  Text(entry.narrative, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 20),
                  Text(
                    'IDEIA · ${entry.concept.toUpperCase()}',
                    style: const TextStyle(color: _lume, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.explanation,
                    style: const TextStyle(
                      height: 1.5,
                      color: Color(0xffd1dce2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _openLearningCheck(entry),
                    icon: Icon(
                      widget.completedLearningCheckIds.contains(
                            widget.catalog.learningChecks
                                .where((item) => item.stageId == entry.stageId)
                                .firstOrNull
                                ?.id,
                          )
                          ? Icons.check_circle_outline
                          : Icons.psychology_alt_outlined,
                    ),
                    label: Text(
                      widget.completedLearningCheckIds.contains(
                            widget.catalog.learningChecks
                                .where((item) => item.stageId == entry.stageId)
                                .firstOrNull
                                ?.id,
                          )
                          ? 'Conceito aplicado · rever'
                          : 'Aplicar esta lembrança',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'A história do Vale é ficcional. A explicação apresenta um conceito cultural geral.',
                    style: TextStyle(fontSize: 11, color: Color(0xff91a6b2)),
                  ),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: _lume, size: 32),
                  SizedBox(height: 12),
                  Text('Esta lembrança ainda não foi encontrada.'),
                  SizedBox(height: 6),
                  Text(
                    'Explore o capítulo para reunir o Eco.',
                    style: TextStyle(color: Color(0xffb0c3ca)),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openLearningCheck(MemoryEntry entry) async {
    final check = widget.catalog.learningChecks
        .where((item) => item.stageId == entry.stageId)
        .firstOrNull;
    if (check == null) return;
    final passed = await showDialog<bool>(
      context: context,
      builder: (context) => _LearningCheckDialog(
        check: check,
        onAnswer: widget.onLearningAnswer == null
            ? null
            : (answer) => widget.onLearningAnswer!(check.id, answer),
      ),
    );
    if (passed == true && mounted) {
      widget.onLearningCheckPassed?.call(check.id);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lembrança compreendida.')));
    }
  }
}

class _LearningCheckDialog extends StatefulWidget {
  const _LearningCheckDialog({required this.check, this.onAnswer});
  final MemoryLearningCheck check;
  final Future<void> Function(int answer)? onAnswer;

  @override
  State<_LearningCheckDialog> createState() => _LearningCheckDialogState();
}

class _LearningCheckDialogState extends State<_LearningCheckDialog> {
  int? _answer;
  String? _feedback;
  bool _passed = false;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _panel,
    title: const Text('Uma lembrança para relacionar'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.check.prompt),
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: _answer,
            onChanged: (value) {
              if (_feedback == null && !_saving) {
                setState(() => _answer = value);
              }
            },
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < widget.check.options.length;
                  index++
                )
                  RadioListTile<int>(
                    value: index,
                    enabled: _feedback == null && !_saving,
                    title: Text(widget.check.options[index]),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          if (_feedback != null) ...[
            const Divider(),
            Text(_feedback!, style: const TextStyle(height: 1.4)),
          ],
          if (_saving) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: _lume)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Fechar'),
      ),
      FilledButton(
        onPressed: _answer == null || _saving
            ? null
            : _feedback == null
            ? () async {
                setState(() {
                  _saving = true;
                  _error = null;
                });
                try {
                  await widget.onAnswer?.call(_answer!);
                  if (!mounted) return;
                  setState(() {
                    _passed = _answer == widget.check.correctIndex;
                    _feedback = _passed
                        ? widget.check.feedbackCorrect
                        : widget.check.feedbackIncorrect;
                  });
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => _error =
                          'Não foi possível salvar a resposta. Tente novamente.',
                    );
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              }
            : _passed
            ? () => Navigator.pop(context, true)
            : () => setState(() {
                _answer = null;
                _feedback = null;
              }),
        child: Text(
          _feedback == null
              ? 'Responder'
              : _passed
              ? 'Continuar'
              : 'Tentar novamente',
        ),
      ),
    ],
  );
}
