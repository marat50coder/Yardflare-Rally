import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/data/levels_data.dart';
import 'package:rallygame/models/level_result.dart';

LevelResult _result({
  required bool won,
  required int startingEggs,
  required int eggsRemaining,
  int coins = 0,
  int scared = 0,
  int combo = 0,
  bool allLit = false,
  bool usedShield = false,
  int waves = 3,
  int totalWaves = 3,
}) {
  return LevelResult(
    won: won,
    wavesCompleted: waves,
    totalWaves: totalWaves,
    startingEggs: startingEggs,
    eggsRemaining: eggsRemaining,
    coinsCollected: coins,
    enemiesScared: scared,
    lanternsRelit: 0,
    maxCombo: combo,
    allLanternsLitAtEnd: allLit,
    usedShield: usedShield,
  );
}

void main() {
  group('stars', () {
    test('losing yields zero stars', () {
      final level = LevelsData.byId(4);
      final r = _result(won: false, startingEggs: level.startingEggs, eggsRemaining: 0);
      expect(r.computeStars(level), 0);
    });

    test('winning with no eggs left is still zero stars', () {
      final level = LevelsData.byId(4);
      final r = _result(won: true, startingEggs: level.startingEggs, eggsRemaining: 0);
      expect(r.computeStars(level), 0);
    });

    test('one star for a bare win', () {
      final level = LevelsData.byId(4); // star2EggsKept = 3, objective collectCoins 25
      final r = _result(won: true, startingEggs: level.startingEggs, eggsRemaining: 1);
      expect(r.computeStars(level), 1);
    });

    test('two stars for saving enough eggs without the objective', () {
      final level = LevelsData.byId(4);
      final r = _result(
        won: true,
        startingEggs: level.startingEggs,
        eggsRemaining: level.star2EggsKept,
        coins: 0,
      );
      expect(r.computeStars(level), 2);
    });

    test('three stars when the objective is also met', () {
      final level = LevelsData.byId(4); // objective: collect 25 coins
      final r = _result(
        won: true,
        startingEggs: level.startingEggs,
        eggsRemaining: level.star2EggsKept,
        coins: 30,
      );
      expect(r.computeStars(level), 3);
    });

    test('noEggLost objective checks full egg count', () {
      final level = LevelsData.byId(1); // objective: noEggLost
      final full = _result(won: true, startingEggs: 5, eggsRemaining: 5);
      expect(full.computeStars(level), 3);
      final partial = _result(won: true, startingEggs: 5, eggsRemaining: 4);
      expect(partial.computeStars(level), lessThan(3));
    });
  });

  group('coins', () {
    test('more stars means more coins', () {
      final level = LevelsData.byId(4);
      final oneStar = _result(won: true, startingEggs: level.startingEggs, eggsRemaining: 1);
      final threeStar = _result(
        won: true,
        startingEggs: level.startingEggs,
        eggsRemaining: level.star2EggsKept,
        coins: 30,
      );
      expect(threeStar.computeCoins(level), greaterThan(oneStar.computeCoins(level)));
    });

    test('a loss still awards some consolation coins', () {
      final level = LevelsData.byId(4);
      final r = _result(
          won: false, startingEggs: level.startingEggs, eggsRemaining: 0, waves: 2, totalWaves: 3);
      expect(r.computeCoins(level), greaterThan(0));
    });

    test('completion coins are included on a win', () {
      final level = LevelsData.byId(1);
      final r = _result(won: true, startingEggs: 5, eggsRemaining: 5);
      expect(r.computeCoins(level), greaterThanOrEqualTo(level.completionCoins));
    });
  });
}
