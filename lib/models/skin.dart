import '../core/constants.dart';

/// A cosmetic chicken skin. Skin 1 is free; the rest cost coins to unlock.
class ChickenSkin {
  final int id; // 1..11
  final String name;
  final int cost; // 0 means unlocked by default
  final String description;

  const ChickenSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
  });

  String get sprite => Assets.chickenSkin(id);

  static const List<ChickenSkin> all = [
    ChickenSkin(id: 1, name: 'Farmhand', cost: 0, description: 'The classic straw-hat defender.'),
    ChickenSkin(id: 11, name: 'Snowy', cost: 400, description: 'A calm white hen with a lantern.'),
    ChickenSkin(id: 2, name: 'Golden', cost: 900, description: 'Shimmering golden feathers.'),
    ChickenSkin(id: 8, name: 'Ranger', cost: 700, description: 'Cowboy hat and red bandana.'),
    ChickenSkin(id: 3, name: 'Midnight', cost: 800, description: 'Dark plumage for night work.'),
    ChickenSkin(id: 7, name: 'Wizard', cost: 1100, description: 'A starry hat full of mystery.'),
    ChickenSkin(id: 4, name: 'Royal', cost: 1300, description: 'Wears a well-earned crown.'),
    ChickenSkin(id: 5, name: 'Captain', cost: 1200, description: 'Bold and battle-ready.'),
    ChickenSkin(id: 6, name: 'Knight', cost: 1500, description: 'Polished silver armour.'),
    ChickenSkin(id: 10, name: 'Rainbow', cost: 1800, description: 'A cheerful burst of colour.'),
    ChickenSkin(id: 9, name: 'Cyber', cost: 2200, description: 'A high-tech mecha hen.'),
  ];

  static ChickenSkin byId(int id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
