import 'level_config.dart';

/// Outcome of a single level attempt. Produced by the game and consumed by the
/// star / reward calculator (kept pure so it is easy to unit test).
class LevelResult {
  final bool won;
  final int wavesCompleted;
  final int totalWaves;
  final int startingEggs;
  final int eggsRemaining;
  final int coinsCollected; // coins picked up during the run
  final int enemiesScared;
  final int lanternsRelit;
  final int maxCombo;
  final bool allLanternsLitAtEnd;
  final bool usedShield;

  const LevelResult({
    required this.won,
    required this.wavesCompleted,
    required this.totalWaves,
    required this.startingEggs,
    required this.eggsRemaining,
    required this.coinsCollected,
    required this.enemiesScared,
    required this.lanternsRelit,
    required this.maxCombo,
    required this.allLanternsLitAtEnd,
    required this.usedShield,
  });

  /// Stars earned (0..3) for a normal level.
  int computeStars(LevelConfig level) {
    if (!won || eggsRemaining <= 0) return 0;
    int stars = 1;
    if (eggsRemaining >= level.star2EggsKept) stars = 2;
    if (stars == 2 && _objectiveMet(level.objective)) stars = 3;
    return stars;
  }

  bool _objectiveMet(LevelObjective o) {
    switch (o.type) {
      case ObjectiveType.noEggLost:
        return eggsRemaining >= startingEggs;
      case ObjectiveType.allLanternsLit:
        return allLanternsLitAtEnd;
      case ObjectiveType.collectCoins:
        return coinsCollected >= o.target;
      case ObjectiveType.keepCombo:
        return maxCombo >= o.target;
      case ObjectiveType.noShield:
        return !usedShield;
      case ObjectiveType.scareEnemies:
        return enemiesScared >= o.target;
    }
  }

  /// Total coins awarded for the run: pickups + completion + performance bonuses.
  int computeCoins(LevelConfig level) {
    if (!won) {
      // Consolation coins for a failed attempt scale with progress.
      final progress = totalWaves == 0 ? 0.0 : wavesCompleted / totalWaves;
      return (coinsCollected + 10 + progress * 20).round();
    }
    int total = coinsCollected;
    total += level.completionCoins;
    total += eggsRemaining * 8; // saved eggs
    total += enemiesScared * 1; // steady defence bonus
    final stars = computeStars(level);
    total += stars * 15; // star bonus
    return total;
  }
}
