class StageEntry {
  const StageEntry(this.id, this.title, this.order, this.nextId);
  final String id, title;
  final int order;
  final String? nextId;
  String get asset => 'assets/levels/$id.json';
}

class StageRegistry {
  static const stages = [
    StageEntry('stage_01', 'O Despertar', 1, 'stage_02'),
    StageEntry('stage_02', 'Galerias Quebradas', 2, 'stage_03'),
    StageEntry('stage_03', 'Torre do Eco', 3, null),
  ];
  static StageEntry get(String id) => stages.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError.value(id, 'stageId', 'Fase desconhecida'),
  );
}
