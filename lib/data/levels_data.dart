import '../models/enemy_type.dart';
import '../models/level_config.dart';
import '../models/powerup_type.dart';

/// Builds the full campaign of 40 levels across 4 locations.
///
/// Every level is described by its own data (enemies, waves, lanterns,
/// objective, special mechanic). Difficulty ramps gradually and each location
/// introduces new enemies and mechanics rather than only bigger numbers.
class LevelsData {
  LevelsData._();

  static final List<LevelConfig> levels = _build();

  static LevelConfig byId(int id) =>
      levels.firstWhere((l) => l.id == id, orElse: () => levels.first);

  static List<LevelConfig> forLocation(int locationId) =>
      levels.where((l) => l.locationId == locationId).toList();

  // Power-up availability grows with the campaign.
  static const _puFarm = [
    PowerUpType.fullIgnite,
    PowerUpType.coopShield,
    PowerUpType.speedBoost,
  ];
  static const _puOrchard = [
    PowerUpType.fullIgnite,
    PowerUpType.coopShield,
    PowerUpType.speedBoost,
    PowerUpType.slowTime,
    PowerUpType.coinMagnet,
    PowerUpType.doubleCoins,
  ];
  static const _puFields = [
    PowerUpType.fullIgnite,
    PowerUpType.coopShield,
    PowerUpType.speedBoost,
    PowerUpType.slowTime,
    PowerUpType.coinMagnet,
    PowerUpType.doubleCoins,
    PowerUpType.shockwave,
    PowerUpType.lanternBuddy,
  ];
  static const _puForest = PowerUpType.values;

