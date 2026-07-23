import 'package:flutter/material.dart';

import '../core/constants.dart';

enum PowerUpType {
  fullIgnite,
  slowTime,
  doubleCoins,
  coinMagnet,
  lanternBuddy,
  coopShield,
  speedBoost,
  shockwave,
}

/// Data description of a power-up: icon, timing and player-facing text.
class PowerUpInfo {
  final PowerUpType type;
  final String name;
  final String icon;

  /// Effect duration in seconds. 0 means an instant, one-shot effect.
  final double duration;
  final String description;
  final Color tint;

  const PowerUpInfo({
    required this.type,
    required this.name,
    required this.icon,
    required this.duration,
    required this.description,
    required this.tint,
  });

  bool get isInstant => duration <= 0;

  static const Map<PowerUpType, PowerUpInfo> all = {
    PowerUpType.fullIgnite: PowerUpInfo(
      type: PowerUpType.fullIgnite,
      name: 'Full Ignite',
      icon: Assets.puFullIgnite,
      duration: 0,
      description: 'Instantly relights every lantern.',
      tint: Color(0xFFFFC64B),
    ),
    PowerUpType.slowTime: PowerUpInfo(
      type: PowerUpType.slowTime,
      name: 'Slow Time',
      icon: Assets.puSlowTime,
      duration: 6,
      description: 'Slows enemies and lantern decay.',
      tint: Color(0xFF6EC6FF),
    ),
    PowerUpType.doubleCoins: PowerUpInfo(
      type: PowerUpType.doubleCoins,
      name: 'Double Coins',
      icon: Assets.puDoubleCoins,
      duration: 10,
      description: 'Doubles every coin you earn.',
      tint: Color(0xFFFFD24B),
    ),
    PowerUpType.coinMagnet: PowerUpInfo(
      type: PowerUpType.coinMagnet,
      name: 'Coin Magnet',
      icon: Assets.puCoinMagnet,
      duration: 8,
      description: 'Pulls nearby coins toward you.',
      tint: Color(0xFFFF6B6B),
    ),
    PowerUpType.lanternBuddy: PowerUpInfo(
      type: PowerUpType.lanternBuddy,
      name: 'Lantern Buddy',
      icon: Assets.puLanternBuddy,
      duration: 9,
      description: 'A helper keeps the darkest lantern lit.',
      tint: Color(0xFFC8A15A),
    ),
    PowerUpType.coopShield: PowerUpInfo(
      type: PowerUpType.coopShield,
      name: 'Coop Shield',
      icon: Assets.puCoopShield,
      duration: 0,
      description: 'Blocks one egg-stealing attempt.',
      tint: Color(0xFF5B8CFF),
    ),
    PowerUpType.speedBoost: PowerUpInfo(
      type: PowerUpType.speedBoost,
      name: 'Speed Boost',
      icon: Assets.puSpeedBoost,
      duration: 6,
      description: 'The chicken runs much faster.',
      tint: Color(0xFFB6F36E),
    ),
    PowerUpType.shockwave: PowerUpInfo(
      type: PowerUpType.shockwave,
      name: 'Shockwave',
      icon: Assets.puShockwave,
      duration: 0,
      description: 'Scares away every nearby enemy.',
      tint: Color(0xFFFF8A3D),
    ),
  };

  static PowerUpInfo of(PowerUpType t) => all[t]!;
}
