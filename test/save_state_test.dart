import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/models/daily_task.dart';
import 'package:rallygame/models/save_state.dart';

void main() {
  group('SaveState serialization', () {
    test('round-trips all fields', () {
      final state = SaveState(
        tutorialDone: true,
        coins: 1234,
        levelStars: {1: 3, 2: 2, 5: 1},
        unlockedSkins: [1, 2, 8],
        selectedSkin: 8,
        upgradeLevels: {0: 3, 4: 1},
        endlessBestWave: 12,
        endlessBestScore: 5000,
        endlessBestTime: 320,
        dailyDate: '2026-07-23',
        dailyTasks: [DailyTask(type: DailyTaskType.collectCoins, target: 1000, reward: 150, progress: 400)],
        music: false,
        sound: true,
        vibration: false,
        controlMode: ControlMode.joystick,
      );

      final restored = SaveState.fromJson(state.toJson());
      expect(restored.tutorialDone, true);
      expect(restored.coins, 1234);
      expect(restored.levelStars[1], 3);
      expect(restored.levelStars[5], 1);
      expect(restored.unlockedSkins, containsAll([1, 2, 8]));
      expect(restored.selectedSkin, 8);
      expect(restored.upgradeLevels[0], 3);
      expect(restored.endlessBestWave, 12);
      expect(restored.endlessBestScore, 5000);
      expect(restored.endlessBestTime, 320);
      expect(restored.dailyDate, '2026-07-23');
      expect(restored.dailyTasks.length, 1);
      expect(restored.dailyTasks.first.progress, 400);
      expect(restored.music, false);
      expect(restored.controlMode, ControlMode.joystick);
    });

    test('missing fields fall back to safe defaults', () {
      final restored = SaveState.fromJson({});
      expect(restored.coins, 0);
      expect(restored.tutorialDone, false);
      expect(restored.selectedSkin, 1);
      expect(restored.unlockedSkins, contains(1));
      expect(restored.music, true);
      expect(restored.controlMode, ControlMode.drag);
    });

    test('unlocked skins always include the default skin', () {
      final restored = SaveState.fromJson({'unlockedSkins': [3, 4]});
      expect(restored.unlockedSkins, contains(1));
    });

    test('out-of-range control mode is clamped', () {
      final restored = SaveState.fromJson({'controlMode': 99});
      expect(ControlMode.values, contains(restored.controlMode));
    });

    test('garbage typed values do not crash and use defaults', () {
      final restored = SaveState.fromJson({
        'coins': 'not-a-number',
        'levelStars': 'broken',
        'unlockedSkins': 'broken',
      });
      expect(restored.coins, 0);
      expect(restored.levelStars, isEmpty);
      expect(restored.unlockedSkins, contains(1));
    });

    test('highest unlocked level advances with completed levels', () {
      final state = SaveState(levelStars: {1: 3, 2: 1, 3: 2});
      expect(state.highestUnlockedLevel, 4);
      expect(state.isLevelUnlocked(4), true);
      expect(state.isLevelUnlocked(5), false);
    });

    test('endless unlocks after level 40', () {
      final locked = SaveState(levelStars: {39: 3});
      expect(locked.endlessUnlocked, false);
      final unlocked = SaveState(levelStars: {40: 1});
      expect(unlocked.endlessUnlocked, true);
    });
  });
}
