import 'package:flutter/material.dart';

/// One of the four game locations, each holding 10 levels.
class GameLocation {
  final int id; // 0..3
  final String name;
  final String tagline;
  final int backgroundIndex; // default background for the location
  final int coopIndex; // which coop sprite to show
  final Color themeColor;

  const GameLocation({
    required this.id,
    required this.name,
    required this.tagline,
    required this.backgroundIndex,
    required this.coopIndex,
    required this.themeColor,
  });

  int get firstLevelId => id * 10 + 1;
  int get lastLevelId => id * 10 + 10;

  static const List<GameLocation> all = [
    GameLocation(
      id: 0,
      name: 'Cozy Farm',
      tagline: 'Learn the ropes on a calm little farm.',
      backgroundIndex: 0,
      coopIndex: 0,
      themeColor: Color(0xFF8BC34A),
    ),
    GameLocation(
      id: 1,
      name: 'Moonlit Orchard',
      tagline: 'Longer routes under the orchard moon.',
      backgroundIndex: 2,
      coopIndex: 1,
      themeColor: Color(0xFF5C6BC0),
    ),
    GameLocation(
      id: 2,
      name: 'Windy Fields',
      tagline: 'The wind steals the light from the lanterns.',
      backgroundIndex: 4,
      coopIndex: 2,
      themeColor: Color(0xFF26A69A),
    ),
    GameLocation(
      id: 3,
      name: 'Dark Forest Edge',
      tagline: 'Every intruder prowls at the forest edge.',
      backgroundIndex: 5,
      coopIndex: 3,
      themeColor: Color(0xFF7E57C2),
    ),
  ];

  static GameLocation of(int id) => all[id.clamp(0, all.length - 1)];
}
