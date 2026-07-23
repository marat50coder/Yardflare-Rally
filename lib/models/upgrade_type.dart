import 'package:flutter/material.dart';

enum UpgradeType {
  movementSpeed,
  lanternRecharge,
  lanternBurnTime,
  startingEggs,
  dashCooldown,
  coinMagnetRadius,
  powerupDuration,
}

/// Description of a permanent upgrade with a limited number of levels.
class UpgradeInfo {
  final UpgradeType type;
  final String name;
  final String description;
  final IconData icon;
  final int maxLevel;
  final int baseCost;
  final int costStep;

  /// Multiplier or additive bonus granted per level (interpretation depends on
  /// the upgrade). Exposed through [valueAtLevel] and [effectLabel].
  final double perLevel;

  const UpgradeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.maxLevel,
    required this.baseCost,
    required this.costStep,
    required this.perLevel,
  });

  /// Coin cost to buy the [nextLevel] (1-based). Returns 0 if maxed.
  int costForLevel(int nextLevel) {
    if (nextLevel > maxLevel) return 0;
    return baseCost + costStep * (nextLevel - 1);
  }

  /// The concrete gameplay value at a given upgrade level.
  double valueAtLevel(int level) => 1 + perLevel * level;

  /// Human readable effect at a level, e.g. "+30%" or "+2 eggs".
  String effectLabel(int level) {
    switch (type) {
      case UpgradeType.startingEggs:
        return '+$level eggs';
      case UpgradeType.dashCooldown:
        return '-${(perLevel * level * 100).round()}% cooldown';
      case UpgradeType.lanternBurnTime:
        return '-${(perLevel * level * 100).round()}% decay';
      default:
        return '+${(perLevel * level * 100).round()}%';
    }
  }

  static const Map<UpgradeType, UpgradeInfo> all = {
    UpgradeType.movementSpeed: UpgradeInfo(
      type: UpgradeType.movementSpeed,
      name: 'Movement Speed',
      description: 'Run faster between lanterns.',
      icon: Icons.directions_run,
      maxLevel: 6,
      baseCost: 120,
      costStep: 90,
      perLevel: 0.06,
    ),
    UpgradeType.lanternRecharge: UpgradeInfo(
      type: UpgradeType.lanternRecharge,
      name: 'Lantern Recharge',
      description: 'Relight lanterns quicker.',
      icon: Icons.local_fire_department,
      maxLevel: 6,
      baseCost: 120,
      costStep: 90,
      perLevel: 0.10,
    ),
    UpgradeType.lanternBurnTime: UpgradeInfo(
      type: UpgradeType.lanternBurnTime,
      name: 'Lantern Burn Time',
      description: 'Lanterns fade more slowly.',
      icon: Icons.hourglass_bottom,
      maxLevel: 6,
      baseCost: 140,
      costStep: 100,
      perLevel: 0.07,
    ),
    UpgradeType.startingEggs: UpgradeInfo(
      type: UpgradeType.startingEggs,
      name: 'Starting Eggs',
      description: 'Begin each level with extra eggs.',
      icon: Icons.egg,
      maxLevel: 3,
      baseCost: 200,
      costStep: 200,
      perLevel: 1,
    ),
    UpgradeType.dashCooldown: UpgradeInfo(
      type: UpgradeType.dashCooldown,
      name: 'Dash Cooldown',
      description: 'Dash more often.',
      icon: Icons.bolt,
      maxLevel: 5,
      baseCost: 150,
      costStep: 110,
      perLevel: 0.08,
    ),
    UpgradeType.coinMagnetRadius: UpgradeInfo(
      type: UpgradeType.coinMagnetRadius,
      name: 'Coin Magnet Radius',
      description: 'Attract coins from farther away.',
      icon: Icons.adjust,
      maxLevel: 5,
      baseCost: 100,
      costStep: 70,
      perLevel: 0.20,
    ),
    UpgradeType.powerupDuration: UpgradeInfo(
      type: UpgradeType.powerupDuration,
      name: 'Power-up Duration',
      description: 'Power-ups last longer.',
      icon: Icons.timer,
      maxLevel: 5,
      baseCost: 160,
      costStep: 120,
      perLevel: 0.10,
    ),
  };

  static UpgradeInfo of(UpgradeType t) => all[t]!;
}