  static List<LevelConfig> _build() {
    final specs = <_Spec>[
      // ---------------- Location 0 - Cozy Farm (1-10) ----------------
      _Spec('First Night', 3, 2, 16, 5, 0.030, [EnemyType.mouse], 3.2,
          SpecialCondition.tutorial, LevelObjective(ObjectiveType.noEggLost), 5, 30),
      _Spec('Two Little Paws', 3, 2, 18, 5, 0.035, [EnemyType.mouse, EnemyType.raccoon],
          3.0, SpecialCondition.tutorial, LevelObjective(ObjectiveType.allLanternsLit), 4, 35),
      _Spec('Keep Them Bright', 3, 3, 18, 5, 0.040,
          [EnemyType.mouse, EnemyType.raccoon], 2.8, SpecialCondition.none,
          LevelObjective(ObjectiveType.scareEnemies, 8), 4, 40),
      _Spec('The Sly One', 4, 3, 20, 5, 0.045,
          [EnemyType.mouse, EnemyType.raccoon, EnemyType.fox], 2.7,
          SpecialCondition.none, LevelObjective(ObjectiveType.collectCoins, 25), 3, 45),
      _Spec('Quick Feet', 4, 3, 20, 4, 0.050, [EnemyType.raccoon, EnemyType.fox], 2.5,
          SpecialCondition.none, LevelObjective(ObjectiveType.keepCombo, 3), 3, 45),
      _Spec('Barnyard Bustle', 4, 4, 20, 4, 0.052,
          [EnemyType.mouse, EnemyType.raccoon, EnemyType.fox], 2.4,
          SpecialCondition.none, LevelObjective(ObjectiveType.noEggLost), 3, 50),
      _Spec('Fox Patrol', 4, 4, 22, 4, 0.055, [EnemyType.fox, EnemyType.raccoon], 2.2,
          SpecialCondition.none, LevelObjective(ObjectiveType.scareEnemies, 14), 3, 50),
      _Spec('Steady Glow', 4, 4, 22, 4, 0.058, [EnemyType.mouse, EnemyType.fox], 2.2,
          SpecialCondition.none, LevelObjective(ObjectiveType.allLanternsLit), 3, 55),
      _Spec('Full Yard', 4, 5, 22, 4, 0.060,
          [EnemyType.mouse, EnemyType.raccoon, EnemyType.fox], 2.1,
          SpecialCondition.none, LevelObjective(ObjectiveType.collectCoins, 45), 3, 55),
      _Spec('Boar at the Gate', 4, 5, 24, 5, 0.060, [EnemyType.fox, EnemyType.raccoon],
          2.0, SpecialCondition.miniBoss, LevelObjective(ObjectiveType.noEggLost), 4, 80),

      // ------------- Location 1 - Moonlit Orchard (11-20) -------------
      _Spec('Badger Burrows', 4, 4, 22, 5, 0.055, [EnemyType.raccoon, EnemyType.badger],
          2.3, SpecialCondition.none, LevelObjective(ObjectiveType.scareEnemies, 16), 4, 55),
      _Spec('Night Wings', 4, 4, 22, 5, 0.058, [EnemyType.fox, EnemyType.owl], 2.2,
          SpecialCondition.none, LevelObjective(ObjectiveType.allLanternsLit), 4, 55),
      _Spec('Long Rows', 5, 4, 24, 5, 0.060, [EnemyType.badger, EnemyType.fox], 2.2,
          SpecialCondition.none, LevelObjective(ObjectiveType.collectCoins, 55), 4, 60),
      _Spec('Orchard Watch', 5, 5, 24, 5, 0.062,
          [EnemyType.owl, EnemyType.raccoon, EnemyType.badger], 2.1,
          SpecialCondition.none, LevelObjective(ObjectiveType.noEggLost), 4, 60),
      _Spec('Swoop and Dig', 5, 5, 24, 5, 0.064, [EnemyType.fox, EnemyType.owl], 2.0,
          SpecialCondition.none, LevelObjective(ObjectiveType.keepCombo, 4), 3, 65),
      _Spec('Moonlit Rush', 5, 5, 26, 5, 0.066,
          [EnemyType.badger, EnemyType.fox, EnemyType.owl], 1.9,
          SpecialCondition.none, LevelObjective(ObjectiveType.scareEnemies, 22), 3, 65),
      _Spec('Tricky Skies', 5, 5, 26, 5, 0.068,
          [EnemyType.mouse, EnemyType.owl, EnemyType.badger], 1.9,
          SpecialCondition.none, LevelObjective(ObjectiveType.allLanternsLit), 3, 70),
      _Spec('Deep Orchard', 5, 6, 26, 5, 0.070,
          [EnemyType.fox, EnemyType.owl, EnemyType.badger], 1.8,
          SpecialCondition.none, LevelObjective(ObjectiveType.collectCoins, 70), 3, 70),
      _Spec('Restless Night', 5, 6, 28, 5, 0.072,
          [EnemyType.badger, EnemyType.owl, EnemyType.fox, EnemyType.raccoon], 1.8,
          SpecialCondition.none, LevelObjective(ObjectiveType.noEggLost), 3, 75),
      _Spec('Orchard Boar', 5, 6, 28, 6, 0.070,
          [EnemyType.owl, EnemyType.badger, EnemyType.fox], 1.7,
          SpecialCondition.miniBoss, LevelObjective(ObjectiveType.scareEnemies, 26), 4, 100),

      // -------------- Location 2 - Windy Fields (21-30) --------------
      _Spec('First Gust', 5, 5, 26, 5, 0.062, [EnemyType.crow, EnemyType.fox], 2.0,
          SpecialCondition.wind, LevelObjective(ObjectiveType.allLanternsLit), 4, 65),
      _Spec('Grey Runner', 5, 5, 26, 5, 0.064, [EnemyType.wolf, EnemyType.raccoon], 1.9,
          SpecialCondition.wind, LevelObjective(ObjectiveType.scareEnemies, 20), 3, 65),
      _Spec('Windswept', 6, 5, 28, 5, 0.066, [EnemyType.crow, EnemyType.badger], 1.9,
          SpecialCondition.wind, LevelObjective(ObjectiveType.collectCoins, 75), 3, 70),
      _Spec('Howling Fields', 6, 6, 28, 5, 0.068, [EnemyType.wolf, EnemyType.owl], 1.8,
          SpecialCondition.wind, LevelObjective(ObjectiveType.noEggLost), 3, 70),
      _Spec('Feathers & Fangs', 6, 6, 28, 5, 0.070, [EnemyType.crow, EnemyType.wolf], 1.7,
          SpecialCondition.wind, LevelObjective(ObjectiveType.keepCombo, 5), 3, 75),
      _Spec('Storm Watch', 6, 6, 30, 5, 0.072,
          [EnemyType.wolf, EnemyType.fox, EnemyType.crow], 1.7,
          SpecialCondition.wind, LevelObjective(ObjectiveType.scareEnemies, 26), 3, 75),
      _Spec('Scattered Light', 6, 6, 30, 5, 0.074,
          [EnemyType.crow, EnemyType.owl, EnemyType.badger], 1.6,
          SpecialCondition.wind, LevelObjective(ObjectiveType.allLanternsLit), 3, 80),
      _Spec('Gale Force', 6, 7, 30, 5, 0.076,
          [EnemyType.wolf, EnemyType.crow, EnemyType.fox], 1.6,
          SpecialCondition.wind, LevelObjective(ObjectiveType.collectCoins, 95), 3, 80),
      _Spec('Wild Night', 6, 7, 32, 5, 0.078,
          [EnemyType.wolf, EnemyType.crow, EnemyType.owl, EnemyType.badger], 1.5,
          SpecialCondition.wind, LevelObjective(ObjectiveType.noEggLost), 3, 85),
      _Spec('Boar in the Wind', 6, 7, 32, 6, 0.076, [EnemyType.wolf, EnemyType.crow],
          1.5, SpecialCondition.miniBoss, LevelObjective(ObjectiveType.scareEnemies, 30), 4, 120),

      // ------------ Location 3 - Dark Forest Edge (31-40) ------------
      _Spec('Edge of the Woods', 6, 6, 30, 6, 0.070,
          [EnemyType.fox, EnemyType.badger, EnemyType.owl, EnemyType.crow], 1.7,
          SpecialCondition.none, LevelObjective(ObjectiveType.allLanternsLit), 4, 80),
      _Spec('Pack Hunt', 6, 6, 30, 6, 0.072,
          [EnemyType.wolf, EnemyType.raccoon, EnemyType.crow], 1.6,
          SpecialCondition.none, LevelObjective(ObjectiveType.scareEnemies, 28), 4, 80),
      _Spec('Whistling Dark', 7, 7, 32, 6, 0.076,
          [EnemyType.owl, EnemyType.wolf, EnemyType.badger], 1.5,
          SpecialCondition.wind, LevelObjective(ObjectiveType.noEggLost), 4, 90),
      _Spec('Many Eyes', 7, 7, 32, 6, 0.078,
          [EnemyType.crow, EnemyType.wolf, EnemyType.fox, EnemyType.owl], 1.5,
          SpecialCondition.none, LevelObjective(ObjectiveType.collectCoins, 110), 4, 90),
      _Spec('Tusk and Claw', 7, 7, 34, 6, 0.078,
          [EnemyType.fox, EnemyType.wolf, EnemyType.owl], 1.4,
          SpecialCondition.miniBoss, LevelObjective(ObjectiveType.noEggLost), 4, 130),
      _Spec('Cold Wind', 7, 7, 34, 6, 0.080,
          [EnemyType.wolf, EnemyType.crow, EnemyType.badger, EnemyType.owl], 1.4,
          SpecialCondition.wind, LevelObjective(ObjectiveType.keepCombo, 6), 4, 100),
      _Spec('Surrounded', 8, 8, 34, 6, 0.082,
          [EnemyType.fox, EnemyType.wolf, EnemyType.crow, EnemyType.owl, EnemyType.badger],
          1.4, SpecialCondition.none, LevelObjective(ObjectiveType.allLanternsLit), 4, 100),
      _Spec('Relentless', 8, 8, 36, 6, 0.084,
          [EnemyType.wolf, EnemyType.crow, EnemyType.owl, EnemyType.badger, EnemyType.fox],
          1.3, SpecialCondition.wind, LevelObjective(ObjectiveType.scareEnemies, 38), 4, 110),
      _Spec('Forest Boar', 8, 8, 36, 7, 0.082,
          [EnemyType.boar, EnemyType.wolf, EnemyType.crow, EnemyType.owl], 1.3,
          SpecialCondition.miniBoss, LevelObjective(ObjectiveType.noEggLost), 5, 150),
      _Spec('The Long Night', 8, 10, 38, 7, 0.086,
          [EnemyType.mouse, EnemyType.raccoon, EnemyType.fox, EnemyType.badger,
            EnemyType.owl, EnemyType.crow, EnemyType.wolf, EnemyType.boar],
          1.2, SpecialCondition.finalChallenge,
          LevelObjective(ObjectiveType.noEggLost), 5, 250),
    ];

    final result = <LevelConfig>[];
    for (int i = 0; i < specs.length; i++) {
      final s = specs[i];
      final id = i + 1;
      final locationId = i ~/ 10;
      final indexInLocation = (i % 10) + 1;
      final powerups = switch (locationId) {
        0 => _puFarm,
        1 => _puOrchard,
        2 => _puFields,
        _ => _puForest,
      };
      // Tutorial levels start with no power-ups to keep the focus on learning.
      final levelPowerups =
          s.special == SpecialCondition.tutorial ? const <PowerUpType>[] : powerups;
      result.add(LevelConfig(
        id: id,
        locationId: locationId,
        indexInLocation: indexInLocation,
        name: s.name,
        backgroundIndex: _backgroundFor(locationId, indexInLocation),
        lanternCount: s.lanterns,
        waveCount: s.waves,
        waveDuration: s.waveDuration,
        startingEggs: s.eggs,
        decayRate: s.decay,
        enemies: s.enemies,
        spawnInterval: s.spawnInterval,
        powerups: levelPowerups,
        special: s.special,
        objective: s.objective,
        star2EggsKept: s.star2,
        completionCoins: s.coins,
      ));
    }
    return result;
  }

  static int _backgroundFor(int locationId, int indexInLocation) {
    // Two background variants per location for a little visual variety.
    const pairs = [
      [0, 1],
      [2, 3],
      [4, 3],
      [5, 4],
    ];
    final pair = pairs[locationId];
    return indexInLocation.isOdd ? pair[0] : pair[1];
  }
}

/// Compact internal spec used to build a [LevelConfig].
class _Spec {
  final String name;
  final int lanterns;
  final int waves;
  final double waveDuration;
  final int eggs;
  final double decay;
  final List<EnemyType> enemies;
  final double spawnInterval;
  final SpecialCondition special;
  final LevelObjective objective;
  final int star2;
  final int coins;

  const _Spec(
    this.name,
    this.lanterns,
    this.waves,
    this.waveDuration,
    this.eggs,
    this.decay,
    this.enemies,
    this.spawnInterval,
    this.special,
    this.objective,
    this.star2,
    this.coins,
  );
}
