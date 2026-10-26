class HudState {
  const HudState({
    this.echoes = 0,
    this.totalEchoes = 1,
    this.section = 'O Despertar',
    this.deaths = 0,
    this.checkpoint = 'Despertar',
    this.dashReady = true,
    this.paused = false,
    this.completed = false,
    this.message = 'Colete o Eco e encontre o farol adiante.',
  });
  final int echoes, totalEchoes, deaths;
  final String checkpoint, message, section;
  final bool dashReady, paused, completed;
  String get signature =>
      '$echoes/$totalEchoes/$section/$deaths/$checkpoint/$dashReady/$paused/$completed/$message';
}
