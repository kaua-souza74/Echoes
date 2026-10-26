/// Local attempt only. No backend or persistent rewards.
class LevelProgress {
  final Set<String> echoes = {};
  String checkpoint = 'Despertar';
  int checkpointOrder = -1, deaths = 0;
  double spawnX = 64, spawnY = 384;
  bool completed = false;

  bool activateCheckpoint(String label, int order, double x, double y) {
    if (order <= checkpointOrder) {
      return false;
    }
    checkpoint = label;
    checkpointOrder = order;
    spawnX = x;
    spawnY = y;
    return true;
  }

  bool collect(String id) => echoes.add(id);
  bool finish({Iterable<String> requiredEchoes = const ['echo_01']}) {
    if (completed || !requiredEchoes.every(echoes.contains)) {
      return false;
    }
    completed = true;
    return true;
  }

  void reset({double spawnX = 64, double spawnY = 384}) {
    echoes.clear();
    checkpoint = 'Despertar';
    checkpointOrder = -1;
    this.spawnX = spawnX;
    this.spawnY = spawnY;
    deaths = 0;
    completed = false;
  }
}
