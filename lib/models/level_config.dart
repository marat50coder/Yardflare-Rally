import 'enemy_type.dart';
import 'powerup_type.dart';

/// Special mechanics a level can introduce. Kept as data so the game logic
/// reads flags instead of hard-coding per-level behaviour.
enum SpecialCondition {
  none,
  tutorial,
  wind, // some lanterns fade noticeably faster
  miniBoss, // a Boar joins during the level
  finalChallenge, // level 40
}

/// The optional 3-star objective for a level.
enum ObjectiveType {
  noEggLost,
  allLanternsLit,
  collectCoins,
  keepCombo,
  noShield,
  scareEnemies,
}

class LevelObjective {
  final ObjectiveType type;
  final int target;

  const LevelObjective(this.type, [this.target = 0]);

  String get label {
    switch (type) {
      case ObjectiveType.noEggLost:
        return "Don't lose a single egg";
      case ObjectiveType.allLanternsLit:
        return 'Finish with every lantern lit';
      case ObjectiveType.collectCoins:
        return 'Collect $target coins';
      case ObjectiveType.keepCombo:
        return 'Reach a x$target relight combo';
      case ObjectiveType.noShield:
        return "Finish without using a shield";
      case ObjectiveType.scareEnemies:
        return 'Scare away $target enemies';
    }
  }
}

/// Complete, data-only description of a single level.
class LevelConfig {
  final int id; // 1..40 global
  final int locationId; // 0..3
  final int indexInLocation; // 1..10
  final String name;
  final int backgroundIndex;

  final int lanternCount;
  final int waveCount;
  final double waveDuration; // seconds of active spawning per wave
  final int startingEggs;
  final double decayRate; // lantern charge lost per second (0..1 scale)
  final List<EnemyType> enemies;
  final double spawnInterval; // base seconds between spawn attempts
  final List<PowerUpType> powerups;
  final SpecialCondition special;

  final int completionCoins;
  final int star2EggsKept; // keep at least this many eggs for the 2nd star
  final LevelObjective objective; // 3rd star

  const LevelConfig({
    required this.id,
    required this.locationId,
    required this.indexInLocation,
    required this.name,
    required this.backgroundIndex,
    required this.lanternCount,
    required this.waveCount,
    required this.waveDuration,
    required this.startingEggs,
    required this.decayRate,
    required this.enemies,
    required this.spawnInterval,
    required this.powerups,
    required this.objective,
    this.special = SpecialCondition.none,
    this.completionCoins = 40,
    this.star2EggsKept = 2,
  });

  bool get isTutorial => special == SpecialCondition.tutorial;
}
