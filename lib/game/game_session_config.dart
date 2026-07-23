import '../core/constants.dart';
import '../models/enemy_type.dart';
import '../models/level_config.dart';
import '../models/powerup_type.dart';
import '../models/upgrade_type.dart';
import '../services/game_data.dart';

/// Everything the running game needs for one session. Built from a level (or
/// generated for endless mode) and blended with the player's permanent upgrades.
class GameSessionConfig {
  final LevelConfig? level; // null => endless mode
  final bool endless;
  final int locationId;

  final int lanternCount;
  final double decayRate; // charge lost per second (after upgrades)
  final int startingEggs;
  final List<EnemyType> enemies;
  final double spawnInterval;
  final int waveCount;
  final double waveDuration;
  final List<PowerUpType> powerups;
  final SpecialCondition special;

  // Upgrade-derived player stats.
  final double chickenSpeed;
  final double rechargePerSecond;
  final double dashCooldown;
  final double coinMagnetRadius;
  final double powerupDurationMult;
  final int selectedSkin;

  const GameSessionConfig({
    required this.level,
    required this.endless,
    required this.locationId,
    required this.lanternCount,
    required this.decayRate,
    required this.startingEggs,
    required this.enemies,
    required this.spawnInterval,
    required this.waveCount,
    required this.waveDuration,
    required this.powerups,
    required this.special,
    required this.chickenSpeed,
    required this.rechargePerSecond,
    required this.dashCooldown,
    required this.coinMagnetRadius,
    required this.powerupDurationMult,
    required this.selectedSkin,
  });

  bool get isTutorial => special == SpecialCondition.tutorial;

  factory GameSessionConfig.fromLevel(LevelConfig level) {
    final data = GameData.instance;
    final speedLvl = data.upgradeLevel(UpgradeType.movementSpeed);
    final rechargeLvl = data.upgradeLevel(UpgradeType.lanternRecharge);
    final burnLvl = data.upgradeLevel(UpgradeType.lanternBurnTime);
    final eggLvl = data.upgradeLevel(UpgradeType.startingEggs);
    final dashLvl = data.upgradeLevel(UpgradeType.dashCooldown);
    final magnetLvl = data.upgradeLevel(UpgradeType.coinMagnetRadius);
    final puLvl = data.upgradeLevel(UpgradeType.powerupDuration);

    return GameSessionConfig(
      level: level,
      endless: false,
      locationId: level.locationId,
      lanternCount: level.lanternCount,
      decayRate: level.decayRate * (1 - 0.07 * burnLvl),
      startingEggs: level.startingEggs + eggLvl,
      enemies: level.enemies,
      spawnInterval: level.spawnInterval,
      waveCount: level.waveCount,
      waveDuration: level.waveDuration,
      powerups: level.powerups,
      special: level.special,
      chickenSpeed: GameTuning.baseChickenSpeed * (1 + 0.06 * speedLvl),
      rechargePerSecond: GameTuning.baseRechargePerSecond * (1 + 0.10 * rechargeLvl),
      dashCooldown: GameTuning.baseDashCooldown * (1 - 0.08 * dashLvl),
      coinMagnetRadius: GameTuning.coinMagnetBaseRadius * (1 + 0.20 * magnetLvl),
      powerupDurationMult: 1 + 0.10 * puLvl,
      selectedSkin: data.selectedSkin,
    );
  }

  /// Endless mode: a balanced starting point. The game scales it up per wave.
  factory GameSessionConfig.endless() {
    final data = GameData.instance;
    final speedLvl = data.upgradeLevel(UpgradeType.movementSpeed);
    final rechargeLvl = data.upgradeLevel(UpgradeType.lanternRecharge);
    final burnLvl = data.upgradeLevel(UpgradeType.lanternBurnTime);
    final eggLvl = data.upgradeLevel(UpgradeType.startingEggs);
    final dashLvl = data.upgradeLevel(UpgradeType.dashCooldown);
    final magnetLvl = data.upgradeLevel(UpgradeType.coinMagnetRadius);
    final puLvl = data.upgradeLevel(UpgradeType.powerupDuration);

    return GameSessionConfig(
      level: null,
      endless: true,
      locationId: 3,
      lanternCount: 6,
      decayRate: 0.060 * (1 - 0.07 * burnLvl),
      startingEggs: 6 + eggLvl,
      enemies: EnemyType.values,
      spawnInterval: 2.2,
      waveCount: 9999,
      waveDuration: 26,
      powerups: PowerUpType.values,
      special: SpecialCondition.none,
      chickenSpeed: GameTuning.baseChickenSpeed * (1 + 0.06 * speedLvl),
      rechargePerSecond: GameTuning.baseRechargePerSecond * (1 + 0.10 * rechargeLvl),
      dashCooldown: GameTuning.baseDashCooldown * (1 - 0.08 * dashLvl),
      coinMagnetRadius: GameTuning.coinMagnetBaseRadius * (1 + 0.20 * magnetLvl),
      powerupDurationMult: 1 + 0.10 * puLvl,
      selectedSkin: data.selectedSkin,
    );
  }
}
