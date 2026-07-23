import '../core/constants.dart';

/// The eight animal intruders. Ordered by the sheet layout.
enum EnemyType { mouse, raccoon, fox, badger, owl, crow, wolf, boar }

/// Static, data-driven description of an enemy's look and behaviour.
class EnemyKind {
  final EnemyType type;
  final String name;
  final String sprite;

  /// Movement speed in px/s along its lane (before level/global scaling).
  final double speed;

  /// How many scares are required to drive it off.
  final int toughness;

  /// Coins and score awarded when scared away.
  final int coinReward;
  final int scoreReward;

  /// Visual radius of the enemy on screen.
  final double radius;

  // Behaviour flags.
  final bool pauses; // raccoon: occasional short stops
  final bool flies; // owl: enters mid-lane, ignores slow-downs
  final bool drainsLanterns; // crow: speeds up nearby lantern decay
  final bool extinguishesLantern; // boar: puts out nearest lantern at coop
  final bool spawnsInGroups; // mouse: arrives in small packs
  final bool elite; // wolf: very fast
  final bool miniBoss; // boar

  const EnemyKind({
    required this.type,
    required this.name,
    required this.sprite,
    required this.speed,
    required this.toughness,
    required this.coinReward,
    required this.scoreReward,
    required this.radius,
    this.pauses = false,
    this.flies = false,
    this.drainsLanterns = false,
    this.extinguishesLantern = false,
    this.spawnsInGroups = false,
    this.elite = false,
    this.miniBoss = false,
  });

  static const Map<EnemyType, EnemyKind> all = {
    EnemyType.mouse: EnemyKind(
      type: EnemyType.mouse,
      name: 'Mouse',
      sprite: Assets.enemyMouse,
      speed: 42,
      toughness: 1,
      coinReward: 2,
      scoreReward: 10,
      radius: 26,
      spawnsInGroups: true,
    ),
    EnemyType.raccoon: EnemyKind(
      type: EnemyType.raccoon,
      name: 'Raccoon',
      sprite: Assets.enemyRaccoon,
      speed: 55,
      toughness: 1,
      coinReward: 3,
      scoreReward: 15,
      radius: 32,
      pauses: true,
    ),
    EnemyType.fox: EnemyKind(
      type: EnemyType.fox,
      name: 'Fox',
      sprite: Assets.enemyFox,
      speed: 82,
      toughness: 1,
      coinReward: 4,
      scoreReward: 20,
      radius: 32,
    ),
    EnemyType.badger: EnemyKind(
      type: EnemyType.badger,
      name: 'Badger',
      sprite: Assets.enemyBadger,
      speed: 48,
      toughness: 2,
      coinReward: 6,
      scoreReward: 30,
      radius: 36,
    ),
    EnemyType.owl: EnemyKind(
      type: EnemyType.owl,
      name: 'Owl',
      sprite: Assets.enemyOwl,
      speed: 70,
      toughness: 1,
      coinReward: 5,
      scoreReward: 25,
      radius: 34,
      flies: true,
    ),
    EnemyType.crow: EnemyKind(
      type: EnemyType.crow,
      name: 'Crow',
      sprite: Assets.enemyCrow,
      speed: 62,
      toughness: 1,
      coinReward: 5,
      scoreReward: 25,
      radius: 32,
      drainsLanterns: true,
    ),
    EnemyType.wolf: EnemyKind(
      type: EnemyType.wolf,
      name: 'Wolf',
      sprite: Assets.enemyWolf,
      speed: 105,
      toughness: 1,
      coinReward: 8,
      scoreReward: 45,
      radius: 36,
      elite: true,
    ),
    EnemyType.boar: EnemyKind(
      type: EnemyType.boar,
      name: 'Boar',
      sprite: Assets.enemyBoar,
      speed: 40,
      toughness: 3,
      coinReward: 15,
      scoreReward: 90,
      radius: 44,
      extinguishesLantern: true,
      miniBoss: true,
    ),
  };

  static EnemyKind of(EnemyType t) => all[t]!;
}
