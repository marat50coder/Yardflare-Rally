import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/models/skin.dart';
import 'package:rallygame/models/upgrade_type.dart';
import 'package:rallygame/services/game_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameData.instance.resetProgress();
    await GameData.instance.load();
  });

  group('coins', () {
    test('add and spend', () {
      final data = GameData.instance;
      data.addCoins(500);
      expect(data.coins, 500);
      expect(data.trySpend(200), true);
      expect(data.coins, 300);
      expect(data.trySpend(9999), false);
      expect(data.coins, 300);
    });
  });

  group('upgrades', () {
    test('cost grows per level and buying deducts coins', () {
      final data = GameData.instance;
      final info = UpgradeInfo.of(UpgradeType.movementSpeed);
      expect(info.costForLevel(1), info.baseCost);
      expect(info.costForLevel(2), info.baseCost + info.costStep);

      data.addCoins(10000);
      expect(data.upgradeLevel(UpgradeType.movementSpeed), 0);
      final before = data.coins;
      expect(data.buyUpgrade(UpgradeType.movementSpeed), true);
      expect(data.upgradeLevel(UpgradeType.movementSpeed), 1);
      expect(data.coins, before - info.costForLevel(1));
    });

    test('cannot exceed max level', () {
      final data = GameData.instance;
      data.addCoins(100000);
      final info = UpgradeInfo.of(UpgradeType.startingEggs);
      for (int i = 0; i < info.maxLevel; i++) {
        expect(data.buyUpgrade(UpgradeType.startingEggs), true);
      }
      expect(data.upgradeLevel(UpgradeType.startingEggs), info.maxLevel);
      expect(data.buyUpgrade(UpgradeType.startingEggs), false);
    });

    test('cannot buy without enough coins', () {
      final data = GameData.instance;
      expect(data.coins, 0);
      expect(data.buyUpgrade(UpgradeType.movementSpeed), false);
    });
  });

  group('skins', () {
    test('buying a skin unlocks and equips it', () {
      final data = GameData.instance;
      final skin = ChickenSkin.all.firstWhere((s) => s.cost > 0);
      data.addCoins(skin.cost);
      expect(data.isSkinUnlocked(skin.id), false);
      expect(data.buySkin(skin), true);
      expect(data.isSkinUnlocked(skin.id), true);
      expect(data.selectedSkin, skin.id);
    });
  });

  group('levels', () {
    test('recording a level keeps the best star count and unlocks next', () {
      final data = GameData.instance;
      data.recordLevel(1, 2, 50);
      expect(data.starsFor(1), 2);
      expect(data.coins, 50);
      expect(data.isLevelUnlocked(2), true);
      // A worse result must not reduce stars.
      data.recordLevel(1, 1, 20);
      expect(data.starsFor(1), 2);
    });

    test('endless records keep the best values', () {
      final data = GameData.instance;
      data.updateEndless(5, 1000, 120);
      data.updateEndless(3, 2000, 60);
      expect(data.endlessBestWave, 5);
      expect(data.endlessBestScore, 2000);
      expect(data.endlessBestTime, 120);
    });
  });

  group('persistence', () {
    test('survives a reload', () async {
      final data = GameData.instance;
      data.addCoins(777);
      data.recordLevel(1, 3, 0);
      await data.load(); // simulate restart reading from the same store
      expect(data.coins, 777);
      expect(data.starsFor(1), 3);
    });
  });

  group('daily tasks', () {
    test('claiming a completed task grants its reward once', () {
      final data = GameData.instance;
      final task = data.dailyTasks.first;
      data.addTaskProgress(task.type, task.target);
      final before = data.coins;
      expect(data.dailyTasks.first.canClaim, true);
      expect(data.claimTask(0), true);
      expect(data.coins, before + task.reward);
      expect(data.claimTask(0), false); // cannot claim twice
    });

    test('pickDailyTasks is deterministic and gives three distinct tasks', () {
      final a = GameData.pickDailyTasks('2026-07-23');
      final b = GameData.pickDailyTasks('2026-07-23');
      expect(a.length, 3);
      expect(a.map((t) => t.type).toList(), b.map((t) => t.type).toList());
      expect(a.map((t) => t.type).toSet().length, 3);
    });
  });
}
