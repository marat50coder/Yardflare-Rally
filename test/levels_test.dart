import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/data/levels_data.dart';
import 'package:rallygame/models/level_config.dart';

void main() {
  group('40 level configuration', () {
    final levels = LevelsData.levels;

    test('there are exactly 40 levels', () {
      expect(levels.length, 40);
    });

    test('ids are sequential 1..40 and unique', () {
      final ids = levels.map((l) => l.id).toList();
      expect(ids, List<int>.generate(40, (i) => i + 1));
      expect(ids.toSet().length, 40);
    });

    test('four locations with ten levels each', () {
      for (int loc = 0; loc < 4; loc++) {
        final inLoc = LevelsData.forLocation(loc);
        expect(inLoc.length, 10, reason: 'location $loc');
        for (final l in inLoc) {
          expect(l.locationId, loc);
        }
      }
    });

    test('lantern counts match the design per location', () {
      const ranges = {
        0: [3, 4],
        1: [4, 5],
        2: [5, 6],
        3: [6, 8],
      };
      for (final l in levels) {
        final r = ranges[l.locationId]!;
        expect(l.lanternCount, inInclusiveRange(r[0], r[1]),
            reason: 'level ${l.id}');
      }
    });

    test('every level has enemies, waves and valid egg thresholds', () {
      for (final l in levels) {
        expect(l.enemies, isNotEmpty, reason: 'level ${l.id}');
        expect(l.waveCount, greaterThanOrEqualTo(2), reason: 'level ${l.id}');
        expect(l.startingEggs, greaterThan(0));
        expect(l.star2EggsKept, lessThanOrEqualTo(l.startingEggs),
            reason: 'level ${l.id}');
        expect(l.spawnInterval, greaterThan(0));
        expect(l.decayRate, greaterThan(0));
      }
    });

    test('difficulty ramps across the campaign', () {
      final first = levels.first;
      final last = levels.last;
      expect(last.decayRate, greaterThan(first.decayRate));
      expect(last.spawnInterval, lessThan(first.spawnInterval));
      expect(last.waveCount, greaterThanOrEqualTo(first.waveCount));
    });

    test('level 1 is the tutorial and level 40 is the final challenge', () {
      expect(levels.first.special, SpecialCondition.tutorial);
      expect(levels.last.special, SpecialCondition.finalChallenge);
      expect(levels.last.id, 40);
    });

    test('tutorial levels carry no power-ups, later levels do', () {
      expect(LevelsData.byId(1).powerups, isEmpty);
      expect(LevelsData.byId(10).powerups, isNotEmpty);
      expect(LevelsData.byId(40).powerups, isNotEmpty);
    });

    test('mini-boss levels exist at the end of each of the last three locations',
        () {
      expect(LevelsData.byId(10).special, SpecialCondition.miniBoss);
      expect(LevelsData.byId(20).special, SpecialCondition.miniBoss);
      expect(LevelsData.byId(30).special, SpecialCondition.miniBoss);
    });
  });
}
